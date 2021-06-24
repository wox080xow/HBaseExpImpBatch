createtable=""
while read l
do
  table="Table"
  #cf="{NAME"
  cf="NAME =>"
  #echo $l
  #echo -e "\n*****createtable string:\n$createtable\n"
  if [[ $l =~ $table ]]
  then
    echo $l|cut -d' ' -f2
    echo 'this is table'
    createtable="create $(echo $l|cut -d' ' -f2)"
    echo -e "\n*****createtable string:\n$createtable\n"
  fi
  if [[ $l =~ $cf ]]
  then
    echo $l|sed 's/FOREVER/org.apache.hadoop.hbase.HConstants::FOREVER/'
    echo 'this is column family'
    createtable="$createtable, $(echo $l|sed 's/FOREVER/org.apache.hadoop.hbase.HConstants::FOREVER/')"
    echo -e "\n*****createtable string:\n$createtable\n"
  fi
  if [[ $l = "nil" ]]
  then
    createtable=""
    echo 'the end of desc'
  fi
done <desc.list.tmp
