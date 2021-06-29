# dir for tmp files
tmpdir="OMNI_TMP_FILES/"
if [[ -d $tmpdir ]]
then
  echo "directory $tmpdir for tmp files is exist"
else
  mkdir $tmpdir
  echo "directory $tmpdir for tmp files is created"
fi

# files
tablelist="${tmpdir}table.list.tmp" new line seperated tables

# MERGE TABLE BATCH

# variables
starttime=$(date -d $1 +%s)
endtime=$(date -d $2 +%s)

while read t
do 
  # variables
  tmpt="${t}_OMNI_TMP

  # files
  cpout="${tmpdir}mr-cp-$tmpt.out.tmp" # mapreduce.CopyTable output
  rcout="${tmpdir}mr-rc-$t-$sarttime-$endtime.out.tmp" # mapreduce.RowCount ouput
  checklist="${tmpdir}success.table.list.tmp" # new line seperated tables
  rclist="${tmpdir}rc.table.list.tmp" # new line seperated row count outcome, each line look like: table,100

  # check if table import done
  echo "START table $tmpt IMPORT"
  if [ -f success.table.list.tmp ]
  then
    echo "checklist exists"
  else
    touch $checklist
    echo "checklist $checklist is touched"
  fi
  success=$(grep -w $tmpt $checklist)
  echo $success
  if [[ $success = $tmpt ]]
  then
    echo "table $tmpt is done, continue with next table"
    continue
  fi

  hbase org.apache.hadoop.hbase.mapreduce.CopyTable --new.name=$t $tmpt >$cpout 2>&1
  echo $cpout
  echo $rcout
  
  # record table import successful
  checkstring="successfully"
  check=$(grep $string $impout)
  echo $check
  if [[ $check =~ $checkstring ]]
  then
    echo $tmpt >> $checklist
  fi

  # record table and row count
  hbase org.apache.hadoop.hbase.mapreduce.RowCounter $tmpt --starttime=$starttime --endtime=$endtime >$rcout 2>&1
  rowstring="ROWS"
  rows=$(grep $rowstring $rcout|sed 's/[[:space:]][[:space:]]*//'|cut -d'=' -f2)
  echo $rows
  echo "$tmpt,$rows" >>$rclist

done <$tablelist
