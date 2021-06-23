starttime=$(date -d $1 +%s)
endtime=$(date -d $2 +%s)
#outputdirp="hdfs://isicdp.example.com:8020/tmp/"
outputdirp="/tmp/"
while read t
do
  # variables
  name="$t-$1-$2"
  outputdir="export-$name"
  mrout="mr-$outputdir.out.tmp"
  rcout="rc-$name.out.tmp"
  checklist="success.table.list.tmp"
  rclist="rc.table.list.tmp"

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
done <tmp.table.list
