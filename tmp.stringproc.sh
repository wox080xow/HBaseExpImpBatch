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
    echo $l|cut -d' ' -f2|sed "s/^/\'/;s/$/\'/"
    echo 'this is table'
    createtable="create $(echo $l|cut -d' ' -f2|sed "s/^/\'/;s/$/\'/")"
    echo -e "\n*****createtable string:\n$createtable\n"
  fi
  if [[ $l =~ $cf ]]
  then
    #echo $l|sed 's/FOREVER/org.apache.hadoop.hbase.HConstants::FOREVER/'
    echo $l|sed "s/ TTL => 'FOREVER',//"
    echo 'this is column family'
    createtable="$createtable, $(echo $l|sed "s/ TTL => 'FOREVER',//")"
    echo -e "\n*****createtable string:\n$createtable\n"
  fi
  if [[ $l = "nil" ]]
  then
    echo $createtable >>createtable.list.tmp
    createtable=""
    echo 'the end of desc'
  fi
done <desc.list.tmp
