file=$1
filecheckstring="No such file or directory"
filecheck=$(hdfs dfs -ls $file)

#if [[ $filecheck =~ $filecheckstring ]]
if [[ $filecheckstring =~ $filecheck ]]
then
  #echo $filecheck
  echo "No file on hdfs"
else
  echo $filecheck
  echo "File here"
fi
