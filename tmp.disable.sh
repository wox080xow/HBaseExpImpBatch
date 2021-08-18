# list of drop table line
disabletable=""

tmpdir="OMNI_TMP_FILES/"

# files
disabletablelist=$tmpdir"disabletable.list.tmp"
tabledisabledlist=$tmpdir"tabledisabled.out.list.tmp"
tablelisttarget=$tmpdir"table.list.tmp.target"

rm -f $disabletablelist $droptablelist
while read t 
do
  tableAd=$(echo $t|sed "s/^/\'/;s/$/\'/")
  disabletable="disable $tableAd"
  #disabletable="enable $tableAd" # for enable tables...
  echo $disabletable >>$disabletablelist
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
echo "Tables above are disabled."
