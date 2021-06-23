while read t
do 
  hbase org.apache.hadoop.hbase.mapreduce.Import $t /tmp/export-$t
done < tmp.table.list
