#!/bin/sh
#BSUB -J ROC
#BSUB -o logs/ROC_%J.out  # Appends std output to file %J.out.
#BSUB -e logs/ROC_%J.err  # Appends std error to file %J.err.
#BSUB -q serial_6h       # queue
#BSUB -u antonella.sanna@cmcc.it
#BSUB -N
#BSUB -n 4    

set -evx

export iniy=1993
export endy=2016
st="1" #not 2 figures
export nrun=40

varm="TREFHT"
prefix=t2m_ERAI
export var="T2m"
varERAI=var167
model=SPS3
outputdir=/work/sp2/$model/SKILL_SCORES/ROC
modelprefix=${varm}_${model}
remap=r360x180
#

m=$st
export st=`printf '%.2d' $(( 10#$m ))`
#i=`expr $m - 1`
i=$m
month=(/ January February March April May June July August September October November December /)
mon=${month[$i]}
dirm=/work/sp2/SPS3/CESM/monthly/$varm/anom/
diro=/work/sp2/VALIDATION/ERAI/$var/monthly/anom/
diro2m=/work/sp2/SPS3/ERAI/$var/monthly/anom/
mkdir -p $diro2m

./common_compute_ROC_template.sh $dirm $varm $st $iniy $endy $diro $prefix $var $diro2m $mon $modelprefix $outputdir $model $remap $varERAI
