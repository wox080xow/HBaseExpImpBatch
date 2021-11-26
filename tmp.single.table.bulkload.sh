function usage() {
   echo -e "Usage:  sh $0 tablename"
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

t=$1

# COPY TMP TABLE HFILE
#srcdir="/hbase/data/default/" # for CDP
# srcdir="/apps/hbase/data/data/default/" # for HDP
#destdir="/tmp/bulkload/"

#banner "COPY HFILE"
# tmpt="${t}_OMNI_TMP"
# srchfile="$srcdir$tmpt"
#srchfile="$srcdir$t"
#hdfs dfs -cp $srchfile $destdir

# BULKLOAD TABLE
banner "START TABLE BULKLOAD"

# tmpt="${t}_OMNI_TMP"
hdfsout="${tmpdir}hdfs-$t.out.tmp"

# hdfs dfs -du -h /tmp/bulkload/$t | grep -P "[[:xdigit:]]{32}$" | tr [:space:] ',' | sed 's/,,./,/g' | cut -d ',' -f 3 >$hdfsout
hdfs dfs -du -h /tmp/bulkload/$t >$hdfsout
  
phase "table $t"
# re="(\/[a-zA-Z0-9_-]+)+$"
re="/.*/.*/[[:xdigit:]]{32}$"
while read l
do
  string=$l
  if [[ $string =~ $re ]]
  then
    path=${BASH_REMATCH[0]}
    r=$(echo $path|cut -d'/' -f3)
    bulkloadout="${tmpdir}bulkload-$t-$r.out.tmp"
    echo "Region: $path"
    echo "hbase org.apache.hadoop.hbase.mapreduce.LoadIncrementalHFiles $path $t"
    hbase org.apache.hadoop.hbase.mapreduce.LoadIncrementalHFiles $path $t >$bulkloadout 2>&1
    echo "bulkloadout: $bulkloadout"
    cat $bulkloadout|grep "Trying to load hfile"|cut -d' ' -f1,2,10
  fi
done <$hdfsout

