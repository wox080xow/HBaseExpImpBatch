function exp() {
  echo $* "export"
  sleep 3
}

function rc() {
  echo $* "rowcounter"
  sleep 3
}

n=1
echo n init: $n
for ((i=1;i<=30;i++))
do
  if [ $n -lt 5 ]
  then
    # echo $n
    exp $i && rc $i &
    # sh tmp.if.test.exp.sh $n && sh tmp.if.test.rc.sh $n &
  else
    # echo $n
    exp $i && wait && rc $i &
    wait
    # sh tmp.if.test.exp.sh $n && wait && sh tmp.if.test.rc.sh $n &
    echo -e "^^^batch cycle $n/5^^^\n"
    n=0
  fi
  n=$(($n+1))
done
