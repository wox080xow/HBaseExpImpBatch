re="http://([^/]+)/"
name="http://google.com/"
if [[ $name =~ $re ]]
then
  echo ${BASH_REMATCH[1]}
fi
