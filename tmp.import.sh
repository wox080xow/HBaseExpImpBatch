while read t
do 
  hbase org.apache.hadoop.hbase.mapreduce.Import $t /tmp/export-$t
done < tmp.table.list

# list of drop table line
disabletable=""
droptable=""

# files
tabletobecreatedlist="tabletobecreated.list.tmp"
disabletablelist="disabletable.list.tmp"
droptablelist="droptable.list.tmp"
tabledisabledlist="tabledisabled.out.list.tmp"
tabledroppedlist="tabledropped.out.list.tmp"
desclist="desc.list.tmp"

rm -f $disabletablelist $droptablelist
while read t
do
  tableAd=$(echo $t|sed "s/^/\'/;s/$/\'/")
  disabletable="disable $tableAd"
  droptable="drop $tableAd"
  echo $disabletable >>$disabletablelist
  echo $droptable >>$droptablelist
done <$tabletobecreatedlist

# disable table through hbase shell
dtb=""
while read l
do
  dta=$l
  dtb=$dtb"\n"$dta
done <$disabletablelist

echo -e $dtb
echo -e $dtb|hbase shell -n >>$tabledisabledlist
echo "All tables are disabled."

# drop table through hbase shell
dtb=""
while read l
do
  dta=$l
  dtb=$dtb"\n"$dta
done <$droptablelist

echo -e $dtb
echo -e $dtb|hbase shell -n >>$tabledroppedlist
echo "All tables are dropped."


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
#inputdirp="hdfs://isicdp.example.com:8020/tmp/"
inputdirp="/tmp/"
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
  inputdir="export-$name"
  mrout="mr-$inputdir.out.tmp"
  rcout="rc-$name.out.tmp"
  checklist="success.table.list.tmp"
  rclist="rc.table.list.tmp"

  # check if table import done
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

  hbase org.apache.hadoop.hbase.mapreduce.Import $t $inputdirp$inputdir >$mrout 2>&1
  #a=$(hbase org.apache.hadoop.hbase.mapreduce.Import $t $inputdirp$inputdir 1 $starttime $endtime)
  echo $starttime $endtime
  echo $inputdirp$inputdir
  echo $mrout
  echo $rcout
  
  # record table import successful
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
