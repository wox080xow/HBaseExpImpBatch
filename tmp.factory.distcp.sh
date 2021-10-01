function date_cvt(){
  string=$(echo $1|sed 's/\// /g;s/:/ /g')
  year=$(echo $string|cut -d' ' -f1)
  month=$(echo $string|cut -d' ' -f2)
  day=$(echo $string|cut -d' ' -f3)
  hour=$(echo $string|cut -d' ' -f4)
  minute=$(echo $string|cut -d' ' -f5)
  second=$(echo $string|cut -d' ' -f6)
  #echo $year $month $day $hour $minute $second
  date -d "$year$month$day $hour:$minute:$second" +%s
}

# variables
srchdfs="hdfs://172.16.1.66:8020"
#srcdir="/tmp"
srcdir="/apps/hbase/data/data/default/"
desthdfs="hdfs://172.16.1.57:8020"
destdir="/tmp"

# files
tmpdir="OMNI_TMP_FILES/"
factorylist=$tmpdir"factory.tmp"
velocitylist=$tmpdir"velocity.list.tmp"

while read t
do
  jobname=$t
  distcpout=$tmpdir"distcp-$t.out.tmp"
  echo "hadoop distcp -Dmapred.job.name=$jobname $srchdfs$srcdir$t $desthdfs$destdir >$distcpout 2>&1 &"
  hadoop distcp -Dmapred.job.name=$jobname $srchdfs$srcdir$t $desthdfs$destdir >$distcpout 2>&1 &
  # hadoop distcp -Dmapred.job.name=$jobname -Dmapred.job.queue.name=default $srchdfs$srcdir$t $desthdfs$destdir >$distcpout 2>&1 &
  echo SRC: $srchdfs$srcdir$t
  echo DST: $desthdfs$destdir
  wait

  forstarttime='mapreduce.JobSubmitter: Submitting tokens for job'
  forendtime='mapreduce.Job: Counters:'
  forsize='BYTESCOPIED'
  grep "$forstarttime" $distcpout|cut -d' ' -f1,2
  grep "$forendtime" $distcpout|cut -d' ' -f1,2
  grep $forsize $distcpout|cut -d'=' -f2
  starttime=$(grep "$forstarttime" $distcpout|cut -d' ' -f1,2)
  endtime=$(grep "$forendtime" $distcpout|cut -d' ' -f1,2)
  size=$(grep $forsize $distcpout|cut -d'=' -f2)
  if [[ -z $size ]]
  then
    size=0
  fi
  delta=$(($(date_cvt "$endtime")-$(date_cvt "$starttime")))
  #velocity=$(($(($size/$delta))/1024/1024)) # MB/s
  velocity=$(($size/$delta)) # Byte/s
  printf "%'d Byte/s\n" $velocity
  echo "$t,$size,$delta,$velocity" >>$velocitylist
done <$factorylist
