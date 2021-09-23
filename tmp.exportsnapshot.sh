tmpdir="OMNI_TMP_FILES/"

# files
tablelisttarget=$tmpdir"table.list.tmp.target"

dest='hdfs://172.16.1.57:8020/hbase'
ymd='210923'
while read t
do
  snapshot="${t}_SS_$ymd"
  esout="${tmpdir}mr-exportsnapshot-$snapshot.out.tmp"
  sudo -u hdfs hbase org.apache.hadoop.hbase.snapshot.ExportSnapshot -snapshot $snapshot -copy-to $dest >$esout 2>&1
  echo esout: $esout
done <$tablelisttarget