function fatal() {
   echo "FATAL:  $*"
   exit 1
}

if [[ -z $1 ]]
then
  fatal "arg 1 loss"
fi

echo "great job! you imput arg 1: $1"
