tablelist="tmp/table.list.tmp"
while read l
do
  tempstring='TEMP\.'
  if [ 10 -gt 1 ]
  then
    if [[ $l =~ $tempstring ]]
    then
      echo "table $l is a temporary table from src"
      continue
    else
      echo "table $l is an regular table from src"
    fi
  fi
done <$tablelist
