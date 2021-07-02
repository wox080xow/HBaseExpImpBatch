grep -e "^Table" desc.list.tmp|cut -d' ' -f2

# list of drop table line
disabletable=""
droptable=""

tmpdir="OMNI_TMP_FILES/"

# files
tabletobecreatedlist=$tmpdir"tabletobecreated.list.tmp"
disabletablelist=$tmpdir"disabletable.list.tmp"
droptablelist=$tmpdir"droptable.list.tmp"
tabledisabledlist=$tmpdir"tabledisabled.out.list.tmp"
tabledroppedlist=$tmpdir"tabledropped.out.list.tmp"
desclist=$tmpdir"desc.list.tmp"
tablelisttarget=$tmpdir"table.list.

rm -f $disabletablelist $droptablelist
while read t 
do
  tableAd=$(echo $t|sed "s/^/\'/;s/$/\'/")
  disabletable="disable $tableAd"
  droptable="drop $tableAd"
  echo $disabletable >>$disabletablelist
  echo $droptable >>$droptablelist
#done <$tabletobecreatedlist
done <$tablelisttarget

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
