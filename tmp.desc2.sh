echo "list"|hbase shell -n >list.hb.tmp
lines=$(($(($(cat list.hb.tmp|wc -l)-3))/2))
#echo $lines
cat list.hb.tmp|tail -n $lines >table.list

b=""
while read t
do 
  a="desc '$t'"
  b=$b"\n"$a
done <table.list

echo -e $b|hbase shell -n >>desc.list
#echo -e $b
rm -rf table.list
