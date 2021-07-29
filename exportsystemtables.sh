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

function maketmpdir() {
  if [[ -d $* ]]
  then
  echo "directory $* for tmp files exists"
  else
  mkdir $*
  echo "directory $* for tmp files is created"
  fi
}

# VARIABLES

# for export batch
LIST=('SYSTEM.CATALOG' 'SYSTEM.FUNCTION' 'SYSTEM.SEQUENCE' 'SYSTEM.STATS')
srchdfs="hdfs://malvin-hdp-m1.example.com:8020"
#srchdfs="hdfs://pahdpfs:8020"
desthdfs="hdfs://malvin-cdp-m1.example.com:8020"
#desthdfs="hdfs://tnisilonh500:8020"
outputdirp="$desthdfs/tmp/"

# for $desclist
desclistfilename="systemtables.desc.list.tmp"
desclist="${tmpdir}$desclistfilename" # hbase shell desc 'table' output

# for send $desclist to cdp hdfs
srcdir="/tmp"
destdir="/tmp"

tmpdir="OMNI_TMP_FILES/"
maketmpdir $tmpdir

# DESCLIST
for val in ${LIST[@]}
do
  descseg="desc '$val'"
  descline=$descline"\n"$descseg
done

if [[ -f $desclist ]]
then
  echo "$desclist exists, remove old tmp file"
  rm -rf $desclist
fi

echo -e $descline|hbase shell -n >>$desclist
echo "$desclist is created."

hdfs dfs -put -f $desclist $outputdirp
echo "$desclist is sent to CDP at $outputdirp$desclistfilename"

# EXPORT

for val in ${LIST[@]}
do
  outputdir="export-$val"
  expout="${tmpdir}mr-$outputdir.out.tmp"
  
  phase "START $val EXPORT"
  #hbase org.apache.hadoop.hbase.mapreduce.Export -Dmapred.job.queue.name=Hive_EDC $val $outputdirp$outputdir >$expout 2>&1
  hbase org.apache.hadoop.hbase.mapreduce.Export $val $outputdirp$outputdir >$expout 2>&1
  echo $outputdirp$outputdir
  echo $expout
done
