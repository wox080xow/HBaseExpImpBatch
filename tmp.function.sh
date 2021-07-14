function test() {
    echo $1 $2 $3
}

function testvar() {
    echo $arg1 $arg2 $arg3
}

# test apple pie good
# test $1 $2 $3
arg1=$1
arg2=$2
arg3=$3
# test $arg1 $arg2 $arg3
# test $arg3 $arg2 $arg1
# testvar $arg1 $arg2 $arg3
testvar