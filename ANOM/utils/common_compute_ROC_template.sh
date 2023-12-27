#!/bin/sh
set -xv 

dirm=$1
varm=$2
st=$3
iniy=1993
endy=2016
diro=$6
prefix=$7
var=$8
diro2m=$9
export mon=${10}
modelprefix=${11}
outputdir=${12}
export model=${13}
remap=${14}
varNCEP=${15}

for l in 0 1 2 3
do
   cd ncl
   export lead=$l
   export outputfile=$outputdir/${model}_ROC_${var}_${yearfore}${st}_l${lead}_clim1993-2016_N$nrun.nc
#   if [ ! -f $outputfile ]
#   then
      mm=`expr $st + $l`
      if [ $mm -gt 12 ]
      then
        mm=`expr $mm - 12`
      fi
      lp1=`expr $l + 1`
      lp3=`expr $l + 3`
#now model data
      ncks -O -F -d time,$lp1,$lp3 $dirm/${modelprefix}_${yearfore}${st}_all_ano.${iniy}-${endy}.nc $dirm/${modelprefix}_${yearfore}${st}_all_l${l}_ano.${iniy}-${endy}.nc
      export inputm=$dirm/${modelprefix}_${yearfore}${st}_all_l${l}_ano.${iniy}-${endy}.nc
#now obs data
      export inputo=$diro2m/${prefix}_${yearfore}${st}_l${l}_ano.${iniy}-${endy}.all.nc
      cdo $shift -selsmon,$mm,0,2 $diro/${prefix}_${yearfore}${st}_ano.${iniy}-${endy}.nc $diro/${prefix}_${yearfore}${st}_l${l}_ano.${iniy}-${endy}.all.nc
      cdo -remapbil,$remap $diro/${prefix}_${yearfore}${st}_l${l}_ano.${iniy}-${endy}.all.nc $inputo
#
      if [ ! -f ROC_${varm}.ncl ]
      then
         sed -e "s/obstemplate/"${varNCEP}"/g" ROC_template.ncl > ctr
         sed -e "s/vartemplate/"${varm}"/g" ctr > ROC_${varm}.ncl
      fi
      ncl ROC_${varm}.ncl
#   fi
   ncl plot_ROC_a.ncl
   ncl plot_ROC_b.ncl
   ncl plot_ROC_n.ncl
   cd ..
done
