function usage() {
   echo -e "Usage:  sh $0 starttime endtime\n\te.g.\n\tsh $0 210601 210630"
   exit 1
}

if [[ -z $1 ]]
then
  usage
  exit 1
fi

if [[ -z $2 ]]
then
  usage
  exit 1
fi

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
desclist="${tmpdir}desc.list-$1-$2.tmp" # hbase shell desc 'table' output from HDP
tablelist="${tmpdir}table.list-$1-$2.tmp" # new line seperated tables generated by tmp.import.sh

tablelistO="${tmpdir}origin.table.list-$1-$2.tmp" # new line seperated tables for original table check
tabletobecreatedlistO="${tmpdir}origin.tabletobecreated.list-$1-$2.tmp" # new line seperated tmp tables
createtablelistO="${tmpdir}origin.createtable.list-$1-$2.tmp" # hbase shell create 'table','cf',... input
tablecreatedlistO="${tmpdir}origin.tablecreated.out.list-$1-$2.tmp" # hbase shell create 'table,'cf',... output

# CREATE TABLE IF NOT EXISTS

# generate table list in CDP HBase
#echo "list"|hbase shell -n >list.list.tmp
#lines=$(($(($(cat list.list.tmp|wc -l)-3))/2))
#cat list.list.tmp|tail -n $lines >$tablelistO
#rm -rf list.list.tmp

# list of create table line
createtable=""

rm -f $createtablelistO $tabletobecreatedlistO
echo "tmp files $createtablelistO and $tabletobecreatedlistO are removed"

while read l
do
  table="Table"
  cf="NAME =>"
  #echo $l

  # deal with table name
  if [[ $l =~ $table ]]
  then
    tableA=$(echo $l|cut -d' ' -f2)
    #tableB="${tableA}_OMNI_TMP"
    tableC=$(echo $tableA|sed "s/^/\'/;s/$/\'/")
    echo $tableA >>$tabletobecreatedlistO
    #echo $tableC
    createtable="create $tableC"
    echo $createtable
    #echo -e "\n*****createtable string:\n$createtable\n"
  fi

  # deal with column family attribute
  if [[ $l =~ $cf ]]
  then
    #createtable="$createtable, $(echo $l|sed 's/FOREVER/org.apache.hadoop.hbase.HConstants::FOREVER/')"
    createtable="$createtable, $(echo $l|sed "s/ TTL => 'FOREVER',//")"
    #echo -e "\n*****createtable string:\n$createtable\n"
  fi

  # output "hbase shell input" to file
  if [[ $l = "nil" ]]
  then
    echo $createtable >>$createtablelistO
    createtable=""
    #echo 'the end of desc'
    #echo -e "\n*****createtable string:\n$createtable\n"
  fi
done <$desclist

# create table through hbase shell
ctb=""
while read l
do
  cta=$l
  ctb=$ctb"\n"$cta
done <$createtablelistO

echo -e $ctb|hbase shell -n >>$tablecreatedlistO
echo "Tables above are created."

# MERGE TABLE BATCH

# variables
starttime=$(date -d $1 +%s)
endtime=$(date -d $2 +%s)

while read t
do 
  # variables
  tmpt="${t}_OMNI_TMP"

  # files
  cpout="${tmpdir}mr-cp-$tmpt.out.tmp" # mapreduce.CopyTable output
  rcoutM="${tmpdir}merge.mr-rc-$t-$sarttime-$endtime.out.tmp" # mapreduce.RowCount ouput
  checklistM="${tmpdir}merge.success.table.list-$1-$2.tmp" # new line seperated tables
  rclistM="${tmpdir}merge.rc.table.list-$1-$2.tmp" # new line seperated row count outcome, each line look like: table,100

  # check if table import done
  echo "START table $tmpt IMPORT"
  if [[ -f $checklistM ]]
  then
    echo "checklist exists"
  else
    touch $checklistM
    echo "checklist $checklistM is touched"
  fi
  success=$(grep -w $t $checklistM)
  echo $success
  if [[ $success = $t ]]
  then
    echo "table $t is done, continue with next table"
    continue
  else
    echo "START table $t and $tmpt MERGE"
  fi

  # merge 
  hbase org.apache.hadoop.hbase.mapreduce.CopyTable --new.name=$t $tmpt >$cpout 2>&1
  echo $cpout

  # record table merge successful
  checkstring="successfully"
  check=$(grep $checkstring $cpout)
  if [[ $check =~ $checkstring ]]
  then
    echo $t >> $checklistM
    echo $check
  else
    echo "Import failed..."
  fi

  # record table and row count
  hbase org.apache.hadoop.hbase.mapreduce.RowCounter $t --starttime=$starttime --endtime=$endtime >$rcoutM 2>&1
  rowstring="ROWS="
  rows=$(grep $rowstring $rcoutM|sed 's/[[:space:]][[:space:]]*//'|cut -d'=' -f2)
  if [[ -z $rows ]]
  then
     rows=0
  fi
  echo $rowstring$rows
  echo "$tmpt,$rows" >>$rclistM

done <$tablelist
