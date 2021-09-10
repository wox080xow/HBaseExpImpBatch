echo "list"|hbase shell -n >list.hb.tmp
lines=$(($(($(cat list.hb.tmp|wc -l)-3))/2))
#echo $lines
cat list.hb.tmp|tail -n $lines >OMNI_TMP_FILES/table.list.tmp.target
rm -f list.hb.tmp
