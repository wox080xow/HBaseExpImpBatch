# list of drop table line
enabletable=""

tmpdir="OMNI_TMP_FILES/"

# files
#tabletobecreatedlist=$tmpdir"tabletobecreated.list.tmp"
tablelist=$tmpdir"table.list.tmp"
enabletablelist=$tmpdir"enabletable.list.tmp"
tableenabledlist=$tmpdir"tableenabled.out.list.tmp"

rm -f $enabletablelist 
while read t 
do
  tableAd=$(echo $t|sed "s/^/\'/;s/$/\'/")
  enabletable="enable $tableAd"
  echo $enabletable >>$enabletablelist
done <$tablelist

# enable table through hbase shell
dtb=""
while read l
do
  dta=$l
  dtb=$dtb"\n"$dta
done <$enabletablelist

echo -e $dtb
echo -e $dtb|hbase shell -n >>$tableenabledlist
echo "All tables are enabled."
