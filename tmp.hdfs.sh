file=$1
filecheckstring="No such file or directory"
filecheck=$(hdfs dfs -ls $file)

#if [[ $filecheck =~ $filecheckstring ]]
#if [[ $filecheckstring =~ $filecheck ]]
if [[ $file =~ $filecheck ]]
#if [[ $filecheck =~ $file ]] # why this one work incorrectly???
then
  echo $file
  echo $filecheck
  echo $filecheck|grep $file
  echo "No file on hdfs"
else
  echo $file
  echo $filecheck
  echo $filecheck|grep $file
  echo "File here"
fi
