#variables
table=$1
cf=$2
start=210101
starttime=$(date -d $start +%s)000

function usage() {
   echo -e "Usage:  sh $0 table columnfamily\n\te.g.\n\tsh $0 t1 cf"
   exit 1
}

function putloop() {
  # $1 table name
  # $2 cf
  # $3 timestimp
  putvalue=""
  
  startrow=$((k*10-10))
  endrow=$((k*10))
  for i in $(seq $startrow $endrow)
  do
    putvalueline="put '$1','$i','$2:C1','value$i',$3"
    putvalue="$putvalue\n$putvalueline"
  done
  echo $putvalue
}

# MAIN

if [[ -z $1 ]]
then
  usage
fi

if [[ -z $2 ]]
then
  usage
fi

put=""
for ((k=1;k<=30;k++))
do
  echo "第$k天"
  echo $start
  starttime=$(date -d $start +%s)000
  echo $starttime
  put="$put\n$(putloop $table $cf $starttime)"
  start=$(($start+1))
done
echo -e $put|hbase shell -n
#echo -e $put
