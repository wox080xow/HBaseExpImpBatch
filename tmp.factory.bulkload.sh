function usage() {
   echo -e "Usage:  sh $0 factoryname"
   exit 1
}

function maketmpdir() {
  if [[ -d $* ]]
  then
  echo "directory $* for tmp files exists"
  else
  mkdir $*
  echo "directory $* for tmp files is created"
  fi
}

function banner() {
  echo ""
  echo "##################################################################################"
  echo "##"
  echo "## $*"
  echo "##"
  echo "##################################################################################"
  echo ""
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

# dir for tmp files
tmpdir="OMNI_TMP_FILES/"
maketmpdir $tmpdir

# factory
f=$1
tablelist="factory/"$f

# BULKLOAD TABLE
banner "START TABLE BULKLOAD"

while read t
do
  hdfsout="${tmpdir}hdfs-$t.out.tmp"
  bulkloadout="${tmpdir}bulkload-$t.out.tmp"

  hdfs dfs -du -h /tmp/bulkload/$t >$hdfsout

  phase "table $t"
  re="/.*/.*/[[:xdigit:]]{32}$"
  while read l
  do
    string=$l
    if [[ $string =~ $re ]]
    then
      path=${BASH_REMATCH[0]}
      echo "HFile: $path"
      echo "hbase org.apache.hadoop.hbase.mapreduce.LoadIncrementalHFiles $path $t"
      # hbase org.apache.hadoop.hbase.mapreduce.LoadIncrementalHFiles $path $t >$bulkloadout 2>&1
    fi
  done <$hdfsout
done <$tablelist

