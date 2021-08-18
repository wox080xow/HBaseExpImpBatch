function usage() {
   echo -e "Usage:  sh $0"
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

# dir for tmp files
tmpdir="OMNI_TMP_FILES/"
maketmpdir $tmpdir

# variables
#starttime=$(date -d $1 +%s)000
#endtime=$(date -d $2 +%s)000

# tablelist="tmp/tablelist.tmp"
tablelist="${tmpdir}table.list.tmp" # tablelist

flushtablelist="${tmpdir}flushtable.list.tmp" # habase shell flush 'table' input
tableflushedlist="${tmpdir}tableflushed.out.list.tmp" # hbase shell flush 'talbe' output

# COPY TMP TABLE HFILE
srcdir="/hbase/data/default/" # for CDP
# srcdir="/apps/hbase/data/data/default/" # for HDP
destdir="/tmp/bulkload/"

# BULKLOAD TABLE
banner "START TABLE BULKLOAD"

while read t
do
  tmpt="${t}_OMNI_TMP"
  hdfsout="${tmpdir}hdfs-$t.out.tmp"
  bulkloadout="${tmpdir}bulkload-$t.out.tmp"
  
  # hdfs dfs -du -h /tmp/bulkload/$t | grep -P "[[:xdigit:]]{32}$" | tr [:space:] ',' | sed 's/,,./,/g' | cut -d ',' -f 3 >$hdfsout
  hdfs dfs -du -h /tmp/bulkload/$tmpt >$hdfsout
  
  phase "table $t"
  
  # enable table before bulkloading
  echo 'enable "$t"'|hbase shell -n

  # re="(\/[a-zA-Z0-9_-]+)+$"
  re="/.*/.*/[[:xdigit:]]{32}$"
  while read l
  do
    string=$l
    if [[ $string =~ $re ]]
    then
      path=${BASH_REMATCH[0]}
      # echo $path
      echo "hbase org.apache.hadoop.hbase.mapreduce.LoadIncrementalHFiles $path $t"
      hbase org.apache.hadoop.hbase.mapreduce.LoadIncrementalHFiles $path $t >>$bulkloadout 2>&1
    fi
  done <$hdfsout

  # disable table after bulkloading
  echo 'disable "$t"'|hbase shell -n

done <$tablelist

