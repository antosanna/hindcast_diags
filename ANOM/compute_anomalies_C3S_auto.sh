#!/bin/sh -l

. ~/.bashrc
. ~/.bashrc_skill_scores
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_SPS35/descr_hindcast.sh
. ${DIR_ROOT_SCORES}/descr_SKILL_SCORES.sh

set -evx

yy=$1
fyy=$2
nyearcapsule=$(($fyy - $yy))
nyearcapsule=$(($nyearcapsule + 1))
st=$3 #2 figures
refperiod=$4
varm=$5  # var name in the model
nrun=$6
all=$7
typefore=$8
modelversion=$9
scriptsdir=${10}
submitdir=${11}
mymail=${12}
#


datamm=${WORK}/${modelversion}/CESM/monthly/$varm/C3S

if [ $all -eq 3 ] ; then
   ncapsulest_DONE=`ls -1 ${scriptsdir}/logs/capsule_${st}_${varm}_DONE*| wc -l`
   if [ $ncapsulest_DONE -ne 1 ] 
   then
    	  for yyi in `seq $yy $fyy` ; do
       		set +e
         ncapsuleyyyy_DONE=`ls -1 ${scriptsdir}/logs/capsule_${yyi}${st}_${varm}_DONE* | wc -l`
    		   set -e
         if [ $ncapsuleyyyy_DONE -eq 1 ] ; then
    		    	continue
    		   fi
    
       		workdir=${WORK}/${modelversion}/CESM/workdir/$varm/${yyi}${st}
    		   input="$yyi $st $nrun $datamm $workdir $varm $modelversion $scriptsdir $submitdir $mymail"
     	  	capsule="C3S_lead2Mmonth_capsule.sh"
    		   ${submitdir}/submitcommand.sh -m $machine -M 5000 -q $serialq_m -j ${varm}_capsule_${yyi}${st} -l ${scriptsdir}/logs/ -d ${scriptsdir} -s $capsule -i "$input"
    		   while `true` ; do
    			     ncapsjob=`bjobs -w | grep capsule | wc -l`
    			     if [ $ncapsjob -lt $nrun ] ; then
    			       	break
    			     fi
    			     sleep 60
    		   done
    	  done
      	while `true` ; do
     		  njobs=`bjobs -w | grep capsule | wc -l`
     	  	if [ $njobs -eq 0 ] ; then
     	    		break
     	  	fi
     	  	sleep 300
    	  done
    	  while `true` ; do
    	   	set +e
    	   	ncapsuleDONE=`ls -1 ${scriptsdir}/logs/capsule_????${st}_${varm}_DONE* | wc -l`
    		   set -e
    
    		   if [ $ncapsuleDONE -eq $nyearcapsule ] ; then
            rm ${scriptsdir}/logs/capsule_????${st}_${varm}_DONE*
            touch ${scriptsdir}/logs/capsule_${st}_${varm}_DONE
         			break
    	    else
    	 	     set +e
    		  	   ncapsDONEfound=`ls -1 ${scriptsdir}/logs/capsule_????${st}_${varm}_DONE | wc -l`
    		      set -e
    		     	body="$ncapsDONEfound file found of the $nyearcapsule expected"
    		     	echo $body  | mail -s "$modelversion hindcast MONTHLY MEANS ERROR" ${mymail}
    		     	exit
    	   	fi
    		   sleep 300
    	  done
   fi
	  ./C3S_clim.sh $refperiod $st $datamm $varm $nrun
	  for yyi in `seq $yy $fyy` ; do
      	workdir=${WORK}/${modelversion}/CESM/workdir/$varm/${yyi}${st}
		     ./anom_C3S.sh $yyi $st $refperiod $nrun $datamm $varm
	     	ln -sf $datamm/anom/${varm}_${modelversion}_sps_${yyi}${st}_ens_ano.${refperiod}.nc $workdir
      	ln -sf $datamm/anom/${varm}_${modelversion}_sps_${yyi}${st}_all_ano.${refperiod}.nc $workdir
	  done
  	set +e
   nf=`ls -1 $workdir/../????${st}/*_????${st}_ens_ano.${refperiod}.nc | wc -l`
  	set -e
   if [ $nf -ne $nyearcapsule ] ; then
      exit
  	fi
	  listensm=`ls -1 $workdir/../????${st}/*_????${st}_ens_ano.${refperiod}.nc`
	  ncecat -O $listensm $datamm/anom/${varm}_${modelversion}_${st}_ens_ano.${refperiod}.nc
	  ncrename -O -d record,year $datamm/anom/${varm}_${modelversion}_${st}_ens_ano.${refperiod}.nc
   touch ${scriptsdir}/logs/${varm}_${modelversion}_${st}_ens_ano.${refperiod}_DONE
  	set +e
   nf=`ls -1 $workdir/../????${st}/*_????${st}_all_ano.${refperiod}.nc | wc -l`
  	set -e
   if [ $nf -ne $nyearcapsule ] ; then
  	   exit
  	fi
  	finallist=`ls -1 $workdir/../????${st}/*_????${st}_all_ano.${refperiod}.nc`
	  ncecat -O $finallist $datamm/anom/${varm}_${modelversion}_${st}_all_ano.${refperiod}.nc
	  ncrename -O -d record,year $datamm/anom/${varm}_${modelversion}_${st}_all_ano.${refperiod}.nc
   touch ${scriptsdir}/logs/${varm}_${modelversion}_${st}_all_ano.${refperiod}_DONE
    
elif [ $all -eq 2 ] ; then
   		 ./C3S_clim.sh $refperiod $st $datamm $varm $nrun
  		  for yyi in `seq $yy $fyy` ; do
			       workdir=${WORK}/${modelversion}/CESM/workdir/$varm/${yyi}${st}
		        ./anom_C3S.sh $yyi $st $refperiod $nrun $datamm $varm
		        ln -sf $datamm/anom/${varm}_${modelversion}_sps_${yyi}${st}_ens_ano.${refperiod}.nc $workdir
        		ln -sf $datamm/anom/${varm}_${modelversion}_sps_${yyi}${st}_all_ano.${refperiod}.nc $workdir
      done
     	set +e
      nf=`ls -1 $workdir/../????${st}/*_????${st}_ens_ano.${refperiod}.nc | wc -l`
     	set -e
      if [ $nf -ne $nyearcapsule ] ; then
         exit
     	fi
   	  listensm=`ls -1 $workdir/../????${st}/*_????${st}_ens_ano.${refperiod}.nc`
   	  ncecat -O $listensm $datamm/anom/${varm}_${modelversion}_${st}_ens_ano.${refperiod}.nc
   	  ncrename -O -d record,year $datamm/anom/${varm}_${modelversion}_${st}_ens_ano.${refperiod}.nc
      touch ${scriptsdir}/logs/${varm}_${modelversion}_${st}_ens_ano.${refperiod}_DONE
     	set +e
      nf=`ls -1 $workdir/../????${st}/*_????${st}_all_ano.${refperiod}.nc | wc -l`
     	set -e
      if [ $nf -ne $nyearcapsule ] ; then
     	   exit
     	fi
     	finallist=`ls -1 $workdir/../????${st}/*_????${st}_all_ano.${refperiod}.nc`
   	  ncecat -O $finallist $datamm/anom/${varm}_${modelversion}_${st}_all_ano.${refperiod}.nc
   	  ncrename -O -d record,year $datamm/anom/${varm}_${modelversion}_${st}_all_ano.${refperiod}.nc
      touch ${scriptsdir}/logs/${varm}_${modelversion}_${st}_all_ano.${refperiod}_DONE
    
elif [ $all -eq 1 ] ; then
  	  for yyi in `seq $yy $fyy` ; do
			     workdir=${WORK}/${modelversion}/CESM/workdir/$varm/${yyi}${st}
			     mkdir -p $workdir
			     ./anom_C3S.sh $yyi $st $refperiod $nrun $datamm $varm
	                #test
		      ln -sf $datamm/anom/${varm}_${modelversion}_sps_${yyi}${st}_ens_ano.${refperiod}.nc $workdir
    	   ln -sf $datamm/anom/${varm}_${modelversion}_sps_${yyi}${st}_all_ano.${refperiod}.nc $workdir
	    done
    	set +e
     nf=`ls -1 $workdir/../????${st}/*_????${st}_ens_ano.${refperiod}.nc | wc -l`
    	set -e
     if [ $nf -ne $nyearcapsule ] ; then
        exit
    	fi
  	  listensm=`ls -1 $workdir/../????${st}/*_????${st}_ens_ano.${refperiod}.nc`
  	  ncecat -O $listensm $datamm/anom/${varm}_${modelversion}_${st}_ens_ano.${refperiod}.nc
  	  ncrename -O -d record,year $datamm/anom/${varm}_${modelversion}_${st}_ens_ano.${refperiod}.nc
     touch ${scriptsdir}/logs/${varm}_${modelversion}_${st}_ens_ano.${refperiod}_DONE
    	set +e
     nf=`ls -1 $workdir/../????${st}/*_????${st}_all_ano.${refperiod}.nc | wc -l`
    	set -e
     if [ $nf -ne $nyearcapsule ] ; then
    	   exit
    	fi
    	finallist=`ls -1 $workdir/../????${st}/*_????${st}_all_ano.${refperiod}.nc`
  	  ncecat -O $finallist $datamm/anom/${varm}_${modelversion}_${st}_all_ano.${refperiod}.nc
  	  ncrename -O -d record,year $datamm/anom/${varm}_${modelversion}_${st}_all_ano.${refperiod}.nc
     touch ${scriptsdir}/logs/${varm}_${modelversion}_${st}_all_ano.${refperiod}_DONE
    
fi
