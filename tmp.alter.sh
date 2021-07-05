tablelistE="OMNI_TMP_FILES/exist.table.list.tmp"
while read t
do
  if [[ $t =~ "SYSTEM" ]]
  then
    echo "table $t is PHOENIX system talbe"
  elif [[ $t =~ "OMNI_TMP" ]]
  then
    echo "table $t is tmp table"
  else
    echo "alter '$t', 'coprocessor$1' => '|org.apache.phoenix.coprocessor.ScanRegionObserver|805306366|', 'coprocessor$2' => '|org.apache.phoenix.coprocessor.UngroupedAggregateRegionObserver|805306366|', 'coprocessor$3' => '|org.apache.phoenix.coprocessor.GroupedAggregateRegionObserver|805306366|', 'coprocessor$4' => '|org.apache.phoenix.coprocessor.ServerCachingEndpointImpl|805306366|', 'coprocessor$5' => '|org.apache.phoenix.hbase.index.IndexRegionObserver|805306366|index.builder=org.apache.phoenix.index.PhoenixIndexBuilder,org.apache.hadoop.hbase.index.codec.class=org.apache.phoenix.index.PhoenixIndexCodec', 'coprocessor$6' => '|org.apache.phoenix.coprocessor.PhoenixTTLRegionObserver|805306364|'" #>>$altertablelist
  fi
done <$tablelistE
