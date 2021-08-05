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
LIST=('SYSTEM.CATALOG' 'SYSTEM.FUNCTION' 'SYSTEM.SEQUENCE' 'SYSTEM.STATS')

# maketmpdir
tmpdir="OMNI_TMP_FILES/"
maketmpdir $tmpdir

# FILES
# for import batch
inputdirp="/tmp/"

# for $desclist
desclistfilename="systemtables.desc.list.tmp"
desclist="${tmpdir}$desclistfilename" # hbase shell desc 'table' output

# for get $desclist from cdp hdfs
destdir="/tmp/"

# for create table
createtablelist="${tmpdir}systemtables.createtable.list.tmp" # hbase shell create 'table','cf',... input
tablecreatedlist="${tmpdir}systemtables.tablecreated.out.list.tmp" # hbase shell create 'table,'cf',... output

# DESCLIST
hdfs dfs -get -f $destdir$desclistfilename $tmpdir
#a="hdfs dfs -get -f $destdir$desclistfilename $tmpdir"
#echo $a
echo "get $desclist $tmpdir$desclistfilename from cdp hdfs"

# CREATE TEMP TABLE
rm -f $createtablelist 
echo "remove tmp file $createtablelist"

while read l
do
  table="Table"
  cf="NAME =>"

  # deal with table name
  if [[ $l =~ $table ]]
  then
    tableA=$(echo $l|cut -d' ' -f2)
    tableB="${tableA}_SYSTEMTABLE_OMNI_TMP"
    tableC=$(echo $tableB|sed "s/^/\'/;s/$/\'/")
    createtable="create $tableC"
    #echo $createtable
    continue
  fi

  # deal with column family attribute
  if [[ $l =~ $cf ]]
  then
    createtable="$createtable, $(echo $l|sed "s/ TTL => 'FOREVER',//")"
    #echo $createtable
    continue
  fi

  # output "hbase shell input" to file
  if [[ $l = "nil" ]]
  then
    #echo $createtable
    echo $createtable >>$createtablelist
    createtable=""
  fi
done <$desclist

# create table through hbase shell
cat $createtablelist
ctb=""
while read l
do
  cta=$l
  ctb=$ctb"\n"$cta
done <$createtablelist

echo -e $ctb|hbase shell -n >>$tablecreatedlist
echo "Tables above are created."

# IMPORT

for val in ${LIST[@]}
do
  inputdir="export-$val"
  impout="${tmpdir}mr-imp-$inputdir.out.tmp"
  tmpt=${val}_SYSTEMTABLE_OMNI_TMP

  phase "START $tmpt IMPORT"
  hbase org.apache.hadoop.hbase.mapreduce.Import $tmpt $inputdirp$inputdir >$impout 2>&1
  #a="hbase org.apache.hadoop.hbase.mapreduce.Import $tmpt $inputdirp$inputdir >$impout 2>&1"
  #echo $a
  echo $impout
done

# MERGE
for val in ${LIST[@]}
do
  cpout="${tmpdir}mr-cp-$val.out.tmp"
  tmpt=${val}_SYSTEMTABLE_OMNI_TMP

  phase "START $val MERGE WITH $tmpt"
  hbase org.apache.hadoop.hbase.mapreduce.CopyTable --new.name=$val $tmpt >$cpout 2>&1
  #a="hbase org.apache.hadoop.hbase.mapreduce.CopyTable --new.name=$val $tmpt"
  #echo $a
  echo $cpout
done
