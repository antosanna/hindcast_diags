#!/bin/sh -l
#BSUB -q s_long
#BSUB -J hc_anom_main
#BSUB -o logs/hc_anom_main_%J.out
#BSUB -e logs/hc_anom_main_%J.err
#BSUB -P 0490
#BSUB -N
#BSUB -u andrea.borrelli@cmcc.it

. ~/.bashrc
. ~/.bashrc_skill_scores
. ${DIR_SPS35}/descr_SPS3.5.sh
. ${DIR_ROOT_SCORES}/descr_SKILL_SCORES.sh
. ${DIR_SPS35}/descr_hindcast.sh
. ${DIR_TEMPL}/load_cdo
. ${DIR_TEMPL}/load_nco

set -evx

#WARNING!!!
# Before performing this analysis make sure you have precomputed the climatologies for the reference period (/users/home/sp2/CESM/CESM1.2/GIT/cesm/postproc/SPS3/SKILL_SCORES/ANOM)
yy=$1
fyy=$2
stlist="$3" #05 06 07 08 09 10 11 12 01 02 03 04" # 10 11 12" 
debug=$4
mymail=andrea.borrelli@cmcc.it
# Choose the reference period as you want
refperiod=$5
#
varlist="$6"  #"t2m sst u10 v10 mslp t850 z500 z200 precip prw snprec sf"
modelversion=$7
nrun=$nrunC3Sfore
all=3      #3-if monthly mean + clim + anom ;2 -if only clim + anom; 1-if only anom ; 0 for capsule only
typefore="hc"
varlisttot=`cat varlisttot_C3S.txt`
nyear=$(($fyy - $yy + 1))
nvartot=`echo $varlisttot | wc -w`
nvar=`echo $varlist | wc -w`
totncaps=$(($nyear * $nvar))

scriptsdir=${DIR_ROOT_SCORES}/ANOM
cd $scriptsdir
# IF YOU WANT TO COMPUTE TERCILES FOR REFERNCE PERIOD SET TO 1
for st in $stlist ; do
     for var in $varlist 
     do
        cd $scriptsdir

        echo 'postprocessing $var '$st
        ncapsDONEvar=`ls -1 ${scriptsdir}/logs/*_${modelversion}_${st}_[e,a]??_ano.${refperiod}_DONE | wc -l`
        if [ $ncapsDONEvar -ne $nyear ]
        then 
            if [ $debug -eq 1 ] 
            then
               submitdir=$scriptsdir
            else
               submitdir=${DIR_SPS35}
            fi
            input="$yy $fyy $st $refperiod $var $nrun $all $typefore $modelversion $scriptsdir $submitdir $mymail"
            ${submitdir}/submitcommand.sh -m $machine -M 5000 -q $serialq_m -j ${var}_hc_${st}_anom -l ${scriptsdir}/logs/ -d ${scriptsdir} -s compute_anomalies_C3S_auto.sh -i "$input" 
            while `true` 
            do
               njobs=`$DIR_SPS35/findjobs.sh -m ${machine} -n "_hc_${st}_anom" -c yes`
               if [[ $njobs -lt 1 ]]   # $nvar is too big! Need to set to 1
               then
                  break
               fi
               sleep 300
            done
        fi
     done
#     if [[ $nvar -eq $nvartot ]] ; then
#        while `true` ; do
#           ncapsDONE=`ls -1 ${scriptsdir}/logs/capsule_????${st}_*_DONE | grep -v oce | grep -v snwdpt | wc -l`
#           if [ $ncapsDONE -eq $totncaps ] ; then
#              break
#           fi
#           sleep 300
#        done
#     fi
done

exit 0
