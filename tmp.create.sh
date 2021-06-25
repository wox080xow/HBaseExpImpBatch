#grep -e "^Table" desc.list.tmp|cut -d' ' -f2

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
  #cf="{NAME"
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

#echo -e $ctb|hbase shell -n >>$tablecreatedlist
echo "All table is created."
