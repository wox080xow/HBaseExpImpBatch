while read t
do 
  while read cf
  do 
    echo $t $cf
    cd ycsb-0.17.0;./bin/ycsb load hbase20 -cp /etc/hbase/conf -p table=$t -p columnfamily=$cf -p recordcount=1000 -p fieldcount=5 -p fieldlength=10 -p workload=site.ycsb.workloads.CoreWorkload -threads 2 -s;cd ~
  done <tmp.cf.list
done <tmp.table.list
