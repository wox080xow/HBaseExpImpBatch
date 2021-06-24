#grep -e "^Table" desc.list.tmp|cut -d' ' -f2

while read t
do 
  #echo "create $t"|hbase shell -n
  echo "create $t"
done <
