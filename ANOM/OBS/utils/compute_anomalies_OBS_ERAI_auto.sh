#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh

set -evx

yy=$1
fyy=$2
st=$3 #2 figures
refperiod=$4
varm=$5  # var name in the model
all=$6
#

datamm=/work/csp/sp2/VALIDATION/ERAI/monthly/${varm}
workdir=/work/csp/sp2/VALIDATION/ERAI/workdir/${varm}/${st}

pwd=`pwd`
echo $pwd

#if [ $all -eq 4 ] ; then
#	for yyi in `seq $yy $fyy` ; do
#		./assembler_OBS_ERAI_months.sh $yyi $st $datamm $workdir $varm
#	done
#fi
if [ $all -eq 3 ] ; then
	for yyi in `seq $yy $fyy` ; do
		./assembler_OBS_ERAI_months.sh $yyi $st $datamm $workdir $varm
	done
	./clim_OBS_ERAI.sh $refperiod $st $datamm $workdir $varm
fi
if [ $all -eq 2 ] ; then
	for yyi in `seq $yy $fyy` ; do
		./clim_OBS_ERAI.sh $refperiod $st $datamm $workdir $varm 
	done
fi
for yyi in `seq $yy $fyy` ; do
	./anom_OBS_ERAI.sh $yyi $st $refperiod $datamm $workdir $varm
done
finallist=`ls -1 $datamm/anom/*_????${st}_ano.${refperiod}.nc`
ncecat -O $finallist $datamm/anom/${varm}_${st}_ano.${refperiod}.nc
ncrename -O -d record,year $datamm/anom/${varm}_${st}_ano.${refperiod}.nc
#rm $finallist
 
exit
