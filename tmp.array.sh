LIST=('SYSTEM.CATALOG' 'SYSTEM.FUNCTION' 'SYSTEM.SEQUENCE' 'SYSTEM.STAT')

for val in ${LIST[@]}
do
  echo "Export $val"
done
