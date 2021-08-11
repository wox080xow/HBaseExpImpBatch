function usage() {
   echo -e "Usage:  sh $0 starttime endtime\n\te.g.\n\tsh $0 210601 210630"
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

if [[ -z $2 ]]
then
  usage
  exit 1
fi

# dir for tmp files
tmpdir="OMNI_TMP_FILES/"
maketmpdir $tmpdir

# variables
starttime=$(date -d $1 +%s)000
endtime=$(date -d $2 +%s)000

# tablelist="tmp/tablelist.tmp"
tablelist="${tmpdir}table.list-$1-$2.tmp" # tablelist generated from import.sh
rclistI="${tmpdir}import.rc.table.list-$1-$2.tmp" # rclist generated from import.sh

flushtablelist="${tmpdir}flushtable.list-$1-$2.tmp" # habase shell drop 'table' input
tableflushedlist="${tmpdir}tableflushed.out.list-$1-$2.tmp" # hbase shell disable 'talbe' output

# COPY TMP TABLE HFILE
srcdir="/hbase/data/default/" # for CDP
# srcdir="/apps/hbase/data/data/default/" # for HDP
destdir="/tmp/bulkload/"

# FLUSH TABLE
phase "FLUSH TABLE"
while read t
do
  tableAf=$(echo $t|sed "s/^/\'/;s/$/\'/")
  flushtable="flush $tableAf"
  echo $flushtable >>$flushtablelist
done <$tablelist

# flush table through hbase shell
ftb=""
while read l
do
  fta=$l
  ftb=$ftb"\n"$fta
done <$flushtablelist

echo -e $ftb
echo -e $ftb|hbase shell -n >>$tableflushedlist
echo "Tables above are flushed."

# COPY HFILE
banner "COPY HFILE"
while read t
do
  tmpt="${t}_OMNI_TMP"
  srchfile="$srcdir$tmpt"
  # srchfile="$srcdir$t"
  # echo "hdfs dfs -rm -r $destdir$tmpt"
  # hdfs dfs -rm -r $destdir$tmpt
  echo "hdfs dfs -cp -f $srchfile $destdir"
  hdfs dfs -cp -f $srchfile $destdir 
done <$tablelist


# BULKLOAD TABLE
banner "START TABLE BULKLOAD"

while read t
do
  tmpt="${t}_OMNI_TMP"
  hdfsout="${tmpdir}hdfs-$t-$1-$2.out.tmp"
  bulkloadout="${tmpdir}bulkload-$t-$1-$2.out.tmp"
  
  # hdfs dfs -du -h /tmp/bulkload/$t | grep -P "[[:xdigit:]]{32}$" | tr [:space:] ',' | sed 's/,,./,/g' | cut -d ',' -f 3 >$hdfsout
  hdfs dfs -du -h /tmp/bulkload/$tmpt >$hdfsout
  
  phase "table $t"
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
      hbase org.apache.hadoop.hbase.mapreduce.LoadIncrementalHFiles $path $t >$bulkloadout 2>&1
    fi
  done <$hdfsout

done <$tablelist

# ROWCOUNT TABLE
while read t
do
  # files
  rcout="${tmpdir}bulkload.mr-rc-$t-$1-$2.out.tmp" # mapreduce.RowCount ouput
  rclist="${tmpdir}bulkload.rc.table.list-$1-$2.tmp" # new line seperated row count outcome, each line look like: table,100

  # record table and row count
  hbase org.apache.hadoop.hbase.mapreduce.RowCounter $t --starttime=$starttime --endtime=$endtime >$rcout 2>&1
  rowstring="ROWS="
  rows=$(grep $rowstring $rcout|sed 's/[[:space:]][[:space:]]*//'|cut -d'=' -f2)
  if [[ -z $rows ]]
  then
     rows=0
  fi
  phase "table $t $rowstring$rows"
  echo "$t,$rows" >>$rclist
done <$tablelist
