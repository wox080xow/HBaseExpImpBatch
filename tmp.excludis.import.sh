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

# files
disabletablelist="${tmpdir}disabletable.list-$1-$2.tmp" # hbase shell disable 'table' input
droptablelist="${tmpdir}droptable.list-$1-$2.tmp" # habase shell drop 'table' input
tabledisabledlist="${tmpdir}tabledisabled.out.list-$1-$2.tmp" # hbase shell disable 'talbe' output
tabledroppedlist="${tmpdir}tabledropped.out.list-$1-$2.tmp" # hbase shell drop 'table' output

desclistfilename="desc.list-$1-$2.tmp"
desclist="${tmpdir}$desclistfilename" # hbase shell desc 'table' output FROM HDP
desclistfile="/$desclistfilename"

tablelist="${tmpdir}table.list-$1-$2.tmp" # new line seperated tables
tabletobecreatedlist="${tmpdir}tabletobecreated.list-$1-$2.tmp" # new line seperated tmp tables
createtablelist="${tmpdir}createtable.list-$1-$2.tmp" # hbase shell create 'table','cf',... input
tablecreatedlist="${tmpdir}tablecreated.out.list-$1-$2.tmp" # hbase shell create 'table,'cf',... output

# DROP TEMP TABLES

# list of drop table line
disabletable=""
droptable=""

if [[ -f $tabletobecreatedlist ]]
then
  echo "$tabletobecreatedlist exists"
else
  touch $tabletobecreatedlist
  echo "$tabletobecreatedlist is touched"
fi

if [[ -f $disabletablelist ]] || [[ -f $droptablelist ]]
then
  rm -f $disabletablelist $droptablelist
  echo "remove tmp files $disabletablelist $droptablelist"
else
  touch $disabletablelist $droptablelist
  echo "$disabletablelist and $droptablelist are touched"
fi

while read t
do
  tableAd=$(echo $t|sed "s/^/\'/;s/$/\'/")
  disabletable="disable $tableAd"
  droptable="drop $tableAd"
  echo $disabletable >>$disabletablelist
  echo $droptable >>$droptablelist
done <$tabletobecreatedlist

# disable table through hbase shell
dtb=""
while read l
do
  dta=$l
  dtb=$dtb"\n"$dta
done <$disabletablelist

echo -e $dtb
echo -e $dtb|hbase shell -n >>$tabledisabledlist
echo "Tables above are disabled."

# drop table through hbase shell
dtb=""
while read l
do
  dta=$l
  dtb=$dtb"\n"$dta
done <$droptablelist

echo -e $dtb
echo -e $dtb|hbase shell -n >>$tabledroppedlist
echo "Tables above are dropped."


# CREATE TEMP TABLE

# list of create table line
createtable=""

# get $desclist from CDP hdfs
destdir="/tmp"
hdfs dfs -get -f $destdir$desclistfile $tmpdir

rm -f $tablelist $createtablelist $tabletobecreatedlist
echo "tmp files $tablelist $createtablelist $tabletobecreatedlist are removed"

# create $tablelist
while read l
do
  table="Table"
  disabledstring="DISABLED"
  # exclude disabled table
  if [[ $l =~ $table ]]
  then
    tableA=$(echo $l|cut -d' ' -f2)
    if [[ $l =~ $disabledstring ]]
    then
      echo "table $tableA is disabled"
    else
      echo $tableA >>$tablelist
    fi
  fi
done <$desclist


# create $createtablelist

while read l
do
  table="Table"
  cf="NAME =>"
  #echo $l
  #echo -e "\n*****createtable string:\n$createtable\n"

  # deal with table name
  if [[ $l =~ $table ]]
  then
    tableA=$(echo $l|cut -d' ' -f2)
    tableB="${tableA}_OMNI_TMP"
    tableC=$(echo $tableB|sed "s/^/\'/;s/$/\'/")
    #echo $tableA >>$tablelist
    echo $tableB >>$tabletobecreatedlist
    #echo $tableC
    #echo 'this is table'
    createtable="create $tableC"
    echo $createtable
    #echo -e "\n*****createtable string:\n$createtable\n"
  fi
  
  # deal with column family attribute
  if [[ $l =~ $cf ]]
  then
    #echo $l|sed 's/FOREVER/org.apache.hadoop.hbase.HConstants::FOREVER/'
    #echo $l|sed "s/ TTL => 'FOREVER',//"
    #echo 'this is column family'
    #createtable="$createtable, $(echo $l|sed 's/FOREVER/org.apache.hadoop.hbase.HConstants::FOREVER/')"
    createtable="$createtable, $(echo $l|sed "s/ TTL => 'FOREVER',//")"
    #echo -e "\n*****createtable string:\n$createtable\n"
  fi

  # output "hbase shell input" to file
  if [[ $l = "nil" ]]
  then
    if [[ $tableA =~ $(cat $tablelist) ]]
    then
      echo $createtable >>$createtablelist
      createtable=""
      #echo 'the end of desc'
    fi
  fi
done <$desclist

# create table through hbase shell
ctb=""
while read l
do
  cta=$l
  ctb=$ctb"\n"$cta
done <$createtablelist

echo -e $ctb|hbase shell -n >>$tablecreatedlist
echo "Tables above are created."

# IMPORT BATCH

# variables
starttime=$(date -d $1 +%s)000
endtime=$(date -d $2 +%s)000
#inputdirp="hdfs://isicdp.example.com:8020/tmp/"
inputdirp="/tmp/"

# files
checklist="${tmpdir}success.table.list-$1-$2.tmp" # new line seperated tables

banner "START TABLE IMPORT"
if [[ -f $checklist ]]
then
  echo "checklist exists"
else
  touch $checklist
  echo "checklist $checklist is touched"
fi

while read t
do
  # variables
  name="$t-$1-$2"
  inputdir="export-$name"
  tmpt=${t}_OMNI_TMP
  
  # files
  impout="${tmpdir}mr-imp-$inputdir.out.tmp" # mapreduce.Import output
  rcout="${tmpdir}mr-rc-$name.out.tmp" # mapreduce.RowCount ouput
  rclist="${tmpdir}rc.table.list-$1-$2.tmp" # new line seperated row count outcome, each line look like: table,100

  #echo $t
  #echo $tmpt

  # check if table import done
  success=$(grep -w $tmpt $checklist)
  #echo $success
  if [[ $success = $tmpt ]]
  then
    echo "table $tmpt is done, continue with next table"
    continue
  else  
    phase "START table $tmpt IMPORT"
  fi

  # import table
  filecheckstring="No such file or directory"
  filecheck=$(hdfs dfs -ls $inputdirp$inputdir)
  
  if [[ $filecheckstring =~ $filecheck ]]
  then
    echo "No $inputdirp$inputdir, $t Import failed..."
  else
    hbase org.apache.hadoop.hbase.mapreduce.Import $tmpt $inputdirp$inputdir >$impout 2>&1
    echo $impout

    # record table import successful
    checkstring="successfully"
    check=$(grep $checkstring $impout)
    if [[ $check =~ $checkstring ]]
    then
      echo $tmpt >> $checklist
      echo $tmpt $check
    else
      echo "$t Import failed..."
    fi
  fi

  # record table and row count
  hbase org.apache.hadoop.hbase.mapreduce.RowCounter $tmpt --starttime=$starttime --endtime=$endtime >$rcout 2>&1
  echo $rcout
  rowstring="ROWS="
  rows=$(grep $rowstring $rcout|sed 's/[[:space:]][[:space:]]*//'|cut -d'=' -f2)
  if [[ -z $rows ]]
  then
     rows=0
  fi
  phase "table $tmpt $rowstring$rows"
  echo "$tmpt,$rows" >>$rclist

done <$tablelist
