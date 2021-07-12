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
  echo "directory $tmpdir for tmp files exists"
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
tablelistE="${tmpdir}exist.table.list.tmp"

altertablelist="${tmpdir}altertable.list-$1-$2.tmp"
tabletobealteredlist="${tmpdir}tablatobealtered.list-$1-$2.tmp"
tablealteredlist="${tmpdir}tablealtered.out.list-$1-$2.tmp"

# CREATE TABLE IF NOT EXISTS

# generate table list in CDP HBase
echo "list"|hbase shell -n >list.list.tmp
lines=$(($(($(cat list.list.tmp|wc -l)-3))/2))
#echo $lines
cat list.list.tmp|tail -n $lines >$tablelistE
rm -f list.list.tmp

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
    #echo $createtable
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
    if [[ $(grep -v OMNI_TMP $tablelistE) =~ $tableA ]]
    then
      echo "$tableA exists"
    else
      echo $createtable >>$createtablelistO
      echo $createtable
    fi
    createtable=""
    #echo 'the end of desc'
    #echo -e "\n*****createtable string:\n$createtable\n"
  fi
done <$desclist

# create table through hbase shell
if [[ -f $createtablelistO ]]
then
  echo "$createtablelistO is created"
else
  touch $createtablelistO
  echo "no table to be created, $createtablelistO is touched"
fi

ctb=""
while read l
do
  cta=$l
  ctb=$ctb"\n"$cta
done <$createtablelistO

echo -e $ctb|hbase shell -n >>$tablecreatedlistO
echo "Tables above are created."

# ALTER TABLE ATTRIBUTES FOR PHOENIX

# generate table list in CDP HBase after origin table created
#echo "list"|hbase shell -n >list.list.tmp
#lines=$(($(($(cat list.list.tmp|wc -l)-3))/2))
#echo $lines
#cat list.list.tmp|tail -n $lines >$tablelistE
#rm -f list.list.tmp

#while read t
#do
#  if [[ $t =~ "SYSTEM" ]]
#  then
#    echo "table $t is PHOENIX system talbe"
#  elif [[ $t =~ "OMNI_TMP" ]]
#  then
#    echo "table $t is tmp table"
#  else
#    echo "alter '$t', ..."
#    echo "alter '$t', 'coprocessor$1' => '|org.apache.phoenix.coprocessor.ScanRegionObserver|805306366|', 'coprocessor$2' => '|org.apache.phoenix.coprocessor.UngroupedAggregateRegionObserver|805306366|', 'coprocessor$3' => '|org.apache.phoenix.coprocessor.GroupedAggregateRegionObserver|805306366|', 'coprocessor$4' => '|org.apache.phoenix.coprocessor.ServerCachingEndpointImpl|805306366|', 'coprocessor$5' => '|org.apache.phoenix.hbase.index.IndexRegionObserver|805306366|index.builder=org.apache.phoenix.index.PhoenixIndexBuilder,org.apache.hadoop.hbase.index.codec.class=org.apache.phoenix.index.PhoenixIndexCodec', 'coprocessor$6' => '|org.apache.phoenix.coprocessor.PhoenixTTLRegionObserver|805306364|'" >>$altertablelist
#  fi
#done <$tablelistE

tableA=""
while read l
do
  table="Table"
  schema=$tableA
  #echo "**********"
  #echo $l
  #echo "**********"
  #echo -e "\n*****altertable string:\n$altertable\n"
  if [[ $l =~ $table ]]
  then
    tableA=$(echo $l|cut -d' ' -f2)

    # differ system table and tmp table
    if [[ $tableA =~ "SYSTEM" ]]
    then
      echo "table $tableA is PHOENIX system talbe"
      continue
    elif [[ $tableA =~ "OMNI_TMP" ]]
    then
      echo "table $tableA is tmp table"
      continue
    fi

    tableC=$(echo $tableA|sed "s/^/\'/;s/$/\'/")
    echo $tableA >>$tabletobealteredlist
    echo $tableC
    echo '^^^this is table^^^'
    altertable="alter $tableC"
    #echo -e "\n*****altertable string:\n$altertable\n"
    continue
  fi
  if [[ $l =~ $schema ]]
  then
    schemaA=$(echo $l|sed -e "s/$tableA, {TABLE_ATTRIBUTES => {//;s/}$//;s/coprocessor\$[0-9]/'&'/g;s/METADATA/'&'/")
    altertable="$altertable, $schemaA"
    if [[ $schemaA =~ "coprocessor" ]] && [[ $altertable =~ $schema ]]
    then
      echo $schemaA
      echo "^^^this is schema^^^"
      altertable="$altertable, $schemaA"
      #echo -e "\n*****altertable string:\n$altertable\n"
    else
      altertable=""
    fi
    continue
  fi
  if [[ $l = "nil" ]]
  then
    echo $altertable >>$altertablelist
    altertable=""
    #echo 'the end of desc'
  fi
done <$desclist

# alter table through hbase shell
atb=""
while read l
do
  ata=$l
  atb=$atb"\n"$ata
done <$altertablelist

echo -e $atb|hbase shell -n >>$tablealteredlist
echo "Tables above are altered."

# MERGE TABLE BATCH

# variables
starttime=$(date -d $1 +%s)000
endtime=$(date -d $2 +%s)000

# files
checklistM="${tmpdir}merge.success.table.list-$1-$2.tmp" # new line seperated tables

echo -e "\n####################\n#\n#START TABLE MERGE\n#\n####################\n"
if [[ -f $checklistM ]]
then
  echo "checklist exists"
else
  touch $checklistM
  echo "checklist $checklistM is touched"
fi

while read t
do 
  # variables
  tmpt="${t}_OMNI_TMP"

  # files
  cpout="${tmpdir}mr-cp-$tmpt.out-$1-$2.tmp" # mapreduce.CopyTable output
  rcoutM="${tmpdir}merge.mr-rc-$t-$1-$2.out.tmp" # mapreduce.RowCount ouput
  rclistM="${tmpdir}merge.rc.table.list-$1-$2.tmp" # new line seperated row count outcome, each line look like: table,100

  # check if table merge done
  success=$(grep -w $t $checklistM)
  echo $success
  if [[ $success = $t ]]
  then
    echo "table $t is done, continue with next table"
    continue
  else
    echo -e "\n*****START table $t and $tmpt MERGE*****"
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
    echo "Merge failed..."
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
