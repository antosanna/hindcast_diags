#!/bin/sh
#BSUB -q s_medium
#BSUB -J hc_anom_main
#BSUB -o logs/hc_anom_main_%J.out
#BSUB -e logs/hc_anom_main_%J.err
#BSUB -N
#BSUB -P 0287
#BSUB -sla SC_SERIAL_sps35 
#BSUB -app SERIAL_sps35
#BSUB -u andrea.borrelli@cmcc.it

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_SPS35/descr_hindcast.sh
. ./modules4CDO.sh

set -evx

#WARNING!!!
# Before performing this analysis make sure you have precomputed the climatologies for the reference period (/users/home/sp2/CESM/CESM1.2/GIT/cesm/postproc/SPS3/SKILL_SCORES/ANOM)
yy=1993
fyy=2016
stlist="02"
# Choose the reference period as you want
refperiod=1993-2016
#
nrun=40
all=1      #3-if monthly mean + clim + anom ;2 -if only clim + anom; 1-if only anom ; 0 for capsule only
typefore="hc"

if [ $stlist = "04" ] ; then
	versionflag=tmp
	case $versionflag
	 in
	 tmp) modelversion="3"  ;;
	 def) modelversion="20191201" ;;
	esac
else
	versionflag=def
	modelversion="20191201"
fi
HERE=$HOME/SPS/CMCC-SPS_SKILL_SCORES/ANOM
cd $HERE
# IF YOU WANT TO COMPUTE TERCILES FOR REFERNCE PERIOD SET TO 1
for st in $stlist ; do


     for var in t2m #precip mslp z500 t850 sst
     do
     cd $HERE

        echo 'postprocessing $var '$st

        #bsub -q s_medium -P ${pID} -J ${var}_hc_${st}_anom -e logs/${var}_hc_${st}_anom_%J.err -o logs/${var}_hc_${st}_anom_%J.out ${HERE}/compute_anomalies_C3S_auto.sh $yy $fyy $st $refperiod $var $nrun $all $typefore $modelversion $HERE	
        input="$yy $fyy $st $refperiod $var $nrun $all $typefore $modelversion $HERE"
        ${DIR_SPS35}/submitcommand.sh -m $machine -M 1500 -q $serialq_m -j ${var}_hc_${st}_anom -l ${HERE}/logs/ -d ${HERE} -s compute_anomalies_C3S_auto_02Cineca_climCineca+199502Zeus.sh -i "$input" 

        redo=0
        if [ $redo -eq 1 ]  ;then
           if [ $var != "sst" ] ; then
              ./remap_files4WMO.sh $yy $st $var
           else
              ./remap_sstfiles4WMO.sh $yy $st $var
           fi
        fi
     done
done

exit 0
