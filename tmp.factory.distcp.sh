# variables
srchdfs="hdfs://172.16.1.66:8020"
#srcdir="/tmp"
srcdir="/user/root/data/teragen/"
desthdfs="hdfs://172.16.1.57:8020"
destdir="/tmp"

# files
factorylist=$1

while read t
do
  jobname=$t
  #echo "hadoop distcp -Dmapred.job.name=$jobname $srchdfs$srcdir$t $desthdfs$destdir"
  hadoop distcp -Dmapred.job.name=$jobname $srchdfs$srcdir$t $desthdfs$destdir
  echo $srchdfs$srcdir$t $desthdfs$destdir
done <$factorylist
