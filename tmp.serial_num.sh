function serial_num () {
  i=$*
  len=`expr length $i`
  echo $len
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

serial_num $1
echo $number
