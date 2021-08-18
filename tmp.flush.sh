# list of drop table line
flushtable=""

tmpdir="OMNI_TMP_FILES/"

# files
flushtablelist=$tmpdir"flushtable.list.tmp"
tableflushedlist=$tmpdir"tableflushed.out.list.tmp"
tablelisttarget=$tmpdir"table.list.tmp.target"

rm -f $flushtablelist $droptablelist
while read t 
do
  tableAd=$(echo $t|sed "s/^/\'/;s/$/\'/")
  flushtable="flush $tableAd"
  echo $flushtable >>$flushtablelist
done <$tablelisttarget

# flush table through hbase shell
dtb=""
while read l
do
  dta=$l
  dtb=$dtb"\n"$dta
done <$flushtablelist

echo -e $dtb
echo -e $dtb|hbase shell -n >>$tableflushedlist
echo "Tables above are flushed."
