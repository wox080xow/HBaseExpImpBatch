grep -e "^Table" desc.list.tmp|cut -d' ' -f2

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
