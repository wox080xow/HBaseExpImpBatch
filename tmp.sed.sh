tableB="yes_OMNI_TMP"
tableC=$(echo $tableB|sed "s/^/\'/;s/$/\'/")
echo $tableC
echo 'this is table'
