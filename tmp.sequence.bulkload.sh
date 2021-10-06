factory=('F1' 'F2' 'F3' 'F4' 'F5' 'F6' 'F7' 'F8' 'F8B' 'FT6' 'L1' 'L2' 'L3' 'L4' 'L5' 'L6' 'L7' 'L8' 'LT6' 'LU' 'T1' 'T2' 'T3' 'T4' 'T5' 'T6' 'T7' 'T8' 'T8B' 'TT6')
sequence_a=('F1' 'L1' 'L2' 'F2' 'LT6' 'T1' 'T2' 'FT6' 'TT6' 'T8B')
# F1 L1 L2 F2 LT6 T1 T2 FT6 TT6 T8B
sequence_b=('L3' 'T3' 'F3' 'LU')
sequence_c=('F8B' 'F8' 'L4')
sequence_d=('T8' 'L5' 'T4')
sequence_e=('T7' 'F5')
sequence_f=('F7' 'T5')
sequence_g=('F4' 'L8')
sequence_h=('L7' 'T6')
sequence_i=('L6')
sequence_j=('F6')

for i in ${sequence_a[*]}
do
  echo START $i Bulkload
  sh tmp.factory.bulkload.sh $i >OMNI_TMP_FILES/factory.bulkload-$i.out.tmp 2>&1
  wait
  echo $i Bulkload FIN
done
