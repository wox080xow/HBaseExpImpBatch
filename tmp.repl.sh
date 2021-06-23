while read t
do
  echo "desc '$t'"|hbase shell -n|grep -e '^\{.*\}$'|sed -e 's/{//; s/}//'|awk -F, '{print $1}'|awk '{print $3}'|sed -e "s/'//g" >tmp.cf.list
  while read cf
  do
    echo "$t $cf"
    echo alter "'$t', {NAME => '$cf', REPLICATION_SCOPE => '1'}"|hbase shell -n
  done < tmp.cf.list
done <tmp.table.list
rm -rf tmp.cf.list
