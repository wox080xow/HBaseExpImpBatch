altertablelist=OMNI_TMP_FILES/alter.table.list.tmp
tablealteredlist=OMNI_TMP_FILES/table.altered.list.out.tmp

tablelist=factory/$1

rm -f $altertablelist
while read t
do
  echo "alter '$t', 'coprocessor\$1' => '|org.apache.phoenix.coprocessor.ScanRegionObserver|805306366|', 'coprocessor\$2' => '|org.apache.phoenix.coprocessor.UngroupedAggregateRegionObserver|805306366|', 'coprocessor\$3' => '|org.apache.phoenix.coprocessor.GroupedAggregateRegionObserver|805306366|', 'coprocessor\$4' => '|org.apache.phoenix.coprocessor.ServerCachingEndpointImpl|805306366|', 'coprocessor\$5' => '|org.apache.phoenix.hbase.index.Indexer|805306366|org.apache.hadoop.hbase.index.codec.class=org.apache.phoenix.index.PhoenixIndexCodec,index.builder=org.apache.phoenix.index.PhoenixIndexBuilder', 'coprocessor\$6' => '|org.apache.hadoop.hbase.regionserver.IndexHalfStoreFileReaderGenerator|805306366|', 'METADATA' => {'DATA_TABLE_NAME' => '$t', 'SPLIT_POLICY' => 'org.apache.phoenix.hbase.index.IndexRegionSplitPolicy'}" >>$altertablelist
done <$tablelist

# alter table through hbase shell
cat $altertablelist
atb=""
while read l
do
  ata=$l
  atb=$atb"\n"$ata
done <$altertablelist

#echo $atb
echo -e $atb|hbase shell -n #>>$tablealteredlist
