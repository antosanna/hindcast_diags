#!/bin/sh
#BSUB -P 0490
#BSUB -J NAO_Lee-Wang2003
#BSUB -o logs/NAO_Lee-Wang2003_%J.out  # Appends std output to file %J.out.
#BSUB -e logs/NAO_Lee-Wang2003_%J.err  # Appends std error to file %J.err.
#BSUB -q s_medium       # queue
##BSUB -u andrea.borrelli@cmcc.it
##BSUB -N
#BSUB -n 4    

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh

set -evx

export iniy=1993
export endy=2016
stlist="05"  #07 12 08 01 09 02 10 03 04 05 06" #2 figures
export nrun=40
varm="mslp"
#
datamm=$WORK/${SPSSYS}/CESM/monthly/mslp/C3S
workdir=$WORK/${SPSSYS}/CESM/workdir/mslp

for st in $stlist
do
   ./NAO_hind_LiAndWang_2003.sh $iniy $endy $st $nrun $datamm $workdir $varm
done

