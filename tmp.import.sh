while read t
do 
  hbase org.apache.hadoop.hbase.mapreduce.Import $t /tmp/export-$t
done < tmp.table.list

# CREATE TEMP TABLE

# list of create table line
createtable=""

# files
createtablelist="createtable.list.tmp"
tabletobecreatedlist="tabletobecreated.list.tmp"
tablecreatedlist="tablecreated.list.tmp"
desclist="desc.list.tmp"

rm -f $createtablelist
while read l
do
  table="Table"
  cf="NAME =>"
  #echo $l
  #echo -e "\n*****createtable string:\n$createtable\n"
  if [[ $l =~ $table ]]
  then
    tableA=$(echo $l|cut -d' ' -f2)
    tableB=$(echo "${tableA}_OMNI_TMP")
    tableC=$(echo $tableB|sed "s/^/\'/;s/$/\'/")
    echo $tableB >>$tabletobecreatedlist
    echo $tableC
    echo 'this is table'
    createtable="create $tableB"
    #echo -e "\n*****createtable string:\n$createtable\n"
  fi
  if [[ $l =~ $cf ]]
  then
    #echo $l|sed 's/FOREVER/org.apache.hadoop.hbase.HConstants::FOREVER/'
    echo $l|sed "s/ TTL => 'FOREVER',//"
    #echo 'this is column family'
    #createtable="$createtable, $(echo $l|sed 's/FOREVER/org.apache.hadoop.hbase.HConstants::FOREVER/')"
    createtable="$createtable, $(echo $l|sed "s/ TTL => 'FOREVER',//")"
    #echo -e "\n*****createtable string:\n$createtable\n"
  fi
  if [[ $l = "nil" ]]
  then
    echo $createtable >>$createtablelist
    createtable=""
    #echo 'the end of desc'
  fi
done <$desclist

# create table through hbase shell
ctb=""
while read l
do
  cta=$l
  ctb=$ctb"\n"$cta
done <$createtablelist

echo -e $ctb|hbase shell -n >>$tablecreatedlist
echo "All table is created."

# variables
starttime=$(date -d $1 +%s)
endtime=$(date -d $2 +%s)
#outputdirp="hdfs://isicdp.example.com:8020/tmp/"
outputdirp="/tmp/"
tablelist="table.list.tmp"

# generate table list
echo "list"|hbase shell -n >list.hbaseshell.tmp
lines=$(($(($(cat list.hb.tmp|wc -l)-3))/2))
#echo $lines
cat list.hbaseshell.tmp|tail -n $lines >$tablelist

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
done <$tablelist
