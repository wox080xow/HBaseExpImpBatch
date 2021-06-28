# variables
starttime=$(date -d $1 +%s)
endtime=$(date -d $2 +%s)
#outputdirp="hdfs://isicdp.example.com:8020/tmp/"
#outputdirp="/tmp/"
outputdirp="hdfs://malvin-cdp-m1.example.com:8020/tmp/"

# dir for tmp files
tmpdir="OMNI_TMP_FILES/"
if [[ -d $tmpdir ]]
then
  echo "directory $tmpdir for tmp files is exist"
else
  mkdir $tmpdir
  echo "directory $tmpdir for tmp files is created"
fi

# files
tablelist="${tmpdir}table.list.tmp" # new line seperated tables
listlist="${tmpdir}list.list.tmp" # hbase shell list output
desclist="${tmpdir}desc.list.tmp" # hbase shell desc 'table' output

# generate table list
if [[ -f $tablelist ]]
then
  echo "$tablelist is existed, remove old tmp file"
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

echo -e $descline|hbase shell -n >>$desclist
echo "$desclist is created."


# send $desclist to cdp hdfs
# echo "$desclist is sent to CDP."


# export batch
while read t
do
  # variables
  name="$t-$1-$2"
  outputdir="export-$name"

  # files
  expout="${tmpdir}mr-$outputdir.out.tmp" # mapreduce.Export output
  rcout="${tmpdir}mr-rc-$name.out.tmp" # mapreduce.RowCount output
  checklist="${tmpdir}success.table.list.tmp" # new line seperated tables
  rclist="${tmpdir}rc.table.list.tmp" # new line seperated rowcount outcome, each line look like: table,100

  # check if table export done
  echo -e "*****START table $t EXPORT*****"
  if [ -f $checklist ]
  then
    echo "checklist $checklist exists"
  else
    touch $checklist
    echo "checklist $checklist is touched"
  fi
  success=$(grep -w $t $checklist)
  echo $success
  if [[ $success = $t ]]
  then
    echo "table $t is done, continue with next table"
    continue
  fi

  hbase org.apache.hadoop.hbase.mapreduce.Export $t $outputdirp$outputdir 1 $starttime $endtime >$expout 2>&1
  #a=$(hbase org.apache.hadoop.hbase.mapreduce.Export $t $outputdirp$outputdir 1 $starttime $endtime)
  #echo $starttime $endtime
  echo "output directory:" $outputdirp$outputdir
  echo $expout
  echo $rcout
  
  # record table export successful
  checkstring="successfully"
  check=$(grep $checkstring $expout)
  echo $check
  if [[ $check =~ $checkstring ]]
  then 
    echo $t >> $checklist
  fi
  
  # record table row count
  hbase org.apache.hadoop.hbase.mapreduce.RowCounter $t --starttime=$starttime --endtime=$endtime >$rcout 2>&1
  rowstring="ROWS"
  rows=$(grep $rowstring $rcout|sed 's/[[:space:]][[:space:]]*//'|cut -d'=' -f2)
  #echo $rows
  if [[ -z $rows ]]
  then
     rows=0
  fi
  echo "$t,$rows" >>$rclist
done <$tablelist
