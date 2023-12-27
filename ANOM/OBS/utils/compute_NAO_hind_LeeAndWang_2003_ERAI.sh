#!/bin/sh
#BSUB -P 0287
#BSUB -J NAO_ERAI_Lee-Wang2003
#BSUB -o logs/NAO_ERAI_Lee-Wang2003_%J.out  # Appends std output to file %J.out.
#BSUB -e logs/NAO_ERAI_Lee-Wang2003_%J.err  # Appends std error to file %J.err.
#BSUB -q s_medium       # queue
#BSUB -u andrea.borrelli@cmcc.it
#BSUB -N

set -evx

export iniy=1993
export endy=2016
stlist="11"  #07 12 08 01 09 02 10 03 04 05 06" #2 figures
export nrun=40
varm="mslp"
#
datamm=/work/csp/sp2/VALIDATION/ERAI/monthly/mslp
workdir=/work/csp/sp2/VALIDATION/ERAI/workdir/mslp

for st in $stlist
do
   ./NAO_hind_LeeAndWang_2003_ERAI.sh $iniy $endy $st $nrun $datamm $workdir $varm
done

