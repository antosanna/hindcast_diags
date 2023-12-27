#!/bin/sh
#BSUB -P 0287
#BSUB -J ANOM
#BSUB -o logs/ANOM_%J.out  # Appends std output to file %J.out.
#BSUB -e logs/ANOM_%J.err  # Appends std error to file %J.err.
#BSUB -q s_medium       # queue
#BSUB -u andrea.borrelli@cmcc.it
#BSUB -N
#BSUB -n 4    

set -evx

export iniy=1993
export endy=2016
stlist="01" # 07 12 08 01 09 02 10 03 04 05 06" #2 figures
export nrun=40
varm="mslp"
mymail="andrea.borrelli@cmcc.it"
#
datamm=/work/csp/sp2/SPS3.5/CESM/monthly/mslp/C3S
workdir=/work/csp/sp2/SPS3.5/CESM/workdir/mslp

HERE=`pwd`

for st in $stlist
do
   bsub -P 0287 -q s_medium -J NAO_${st} -o logs/NAO_${st}_%J.out -e logs/NAO_${st}_%J.err -N -u $mymail $HERE/NAO_hind.sh $iniy $endy $st $nrun $datamm $workdir $varm

done

