LIST=('SYSTEM.CATALOG' 'SYSTEM.FUNCTION' 'SYSTEM.SEQUENCE' 'SYSTEM.STATS')

b=""
for t in ${LIST[@]}
do 
  a="desc '$t'"
  b=$b"\n"$a
done

echo -e $b
echo -e $b|hbase shell -n >>OMNI_TMP_FILES/systemtables.desc.list.tmp
