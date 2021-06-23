file="mr-export-tmp3-210601-210630.out.tmp"
string="successfully"
check=$(grep $string $file)
echo $check
if [[ $check =~ $string ]]
then
  echo yes >>ifelse.check.tmp
fi
