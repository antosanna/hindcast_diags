#!/bin/sh -l
#BSUB -q s_long
#BSUB -J obs_anom_main
#BSUB -o logs/obs_anom_main_%J.out
#BSUB -e logs/obs_anom_main_%J.err
#BSUB -N
#BSUB -u andrea.borrelli@cmcc.it
#BSUB -P 0490

. ~/.bashrc_skill_scores
. ${DIR_ROOT_SCORES}/descr_SKILL_SCORES.sh
. ${DIR_TEMPL}/load_cdo

set -uevx

#WARNING!!!
# Before performing this analysis make sure you have precomputed the climatologies for the reference period (/users/home/sp2/CESM/CESM1.2/GIT/cesm/postproc/SPS3/SKILL_SCORES/ANOM)
yy=$1
fyy=$2
stlist="$3" #08 09 10 11 12"  #08 09 10 11 12" # 08 09 10" #2 figures
debug=$4

refperiod=$5
varlist="$6"    #var39 var131_0 var132_0 var132_1 var131_1 var131_2 var132_1 var132_2 var151 var167 precip var129 var130 var34"
all=${7:-3}      #3-if monthly mean +clim+ anom -2 if only monthly mean + anom and plot; 1-if only plot
scriptsdir=${DIR_ROOT_SCORES}/ANOM/OBS

cd $scriptsdir
# IF YOU WANT TO COMPUTE TERCILES FOR REFERNCE PERIOD SET TO 1
for st in $stlist ; do

	  for var in $varlist
  	do
	    	case $var
 		    in
 		    var167) varobs=t2m ;;
 		    var151) varobs=mslp ;;
    			precip) varobs=precip ;;
       var182) varobs=evap ;;
     		var129) varobs=z500 ;;
     		var130) varobs=t850 ;;
     		var131_0) varobs=u925 ;;
     		var131_1) varobs=u850 ;;
     		var131_2) varobs=u200 ;;
     		var132_0) varobs=v925 ;;
     		var132_1) varobs=v850 ;;
     		var132_2) varobs=v200 ;;
     		var34)  varobs=sst ;;
       var39)  varobs=mrlsl ;;
       zos)    varobs=ssh  ;;
       var141) varobs=snwdpt  ;;
    		esac

    		echo 'postprocessing $varobs '$st
      if [ $debug -eq 1 ] 
      then
         submitdir=${DIR_ROOT_SCORES}/ANOM
         mymail=andrea.borrelli@cmcc.it
      else
         submitdir=${DIR_SPS35}
      fi	
      input="$yy $fyy $st $refperiod $varobs $all"
      ${submitdir}/submitcommand.sh -m $machine -M 1000 -q $serialq_s -j ${varobs}_${st}_obs_anom -l ${scriptsdir}/logs -d ${scriptsdir} -s compute_anomalies_OBS_auto.sh -i "$input"
	  done
done

exit 0
