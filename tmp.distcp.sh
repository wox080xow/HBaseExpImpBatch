# variables
srchdfs="hdfs://172.16.1.66:8020"
srcdir="/tmp"
desthdfs="hdfs://172.16.1.57:8020"
destdir="/tmp"

# files
desclist="tmp/y"
desclistfile="/y"

hdfs dfs -put $desclist $srcdir
echo $desclist $srcdir
hadoop distcp $srchdfs$srcdir$desclistfile $desthdfs$destdir
echo $srchdfs$srcdir$desclistfile $desthdfs$destdir
