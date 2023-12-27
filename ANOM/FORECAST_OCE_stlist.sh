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

set -evx

mymail=andrea.borrelli@cmcc.it

#WARNING!!!
# Before performing this analysis make sure you have precomputed the climatologies for the reference period (/users/home/sp2/CESM/CESM1.2/GIT/cesm/postproc/SPS3/SKILL_SCORES/ANOM)
yy=1993
fyy=2016
stlist="08" # 05"
# Choose the reference period as you want
refperiod=1993-2016
#
nrun=40
typefore="hc"
modelversion="20191201"
make_statistics=0    # 1 to make statistics ; 0 nothing
make_anom=0          # 1 to make anomalies ; 0 nothing

scriptsdir=$HOME/SPS/CMCC-SPS_SKILL_SCORES/ANOM
cd $scriptsdir
# IF YOU WANT TO COMPUTE TERCILES FOR REFERNCE PERIOD SET TO 1
for st in $stlist ; do

     for var in votemper #sohtc040 somixhgt vozocrtx vomecrty
     do
     cd $scriptsdir

        case $var
         in
	 votemper) filetype="grid_T_EquT" ;;
	 sohtc040) filetype="grid_Tglobal" ;;
	 somixhgt|vosaline) filetype="grid_T" ;;
	 vozocrtx) filetype="grid_U" ;;
	 vomecrty) filetype="grid_V" ;;
        esac

        echo 'postprocessing $var '$st

        input="$yy $fyy $st $refperiod $var $nrun $typefore $modelversion $scriptsdir $filetype ${make_statistics} ${make_anom}"
        ${scriptsdir}/submitcommand.sh -m $machine -q $serialq_m -j ${var}_hc_oce_${st}_anom -l ${scriptsdir}/logs/ -d ${scriptsdir} -s compute_stat_OCE_auto.sh -i "$input" 

     done
done

exit 0
