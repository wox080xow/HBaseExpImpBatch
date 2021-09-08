function usage() {
   echo -e "Usage:  sh $0 tablename\n\te.g.\n\tsh $0 TestTable"
   exit 1
}

function phase() {
  echo ""
  echo "*****$******"
}

if [[ -z $1 ]]
then
  usage
  exit 1
fi

# variables
srchdfs="hdfs://172.16.1.66:8020"
# srchdfs="hdfs://pahdpfs:8020"
srcdir="/apps/hbase/data/data/default/"
desthdfs="hdfs://172.16.1.57:8020"
# desthdfs="hdfs://tnisilonh500"
destdir="/tmp/bulkload/"

# tmpdir
tmpdir="OMNI_TMP_FILES/"
# table
t=$1

hdfsout="${tmpdir}hdfs-$t.out.tmp"
distcpout="${tmpdir}distcp-$t.out.tmp"

hdfs dfs -du -h $srcdir$t >$hdfsout
hdfs dfs -mkdir $desthdfs$destdir$t
# re="(\/[a-zA-Z0-9_-]+)+$"
re="[[:xdigit:]]{32}$"
while read l
do
    string=$l
    if [[ $string =~ $re ]]
    then
        region=${BASH_REMATCH[0]}
        # distcpout="${tmpdir}distcp-$t-$region.out.tmp"
        hdfsout2="${tmpdir}hdfs-$t-$region.out.tmp"
        # echo $region
        # phase TABLE $t REGION $region
        # echo src: $srchdfs$srcdir$t/$region
        # echo dest: $desthdfs$destdir$t/
        # echo out: $distcpout
        # hadoop distcp $srchdfs$srcdir$t/$region $desthdfs$destdir$t/ >$distcpout 2>&1 &
        hdfs dfs -du -h $srchdfs$srcdir$t/$region >$hdfsout2
        hdfs dfs -mkdir $desthdfs$destdir$t/$region
        while read l
        do
            string=$l
            if [[ $string =~ "recovered.edits" ]] || [[ $string =~ ".tmp" ]] || [[ $string =~ ".regioninfo" ]]
            then
                echo 'not hfile'
            else
                cf=$(echo $string|cut -d'/' -f11)
                # echo $cf
                hdfsout3="${tmpdir}hdfs-$t-$region-$cf.out.tmp"
                phase TABLE $t REGION $region COLUMNFAMILY $cf
                hdfs dfs -du -h $srchdfs$srcdir$t/$region/$cf >$hdfsout3
                hdfs dfs -mkdir $desthdfs$destdir$t/$region/$cf
                while read l
                do
                    string=$l
                    # echo $string
                    if [[ $string =~ $re ]]
                    then
                        hfile=${BASH_REMATCH[0]}
                        # echo hfile of $cf: $hfile
                        distcpout="${tmpdir}distcp-$t-$region-$cf-$hfile.out.tmp"
                        phase HFile $hfile
                        echo src: $srchdfs$srcdir$t/$region/$cf/$hfile 
                        echo dest: $desthdfs$destdir$t/$cf
                        echo out: $distcpout
                        hadoop distcp $srchdfs$srcdir$t/$region/$cf/$hfile $desthdfs$destdir$t/$region/$cf >$distcpout 2>&1 &
                    fi
                done <$hdfsout3
                wait
            fi
        done <$hdfsout2
    fi
done <$hdfsout
