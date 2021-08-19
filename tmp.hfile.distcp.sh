function usage() {
   echo -e "Usage:  sh $0 tablename\n\te.g.\n\tsh $0 TestTable"
   exit 1
}

function phase() {
  echo ""
  echo "*****$******"
}

if [[ -z $1 ]]
then
  usage
  exit 1
fi

# variables
srchdfs="hdfs://172.16.1.66:8020"
# srchdfs="hdfs://pahdpfs:8020"
srcdir="/apps/hbase/data/data/default/"
desthdfs="hdfs://172.16.1.57:8020"
# desthdfs="hdfs://tnisilonh500"
destdir="/tmp/bulkload/"

# tmpdir
tmpdir="OMNI_TMP_FILES/"
# table
t=$1

hdfsout="${tmpdir}hdfs-$t.out.tmp"
distcpout="${tmpdir}distcp-$t.out.tmp"

hdfs dfs -du -h $srcdir$t >$hdfsout
hdfs dfs -mkdir $desthdfs$destdir$t
# re="(\/[a-zA-Z0-9_-]+)+$"
re="[[:xdigit:]]{32}$"
while read l
do
    string=$l
    if [[ $string =~ $re ]]
    then
        path=${BASH_REMATCH[0]}
        distcpout="${tmpdir}distcp-$t-$path.out.tmp"
        # echo $path
        phase TABLE $t REGION $path
        echo src: $srchdfs$srcdir$t/$path
        echo dest: $desthdfs$destdir$t/
        echo out: $distcpout
        hadoop distcp $srchdfs$srcdir$t/$path $desthdfs$destdir$t/ >$distcpout 2>&1
    fi
done <$hdfsout
