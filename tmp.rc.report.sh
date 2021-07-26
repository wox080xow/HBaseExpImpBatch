# tmpdir="OMNI_TMP_FILES/"
tmpdir="tmp/"
# exportrclist="${tmpdir}export.rc.table.list-$1-$2.tmp"
# importlist="${tmpdir}import.rc.table.list-$1-$2.tmp"
# mergerclist="${tmpdir}merge.rc.table.list-$1-$2.tmp"
exportrclist="${tmpdir}x"
importrclist="${tmpdir}y"
mergerclist="${tmpdir}z"
exportrclisttmp="$exportrclist.tmp"
importrclisttmp="$importrclist.tmp"
mergerclisttmp="$mergerclist.tmp"
exportrclisttmptmp="$exportrclisttmp.tmp"
importrclisttmptmp="$importrclisttmp.tmp"
mergerclisttmptmp="$mergerclisttmp.tmp"

function cleaning() {
    file="$*"
    newfile="$*.tmp"

    if [ -f $newfile ]
    then
      rm -f $newfile
      touch $newfile
    else
      touch $newfile
    fi

    while read l
    do
      #echo -e "\n"
      partA=$(echo $l|cut -d',' -f1)
      partAold=$(grep $partA $newfile|cut -d',' -f1)
      partB=$(echo $l|cut -d',' -f2)
      #if [[ "matches" =~ $partB ]]
      if [[ $partB =~ "Binary file" ]]
      then
        partB=0
      else
        partB=$partB
      fi
      partBold=$(grep $partA $newfile|cut -d',' -f2)
      #echo read line $partA $partB
      #echo old record $partAold $partBold
      if [[ -z $partAold ]]
      then
        #echo "no record of $partA"
        echo $partA,$partB >>$newfile
      else
        #echo "there is a record of $partA"
        if [[ $partB -gt $partBold ]]
        then
          sed -i "s/$partA,$partBold/$partA,$partB/" $newfile
          #echo "update $partA Row Count"
        fi
      fi
    done <$file
}

function processing() {
    cat $* | sort | uniq >$*.tmp
}

cleaning $exportrclist
cleaning $importrclist
cleaning $mergerclist
processing $exportrclisttmp
processing $importrclisttmp
processing $mergerclisttmp

echo IMPORT incomplete tables:
diff $exportrclisttmptmp $importrclisttmptmp
echo MERGE incomplet tables:
diff $exportrclisttmptmp $mergerclisttmptmp
