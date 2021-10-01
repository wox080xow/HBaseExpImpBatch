function date_cvt(){
  string=$(echo $1|sed 's/\// /g;s/:/ /g')
  year=$(echo $string|cut -d' ' -f1)
  month=$(echo $string|cut -d' ' -f2)
  day=$(echo $string|cut -d' ' -f3)
  hour=$(echo $string|cut -d' ' -f4)
  minute=$(echo $string|cut -d' ' -f5)
  second=$(echo $string|cut -d' ' -f6)
  #echo $year $month $day $hour $minute $second
  date -d "$year$month$day $hour:$minute:$second" +%s
}

distcpout=$1
forstarttime='mapreduce.JobSubmitter: Submitting tokens for job'
forendtime='mapreduce.Job: Counters:'
forsize='BYTESCOPIED'
grep "$forstarttime" $distcpout|cut -d' ' -f1,2
grep "$forendtime" $distcpout|cut -d' ' -f1,2
grep $forsize $distcpout|cut -d'=' -f2
starttime=$(grep "$forstarttime" $distcpout|cut -d' ' -f1,2)
endtime=$(grep "$forendtime" $distcpout|cut -d' ' -f1,2)
size=$(grep $forsize $distcpout|cut -d'=' -f2)
delta=$(($(date_cvt "$endtime")-$(date_cvt "$starttime")))
echo $delta
#velocity=$(($(($size/$delta))/1024/1024)) # MB/s
velocity=$(($size/$delta)) # Byte/s
printf "%'d Byte/s\n" $velocity
