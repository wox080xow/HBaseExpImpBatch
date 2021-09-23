# list of drop table line
snapshottable=""

tmpdir="OMNI_TMP_FILES/"

# files
snapshottablelist=$tmpdir"snapshottable.list.tmp"
tablesnapshootlist=$tmpdir"tablesnapshoot.out.list.tmp"
tablelisttarget=$tmpdir"table.list.tmp.target"

rm -f $snapshottablelist
ymd=$(date +%y%m%d)
while read t 
do
  tableAd=$(echo $t|sed "s/^/\'/;s/$/\'/")
  snapshotAd=$(echo "${t}_SS_$ymd"|sed "s/^/\'/;s/$/\'/")
  snapshottable="clone_snapshot $snapshotAd, $tableAd"
  echo $snapshottable >>$snapshottablelist
#done <$tabletobecreatedlist
done <$tablelisttarget

# snapshot table through hbase shell
dtb=""
while read l
do
  dta=$l
  dtb=$dtb"\n"$dta
done <$snapshottablelist

echo -e $dtb
echo -e $dtb|hbase shell -n >>$tablesnapshootlist
echo "All tables are cloned."