function usage() {
  echo -e "Usage:  sh $0 starttime endtime\n\te.g.\n\tsh $0 210601 210630"
  exit 1
}

function banner() {
   echo "##################################################################################"
   echo "## $*"
   echo "##################################################################################"
}

function maketmpdir() {
  if [[ -d $* ]]
  then
  echo "directory $* for tmp files exists"
  else
  mkdir $*
  echo "directory $* for tmp files is created"
  fi
}

function phase() {
  echo ""
  echo "*****$******"
}

if [[ -z $1 ]]
then
  usage
fi

if [[ -z $2 ]]
then
  usage
fi

# variables
# for export batch
starttime=$(date -d $1 +%s)000
endtime=$(date -d $2 +%s)000
srchdfs="hdfs://malvin-hdp2-m1.example.com:8020"
desthdfs="hdfs://malvin-cdp-m1.example.com:8020"
#outputdirp="hdfs://isicdp.example.com:8020/tmp/"
outputdirp="$desthdfs/tmp/"

# for send $desclist to cdp hdfs
srcdir="/tmp"
destdir="/tmp"

# dir for tmp files
tmpdir="OMNI_TMP_FILES/"
maketmpdir $tmpdir

# files
tablelist="${tmpdir}table.list-$1-$2.tmp" # new line seperated tables
listlist="${tmpdir}list.list-$1-$2.tmp" # hbase shell list output
desclistfilename="desc.list-$1-$2.tmp"
desclist="${tmpdir}$desclistfilename" # hbase shell desc 'table' output
desclistfile="/$desclistfilename"

# generate table list
if [[ -f $tablelist ]]
then
  echo "$tablelist exists, remove old tmp file"
  rm -rf $tablelist
fi
echo "list"|hbase shell -n >$listlist
lines=$(($(($(cat $listlist|wc -l)-3))/2))
#echo $lines
cat $listlist|tail -n $lines >$tablelist
if [[ -f $tablelist ]]
then
  echo "$tablelist is created"
fi

# export desc table
descline=""
while read t
do
  descseg="desc '$t'"
  descline=$descline"\n"$descseg
done <$tablelist
#rm -rf $tablelist

if [[ -f $desclist ]]
then
  echo "$desclist exists, remove old tmp file"
  rm -rf $desclist
fi

echo -e $descline|hbase shell -n >>$desclist
echo "$desclist is created."


# send $desclist to cdp hdfs
distcpout="${tmpdir}mr-distcp.out.tmp"
hdfs dfs -put -f $desclist $srcdir
#echo $desclist $srcdir
hadoop distcp -overwrite $srchdfs$srcdir$desclistfile $desthdfs$destdir >$distcpout 2>&1
#echo $srchdfs$srcdir$desclistfile $desthdfs$destdir
echo "$desclist is sent to CDP at $desthdfs$destdir$desclistfilename."


# EXPORT BATCH

# files
checklist="${tmpdir}success.table.list-$1-$2.tmp" # new line seperated tables

banner "START TABLE EXPORT"
if [[ -f $checklist ]]
then
  echo "checklist exists"
else
  touch $checklist
  echo "checklist $checklist is touched"
fi

while read t
do
  # variables
  name="$t-$1-$2"
  outputdir="export-$name"

  # files
  expout="${tmpdir}mr-$outputdir.out.tmp" # mapreduce.Export output
  rcout="${tmpdir}mr-rc-$name.out.tmp" # mapreduce.RowCount output
  rclist="${tmpdir}rc.table.list-$1-$2.tmp" # new line seperated rowcount outcome, each line look like: table,100

  # check if table export done
  success=$(grep -w $t $checklist)
  if [[ $success = $t ]]
  then
    echo "table $t is done, continue with next table"
    continue
  else
    phase "START table $t EXPORT"
  fi

  hbase org.apache.hadoop.hbase.mapreduce.Export $t $outputdirp$outputdir 1 $starttime $endtime >$expout 2>&1
  #a=$(hbase org.apache.hadoop.hbase.mapreduce.Export $t $outputdirp$outputdir 1 $starttime $endtime)
  #echo $starttime $endtime
  echo "output directory:" $outputdirp$outputdir
  echo $expout
  
  # record table export successful
  checkstring="successfully"
  check=$(grep $checkstring $expout)
  if [[ $check =~ $checkstring ]]
  then 
    echo $t >> $checklist
    echo $check
  else
    echo "Export failed..."
  fi
  
  # record table row count
  # use MapReduce (plan A)
  hbase org.apache.hadoop.hbase.mapreduce.RowCounter $t --starttime=$starttime --endtime=$endtime >$rcout 2>&1
  rowstring="ROWS="
  rows=$(grep $rowstring $rcout|sed 's/[[:space:]][[:space:]]*//'|cut -d'=' -f2)
  echo $rcout
  if [[ -z $rows ]]
  then
     rows=0
  fi
  echo $rowstring$rows
  echo "$t,$rows" >>$rclist
  
  # use hbase shell (slow, plan B)
  #rows=$(echo -e "import org.apache.hadoop.hbase.filter.FirstKeyOnlyFilter;\nscan '$t', {FILTER=>FirstKeyOnlyFilter.new(),TIMERANGE => [$starttime, $endtime]}"|hbase shell -n|grep "row(s)"|cut -d' ' -f1)
  #echo "$t,$rows" >>$rclist
  
done <$tablelist