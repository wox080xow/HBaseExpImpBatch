function usage() {
  echo -e "Usage:  sh $0 starttime endtime\n\te.g.\n\tsh $0 210601 210630"
  exit 1
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

function banner() {
  echo ""
  echo "##################################################################################"
  echo "##"
  echo "## $*"
  echo "##"
  echo "##################################################################################"
  echo ""
}

function phase() {
  echo ""
  echo "*****$******"
}

function exp() {
  # check if table export done
  success=$(grep -w $t $checklist)
  if [[ $success = $t ]]
  then
    echo "table $t is done, continue with next table"
    continue
  else
    phase "START table $t EXPORT"
  fi

  file=$outputdirp$outputdir
  #filecheckstring="No such file or directory"
  filecheck=$(hdfs dfs -ls $file)

  if [[ $file =~ $filecheck ]]
  then
    echo $filecheck
    hdfs dfs -rm -r $file
    echo "Remove Failed Export output $file"
  else
    #echo $filecheck
    echo "No file on hdfs"
  fi

  hbase org.apache.hadoop.hbase.mapreduce.Export $t $outputdirp$outputdir 1 $starttime $endtime >$expout 2>&1
  echo "$t output directory:" $outputdirp$outputdir
  echo $expout
  
  # record table export successful
  checkstring="successfully"
  check=$(grep --binary-files=text $checkstring $expout)
  if [[ $check =~ $checkstring ]]
  then 
    echo $t >> $checklist
    echo $t $check
  else
    echo "$t Export failed..."
  fi
}

function rc() {
  # record table row count
  # use MapReduce (plan A)
  hbase org.apache.hadoop.hbase.mapreduce.RowCounter $t --starttime=$starttime --endtime=$endtime >$rcout 2>&1
  rowstring="ROWS="
  rows=$(grep --binary-files=text $rowstring $rcout|sed 's/[[:space:]][[:space:]]*//'|cut -d'=' -f2)
  echo $rcout
  if [[ -z $rows ]]
  then
     rows=0
  fi
  phase "table $t $rowstring$rows"
  echo "$t,$rows" >>$rclist
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

excllist="${tmpdir}excl.table.list.tmp"

# generate table list
if [[ -f $tablelist ]]
then
  echo "$tablelist exists, remove old tmp file"
  rm -rf $tablelist
fi
echo "list"|hbase shell -n >$listlist
lines=$(($(($(cat $listlist|wc -l)-3))/2))

#echo $lines
cat $listlist|tail -n $lines|grep -v "TEMP\." >$tablelist
if [[ -f $tablelist ]]
then
  echo "TEMPFILE $tablelist is created"
fi

# generate desc table
descline=""
while read t
do
  descseg="desc '$t'"
  descline=$descline"\n"$descseg
done <$tablelist

if [[ -f $desclist ]]
then
  echo "$desclist exists, remove old tmp file"
  rm -rf $desclist
fi

echo -e $descline|hbase shell -n >>$desclist

if [[ -f $tablelist ]]
then
  echo "TEMPFILE $desclist is created"
fi

# generate tablelist without TEMP and DISABLED tables
if [[ -f $tablelist ]]
then
  echo "TEMPFILE $tablelist exists, remove old tmp file"
  rm -rf $tablelist
fi

while read l
do
  table="Table"
  enabledstring="ENABLED"
  # exclude disabled table
  if [[ $l =~ $table ]]
  then
    tableAl=$(echo $l|cut -d' ' -f2)
    if [[ $l =~ $enabledstring ]]
    then
      echo "table $tableAl is an enabled table from src"
      echo $tableAl >>$tablelist
    else
      echo "table $tableAl is a disabled table from src"
    fi
  fi
done <$desclist
echo "tablelist $tablelist is created"

# make tablelist exclude problematic tables and Phoenix SYSTEM tables
while read l
do
  sed -i "/$l/d" $tablelist
done <$excllist

# generate desclist without TEMP and DISABLED tables
if [[ -f $desclist ]]
then
  echo "TEMPFILE $desclist exists, remove old tmp file"
  rm -rf $desclist
fi

descline=""
while read t
do
  descseg="desc '$t'"
  descline=$descline"\n"$descseg
done <$tablelist

echo -e $descline|hbase shell -n >>$desclist
echo "desclist $desclist is created."

# send $desclist to cdp hdfs
distcpout="${tmpdir}mr-distcp.out.tmp"
#hdfs dfs -put -f $desclist $srcdir
#hadoop distcp -overwrite $srchdfs$srcdir$desclistfile $desthdfs$destdir >$distcpout 2>&1
#echo "$desclist is sent to CDP at $desthdfs$destdir$desclistfilename."
hdfs dfs -put -f $desclist $outputdirp
echo "$desclist is sent to CDP at $outputdirp$desclistfilename"

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

n=1
while read t
do
  # variables
  name="$t-$1-$2"
  outputdir="export-$name"

  # files
  expout="${tmpdir}mr-$outputdir.out.tmp" # mapreduce.Export output
  rcout="${tmpdir}mr-rc-$name.out.tmp" # mapreduce.RowCount output
  rclistfilename="export.rc.table.list-$1-$2.tmp" 
  rclist="${tmpdir}$rclistfilename" # new line seperated rowcount outcome, each line look like: table,100

  if [ $n -lt 5 ]
  then
    # banner "batch"$n"/3"
    exp && rc &
  else
    # banner "batch"$n"/3"
    exp && wait && rc &
    wait
    banner "$n tables above are done"
    n=0
  fi
  n=$(($n+1))
  
done <$tablelist

# send $rclist to cdp hdfs
hdfs dfs -put -f $rclist $outputdirp
echo "$rclist is sent to CDP at $outputdirp$rclistfilename"
