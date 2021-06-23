t="tmp1"
string="ROWS"
rcout="rcout.tmp"
hbase org.apache.hadoop.hbase.mapreduce.RowCounter $t >$rcout 2>&1
rows=$(grep $string $rcout|sed 's/[[:space:]][[:space:]]*//'|cut -d'=' -f2)
echo "$t,$rows" >>rc.table.list.tmp
