tablelistE="OMNI_TMP_FILES/exist.table.list.tmp"

#desclist="desc.list.tmp.target"
desclist="OMNI_TMP_FILES/desc.list-210501-210701.tmp"
tabletobealteredlist="tablatobealtered.list.tmp"
altertablelist="altertable.list.tmp"

tableA=""
while read l
do
  table="Table"
  schema=$tableA
  #echo "**********"
  #echo $l
  #echo "**********"
  #echo -e "\n*****altertable string:\n$altertable\n"
  if [[ $l =~ $table ]]
  then
    tableA=$(echo $l|cut -d' ' -f2)

    # differ system table and tmp table
    if [[ $tableA =~ "SYSTEM" ]]
    then
      echo "table $tableA is PHOENIX system talbe"
      continue
    elif [[ $tableA =~ "OMNI_TMP" ]]
    then
      echo "table $tableA is tmp table"
      continue
    fi

    tableC=$(echo $tableA|sed "s/^/\'/;s/$/\'/")
    echo $tableA >>$tabletobealteredlist
    echo $tableC
    echo '^^^this is table^^^'
    altertable="alter $tableC"
    #echo -e "\n*****altertable string:\n$altertable\n"
    continue
  fi
  if [[ $l =~ $schema ]]
  then
    schemaA=$(echo $l|sed -e "s/$tableA, {TABLE_ATTRIBUTES => {//;s/}$//;s/coprocessor\$[0-9]/'&'/g;s/METADATA/'&'/")
    altertable="$altertable, $schemaA"
    if [[ $schemaA =~ "coprocessor" ]] && [[ $altertable =~ $schema ]]
    then
      echo $schemaA
      echo "^^^this is schema^^^"
      altertable="$altertable, $schemaA"
      #echo -e "\n*****altertable string:\n$altertable\n"
    else
      altertable=""
    fi
    continue
  fi

  if [[ $l = "nil" ]]
  then
    echo $altertable >>$altertablelist
    altertable=""
    #echo 'the end of desc'
  fi
done <$desclist
