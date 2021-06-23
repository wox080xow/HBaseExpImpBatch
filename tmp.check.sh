while read t
do 
  echo "loop of $t"
  success=$(grep -w $t success.table.list.tmp)
  echo $success
  if [[ $success = $t ]]
  then  
    echo "continue next loop"
    continue
  else
    echo "do this loop"
  fi
  echo "work of this loop"
done <tmp.table.list

