echo "list"|hbase shell -n >list.hb.tmp
lines=$(($(($(cat list.hb.tmp|wc -l)-3))/2))
#echo $lines
cat list.hb.tmp|tail -n $lines >table.list
while read t
do 
  echo "desc '$t'"|hbase shell -n >>desc.list
  echo "\n" >>desc.list
  echo "$t is done."
done <table.list
rm -rf table.list
