#re="(\/[\w-]+)+$"
re="(\/[a-zA-Z0-9_-]+)+$"
string="43   43   /tmp/bulkload/TMP1_IMP-1/6f6c8f05cbd241294c0d97a10558d0fe"

#re="[a-z]+" # for test
#string="abc" # for test

if [[ $string =~ $re ]]
then
  echo ${BASH_REMATCH[0]}
fi

# echo 'echo $string|grep -P $re'
# echo $string|grep -P $re
# echo -e '\n'
# echo 'grep -P [[:xdigit:]]{32} hdfs.out'
# grep -P [[:xdigit:]]{32} hdfs.out
# echo -e '\n'
# echo 'hdfs dfs -du -h /tmp/bulkload/TMP1_IMP-1 | grep -P [[:xdigit:]]{32} | sed 's/[[:space:]][[:space:]]./ /g'|cut -d' ' -f3'
# hdfs dfs -du -h /tmp/bulkload/TMP1_IMP-1 | grep -P [[:xdigit:]]{32} | sed 's/[[:space:]][[:space:]]./ /g'|cut -d' ' -f3
