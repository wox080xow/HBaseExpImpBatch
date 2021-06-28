# dir for tmp files
tmpdir="OMNI_TMP_FILES/"
if [[ -d $tmpdir ]]
then
  echo "directory $tmpdir for tmp files is exist"
else
  mkdir $tmpdir
  echo "directory $tmpdir for tmp files is created"
fi
