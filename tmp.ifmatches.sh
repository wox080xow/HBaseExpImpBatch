email=$1
file="/user/hive"
filecheck="Found 1 items drwxr-xr-x - hive hive 0 2021-07-07 04:28 /user/hive/.hiveJars"
#if [[ "$email" =~ "b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Za-z]{2,4}b" ]]
#if [[ "$email" =~ "@" ]]
#if [[ "@" =~ "$email" ]]
if [[ $filecheck =~ $file ]]
#if [[ $file =~ $filecheck ]]
then
  #echo "email format is correct"
  echo "file here"
else
  #echo "wrong format!"
  echo "no file"
fi
