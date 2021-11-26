function usage() {
   echo -e "Usage:  sh $0 tableNamePatern tableNumber\n\te.g.\n\tsh $0 TEST.TEST 100"
   exit 1
}

function serial_num () {
  i=$*
  len=`expr length $i`
  #echo $len
  if [ $len == '1' ]
  then
    number="000"$i
  elif [ $len == '2' ]
  then
    number="00"$i
  elif [ $len == '3' ]
  then
    number="0"$i
  else
    number=$i
  fi
  return $number
}

if [[ -z $1 ]]
then
  usage
  exit 1
fi

if [[ -z $2 ]]
then
  usage
  exit 1
fi

# variables
tableNamePattern=$1
tableNumber=$2
tmpdir='tmp'

# files
createtablelist=$tmpdir"createtable.list.tmp"
tablecreatedlist=$tmpdir"tablecreated.output.tmp"

rm -f $createtablelist
for i in $(seq 1 $tableNumber)
do
  serial_num $i
  #echo $number
  tableName=$tableNamePattern$number
  #echo $tableName
  echo "create '$tableName','cf'">>$createtablelist
done

# create table through hbase shell
ctb=""
while read l
do
  cta=$l
  ctb=$ctb"\n"$cta
done <$createtablelist

echo -e $ctb
echo -e $ctb|hbase shell -n >>$tablecreatedlist
echo "All table is created."
