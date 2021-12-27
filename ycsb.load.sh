tablelist=$1
pwdnow=`pwd`'/'
echo pwdnow: $pwdnow
tmpdir='OMNI_TMP_FILES/'

while read t
do
  ycsboutput=$pwdnow$tmpdir"ycsb-$t-load.out"
  echo $t ycsb loading data...
  echo log: $ycsboutput
  table=$t
  cf='cf'
  #table='"'$t'"' # alphanumeric only
  #table=$(echo $t|sed 's/\./:/') # table does not exist
  echo table: $table

  cd ~/ycsb-0.17.0/
  ./bin/ycsb load hbase20 -p table=$table -p columnfamily=$cf -p recordcount=100 -p fieldcount=1 -p fieldlength=10 -p workload=site.ycsb.workloads.CoreWorkload -threads 2 -s >$ycsboutput 2>&1 &
  wait
  cd $pwdnow
done <$tablelist
