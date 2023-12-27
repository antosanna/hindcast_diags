#!/bin/sh -l
#BSUB -q s_long
#BSUB -J obs_anom_main
#BSUB -o logs/obs_anom_main_%J.out
#BSUB -e logs/obs_anom_main_%J.err
#BSUB -N
#BSUB -u andrea.borrelli@cmcc.it
#BSUB -P 0490

# Set prompt
. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. ../modules4CDO.sh

set -uevx

#WARNING!!!
# Before performing this analysis make sure you have precomputed the climatologies for the reference period (/users/home/sp2/CESM/CESM1.2/GIT/cesm/postproc/SPS3/SKILL_SCORES/ANOM)
yy=1993
fyy=2016
stlist="11" #02 03 04 05 07 10 11 12" #2 figures
refperiod=$yy-$fyy
all=3      #3 if all ; 2 if only monthly mean + anom and plot;
export reglist="global"  # Europe Tropics NH SH"
ensoreglist="Nino1+2 Nino3 Nino3.4 Nino4"

HERE=`pwd`

cd $HERE
# IF YOU WANT TO COMPUTE TERCILES FOR REFERNCE PERIOD SET TO 1
for st in $stlist ; do

	for var in var129   #PSL Z500 T850 TS var167
	do
		cd $HERE
		case $var
 		in
 		var167) varobs=t2m ;;
 		var134) varobs=mslp ;;
 		precip) varobs=precip ;;
		 var129) varobs=z500 ;;
 		var130) varobs=t850 ;;
 		sst)  varobs=sst ;;
		esac

		echo 'postprocessing $varobs '$st
		bsub -P 0490 -q s_short -J ${varobs}_${st}_obs_anom -e logs/${varobs}_${st}_obs_anom_%J.err -o logs/${varobs}_${st}_obs_anom_%J.out $HERE/compute_anomalies_OBS_ERAI_auto.sh $yy $fyy $st $refperiod $varobs $all
        #./compute_anomalies_C3S_auto.sh $yy $fyy $st $refperiod $var $nrun $all $typefore "$reglist" "$ensoreglist"

	done
done

exit 0
