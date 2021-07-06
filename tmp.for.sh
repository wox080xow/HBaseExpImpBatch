function loop1() {
  num1=$((k*10-10))
  num2=$((k*10))
  for i in $(seq $num1 $num2)
  do
    echo $i
  done

}

for ((k=1;k<=5;k++))
do
  loop1
done
