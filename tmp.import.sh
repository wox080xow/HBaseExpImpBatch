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
disabletablelist="${tmpdir}disabletable.list.tmp" # hbase shell disable 'table' input
droptablelist="${tmpdir}droptable.list.tmp" # habase shell drop 'table' input
tabledisabledlist="${tmpdir}tabledisabled.out.list.tmp" # hbase shell disable 'talbe' output
tabledroppedlist="${tmpdir}tabledropped.out.list.tmp" # hbase shell drop 'table' output

desclist="${tmpdir}desc.list.tmp" # hbase shell desc 'table' output FROM HDP
tablelist="${tmpdir}table.list.tmp" new line seperated tables
tabletobecreatedlist="${tmpdir}tabletobecreated.list.tmp" new line seperated tmp tables
createtablelist="${tmpdir}createtable.list.tmp" # hbase shell create 'table','cf',... input
tablecreatedlist="${tmpdir}tablecreated.list.tmp" # hbase shell create 'table,'cf',... output

# DROP TEMP TABLES

# list of drop table line
disabletable=""
droptable=""

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
    echo $tableA >>$tablelist
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

# import batch
while read t
do
  # variables
  name="$t-$1-$2"
  inputdir="export-$name"
  tmpt=${t}_OMNI_TMP

  # files
  impout="${tmpdir}mr-imp-$inputdir.out.tmp" # mapreduce.Import output
  rcout="${tmpdir}mr-rc-$name.out.tmp" # mapreduce.RowCount ouput
  checklist="${tmpdir}success.table.list.tmp" # new line seperated tables
  rclist="${tmpdir}rc.table.list.tmp" # new line seperated row count outcome, each line look like: table,100

  # check if table import done
  echo "START table $tmpt IMPORT"
  if [ -f success.table.list.tmp ]
  then
    echo "checklist exists"
  else
    touch $checklist
    echo "checklist $checklist is touched"
  fi
  success=$(grep -w $tmpt $checklist)
  echo $success
  if [[ $success = $tmpt ]]
  then
    echo "table $tmpt is done, continue with next table"
    continue
  fi

  hbase org.apache.hadoop.hbase.mapreduce.Import $tmpt $inputdirp$inputdir >$impout 2>&1
  echo $starttime $endtime
  echo $inputdirp$inputdir
  echo $impout
  echo $rcout
  
  # record table import successful
  checkstring="successfully"
  check=$(grep $string $impout)
  echo $check
  if [[ $check =~ $checkstring ]]
  then 
    echo $tmpt >> $checklist
  fi
  
  # record table and row count
  hbase org.apache.hadoop.hbase.mapreduce.RowCounter $tmpt --starttime=$starttime --endtime=$endtime >$rcout 2>&1
  rowstring="ROWS"
  rows=$(grep $rowstring $rcout|sed 's/[[:space:]][[:space:]]*//'|cut -d'=' -f2)
  echo $rows
  echo "$tmpt,$rows" >>$rclist
done <$tablelist
