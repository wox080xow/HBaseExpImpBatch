srcdir="/hbase/data/default/" # for CDP
# scrdir="/apps/hbase/data/data/default/" # for HDP
destdir="/tmp/bulkload/"
tablelist="tmp/tablelist.hdfscp.tmp"

cat $tablelist

while read t
do
  tmpt="${t}_OMNI_TMP"
  srchfile="$srcdir$tmpt"
  echo $srchfile $destdir
  hdfs dfs -cp -f $srchfile $destdir
done <$tablelist