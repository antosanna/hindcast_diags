#!/bin/sh -l

. ~/.bashrc_skill_scores
. ${DIR_ROOT_SCORES}/descr_SKILL_SCORES.sh


set -evx

yy=$1
fyy=$2
st=$3 #2 figure
refperiod=$4
varm=$5  # var name in the model
all=${6:-3}
#

datamm=${CLIM_OBS_DIR_DIAG}/${varm}
workdir=${CLIM_OBS_DIR_DIAG}/../workdir/${varm}/${st}

pwd=`pwd`
echo $pwd

if [ $all -eq 3 ] ; then
	for yyi in `seq $yy $fyy` ; do
		./assembler_OBS_months.sh $yyi $st $datamm $workdir $varm
	done
	./clim_OBS.sh $refperiod $st $datamm $workdir $varm
fi
if [ $all -eq 2 ] ; then
	for yyi in `seq $yy $fyy` ; do
		./assembler_OBS_months.sh $yyi $st $datamm $workdir $varm
	done
fi
for yyi in `seq $yy $fyy` ; do
	./anom_OBS.sh $yyi $st $refperiod $datamm $workdir $varm
done
if [ $st = "12" ] ;then
   finallist=`ls -1 $datamm/anom/*_199?${st}_ano.${refperiod}.nc $datamm/anom/*_200?${st}_ano.${refperiod}.nc $datamm/anom/*_201[0-6]${st}_ano.${refperiod}.nc | grep -v 1992`
else
   finallist=`ls -1 $datamm/anom/*_199?${st}_ano.${refperiod}.nc $datamm/anom/*_200?${st}_ano.${refperiod}.nc $datamm/anom/*_201[0-6]${st}_ano.${refperiod}.nc`
fi
ncecat -O $finallist $datamm/anom/${varm}_${st}_ano.${refperiod}.nc
ncrename -O -d record,year $datamm/anom/${varm}_${st}_ano.${refperiod}.nc
touch ${DIR_ROOT_SCORES}/ANOM/OBS/logs/${varm}_${st}_ano.${refperiod}_DONE
#rm $finallist
 
exit
