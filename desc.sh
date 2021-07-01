echo "list"|hbase shell -n >list.list.tmp
lines=$(($(($(cat list.list.tmp|wc -l)-3))/2))
cat list.list.tmp|tail -n $lines >table.list.tmp
rm -rf list.list.tmp

b=""
while read t
do 
  a="desc '$t'"
  b=$b"\n"$a
done <table.list.tmp
rm -rf table.list.tmp

desclist="OMNI_TMP_FILES/desc.list.tmp"
echo -e $b|hbase shell -n >>$desclist
echo "$desclist is created."
