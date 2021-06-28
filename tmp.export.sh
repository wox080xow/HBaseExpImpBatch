# variables
starttime=$(date -d $1 +%s)
endtime=$(date -d $2 +%s)
#outputdirp="hdfs://isicdp.example.com:8020/tmp/"
#outputdirp="/tmp/"
outputdir="hdfs://malvin-cdp-m1.example.com:8020/tmp/"

# files
tablelist="table.list.tmp" # new line seperated tables
desclist="desc.list.tmp" # hbase shell desc 'table' output

# generate table list
echo "list"|hbase shell -n >list.hbaseshell.tmp
lines=$(($(($(cat list.hb.tmp|wc -l)-3))/2))
#echo $lines
cat list.hbaseshell.tmp|tail -n $lines >$tablelist
echo "$tablelist is created"

# export desc table
descline=""
while read t
do
  descseg="desc '$t'"
  descline=$descline"\n"$descseg
done <$tablelist
rm -rf $tablelist

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
  mrout="mr-$outputdir.out.tmp" # mapreduce.Export output
  rcout="rc-$name.out.tmp" # mapreduce.RowCount output
  checklist="success.table.list.tmp" # new line seperated tables
  rclist="rc.table.list.tmp" # new line seperated rowcount outcome, each line look like: table,100

  # check if table export done
  echo "START table $t EXPORT"
  if [ -f success.table.list.tmp ]
  then
    echo "checklist exists"
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

  hbase org.apache.hadoop.hbase.mapreduce.Export $t $outputdirp$outputdir 1 $starttime $endtime >$mrout 2>&1
  #a=$(hbase org.apache.hadoop.hbase.mapreduce.Export $t $outputdirp$outputdir 1 $starttime $endtime)
  echo $starttime $endtime
  echo $outputdirp$outputdir
  echo $mrout
  echo $rcout
  
  # record table export successful
  checkstring="successfully"
  check=$(grep $string $mrout)
  echo $check
  if [[ $check =~ $checkstring ]]
  then 
    echo $t >> $checklist
  fi
  
  # record table and row count
  hbase org.apache.hadoop.hbase.mapreduce.RowCounter $t --starttime=$starttime --endtime=$endtime >$rcout 2>&1
  rowstring="ROWS"
  rows=$(grep $rowstring $rcout|sed 's/[[:space:]][[:space:]]*//'|cut -d'=' -f2)
  echo $rows
  echo "$t,$rows" >>$rclist
done <$tablelist
