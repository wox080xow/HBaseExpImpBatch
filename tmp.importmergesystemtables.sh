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

# for import batch
LIST=('SYSTEM.CATALOG' 'SYSTEM.FUNCTION' 'SYSTEM.SEQUENCE' 'SYSTEM.STATS')
inputdirp="/tmp/"

# for $desclist
desclistfilename="systemtables.desc.list.tmp"
desclist="${tmpdir}$desclistfilename" # hbase shell desc 'table' output

# for get $desclist from cdp hdfs
destdir="/tmp/"

# for create table
createtablelist="${tmpdir}createtable.list-$1-$2.tmp" # hbase shell create 'table','cf',... input
tablecreatedlist="${tmpdir}tablecreated.out.list-$1-$2.tmp" # hbase shell create 'table,'cf',... output

tmpdir="OMNI_TMP_FILES/"
maketmpdir $tmpdir

# DESCLIST
hdfs dfs -get -f $destdir$desclistfilename $tmpdir

# CREATE TEMP TABLE
while read l
do
  table="Table"
  cf="NAME =>"

  # deal with table name
  if [[ $l =~ $table ]]
  then
    tableA=$(echo $l|cut -d' ' -f2)
    tableB="${tableA}_OMNI_TMP"
    tableC=$(echo $tableB|sed "s/^/\'/;s/$/\'/")
    echo $tableB >>$tabletobecreatedlist
    createtable="create $tableC"
    # echo $createtable
    continue
  fi

  # deal with column family attribute
  if [[ $l =~ $cf ]]
  then
    createtable="$createtable, $(echo $l|sed "s/ TTL => 'FOREVER',//")"
    continue
  fi

  # output "hbase shell input" to file
  if [[ $l = "nil" ]]
  then
    if [[ $(cat $tablelist) =~ $tableA ]]
    then
      echo $createtable >>$createtablelist
      createtable=""
    fi
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
  tmpt=$val_SYSTEMTABLE_OMNI_TEMP

  echo "START $tmpt IMPORT"
  #hbase org.apache.hadoop.hbase.mapreduce.Import $tmpt $inputdirp$inputdir >$impout 2>&1
  a="hbase org.apache.hadoop.hbase.mapreduce.Import $tmpt $inputdirp$inputdir >$impout 2>&1"
  echo $a
  echo $impout
done

# MERGE
for val in ${LIST[@]}
do
  cpout="${tmpdir}mr-cp-$tmpt.out.tmp"
  tmpt=$val_SYSTEMTABLE_OMNI_TEMP
  echo "START $val MERGE WITH $tmpt"
  #hbase org.apache.hadoop.hbase.mapreduce.CopyTable --new.name=$val $tmpt
  a="hbase org.apache.hadoop.hbase.mapreduce.CopyTable --new.name=$val $tmpt"
  echo $a
  echo $cpout
done
