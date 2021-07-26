file="tmp/x"
newfile="tmp/x.tmp"

if [ -f $newfile ]
then
  rm -f $newfile
  touch $newfile
else
  touch $newfile
fi

while read l
do
  echo -e "\n"
  partA=$(echo $l|cut -d',' -f1)
  partAold=$(grep $partA $newfile|cut -d',' -f1)
  partB=$(echo $l|cut -d',' -f2)
  partBold=$(grep $partA $newfile|cut -d',' -f2)
  echo readline $partA $partB
  echo oldrecord $partAold $partBold
  if [[ -z $partAold ]]
  then
    echo "no record of $partA"
    echo $l >>$newfile
  else
    echo "there is a record of $partA"
    if [[ $partB -gt $partBold ]]
    then
      sed -i "s/$partA,$partBold/$partA,$partB/" $newfile
      echo "update $partA Row Count"
    fi
  fi
done <$file
