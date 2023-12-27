#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_SPS35/descr_hindcast.sh

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
here=${10}
#

mymail=andrea.borrelli@cmcc.it

datamm=/work/csp/sp2/SPS3.5/CESM/monthly/$varm/C3S

if [ $all -eq 3 ] ; then

	for yyi in `seq $yy $fyy` ; do
		set +e
                ncapsuleyyyy_${varm}_DONE=`ls -1 ${here}/logs/capsule_${yyi}${st}_${varm}_DONE* | wc -l`
		set -e
                if [ $ncapsuleyyyy_${varm}_DONE -eq 1 ] ; then
			continue
		fi

		workdir=/work/csp/sp2/SPS3.5/CESM/workdir/$varm/${yyi}${st}
        	bsub -q s_medium -P $pID \
	             -J capsule_${yyi}${st} \
		     -o logs/capsule_${yyi}${st}_%J.out \
		     -e logs/capsule_${yyi}${st}_%J.err \
  		     $here/C3S_lead2Mmonth_capsule.sh $yyi $st $nrun $datamm $workdir $varm $modelversion $here	 
		#input="$yyi $st $nrun $datamm $workdir $varm $modelversion $here"
		#${DIR_SPS35}/submitcommand.sh -m $machine -M 1500 -q $serialq_m -j capsule_${yyi}${st} -l ${here}/logs/ -d ${here} -s C3S_lead2Mmonth_capsule.sh -i "$input"
        	#./C3S_lead2Mmonth_capsule.sh  $yyi $st $nrun $datamm $workdir $varm $modelversion
		while `true` ; do
			ncapsjob=`bj -w | grep capsule | wc -l`
			if [ $ncapsjob -lt 3 ] ; then
				break
			fi
			sleep 60
		done
	done
	while `true` ; do
		njobs=`bj -w | grep capsule | wc -l`
		if [ $njobs -eq 0 ] ; then
			break
		fi
		sleep 300
	done
	while `true` ; do
		ncapsuleDONE=`ls -1 ${here}/logs/capsule_????${st}_${varm}_DONE* | wc -l`

		if [ $ncapsuleDONE -eq $nyearcapsule ] ; then

			break
		else
			ncapsDONEfound=`ls -1 ${here}/logs/capsule_????${st}_${varm}_DONE | wc -l`
			body="$ncapsDONEfound file found of the $nyearcapsule expected"
			echo $body  | mail -s "SPS3.5 hindcast MONTHLY MEANS ERROR" ${mymail}
			exit
		fi
		sleep 300
	done

	./C3S_clim_02Cineca_199502Zeus.sh $refperiod $st $datamm $varm $nrun
	for yyi in `seq $yy $fyy` ; do
        	workdir=/work/csp/sp2/SPS3.5/CESM/workdir/$varm/${yyi}${st}
		./anom_SPS3.5_C3S_02Cineca_199502Zeus.sh $yyi $st $refperiod $nrun $datamm $varm
		ln -sf $datamm/anom/${varm}_SPS3.5_sps_${yyi}${st}_ens_ano.${refperiod}.nc $workdir
        	ln -sf $datamm/anom/${varm}_SPS3.5_sps_${yyi}${st}_all_ano.${refperiod}.nc $workdir
	done
	listensm=`ls -1 $workdir/../????${st}/*_????${st}_ens_ano.${refperiod}.nc`
	ncecat -O $listensm $datamm/anom/${varm}_SPS3.5_${st}_ens_ano.${refperiod}.nc
	ncrename -O -d record,year $datamm/anom/${varm}_SPS3.5_${st}_ens_ano.${refperiod}.nc

	finallist=`ls -1 $workdir/../????${st}/*_????${st}_all_ano.${refperiod}.nc`
	ncecat -O $finallist $datamm/anom/${varm}_SPS3.5_${st}_all_ano.${refperiod}.nc
	ncrename -O -d record,year $datamm/anom/${varm}_SPS3.5_${st}_all_ano.${refperiod}.nc
 
else
	yyi=$yy
	if [ $all -eq 2 ] ; then
   		./C3S_clim_02Cineca_199502Zeus.sh $refperiod $st $datamm $varm $nrun
  		for yyi in `seq $yy $fyy` ; do
			workdir=/work/csp/sp2/SPS3.5/CESM/workdir/$varm/${yyi}${st}
		        ./anom_SPS3.5_C3S_02Cineca_199502Zeus.sh $yyi $st $refperiod $nrun $datamm $varm
		        ln -sf $datamm/anom/${varm}_SPS3.5_sps_${yyi}${st}_ens_ano.${refperiod}.nc $workdir
        		ln -sf $datamm/anom/${varm}_SPS3.5_sps_${yyi}${st}_all_ano.${refperiod}.nc $workdir
        	done
	elif [ $all -eq 1 ] ; then
  		for yyi in `seq $yy $fyy` ; do
			workdir=/work/csp/sp2/SPS3.5/CESM/workdir/$varm/${yyi}${st}
			./anom_SPS3.5_C3S_02Cineca_climCineca+1995Zeus.sh $yyi $st $refperiod $nrun $datamm $varm
		done
        elif [ $all -eq 0 ] ; then
	     for yyi in `seq $yy $fyy` ; do
                set +e
                ncapsuleyyyy_${varm}_DONE=`ls -1 ${here}/logs/capsule_${yyi}${st}_${varm}_DONE* | wc -l`
                set -e
                if [ $ncapsuleyyyy_${varm}_DONE -eq 1 ] ; then
                        continue
                fi  

                workdir=/work/csp/sp2/SPS3.5/CESM/workdir/$varm/${yyi}${st}
                bsub -q s_medium -P $pID \
                     -J capsule_${yyi}${st} \
                     -o logs/capsule_${yyi}${st}_%J.out \
                     -e logs/capsule_${yyi}${st}_%J.err \
                     $here/C3S_lead2Mmonth_capsule.sh $yyi $st $nrun $datamm $workdir $varm $modelversion $here  
                #input="$yyi $st $nrun $datamm $workdir $varm $modelversion $here"
                #${DIR_SPS35}/submitcommand.sh -m $machine -M 1500 -q $serialq_m -j capsule_${yyi}${st} -l ${here}/logs/ -d ${here} -s C3S_lead2Mmonth_capsule.sh -i "$input"
                #./C3S_lead2Mmonth_capsule.sh  $yyi $st $nrun $datamm $workdir $varm $modelversion
                while `true` ; do
                        ncapsjob=`bj -w | grep capsule | wc -l`
                        if [ $ncapsjob -lt 3 ] ; then
                                break
                        fi  
                        sleep 60
                done
            done
	    while `true` ; do
                njobs=`bj -w | grep capsule | wc -l`
                if [ $njobs -eq 0 ] ; then
                        break
                fi
                sleep 300
            done
            while `true` ; do
                ncapsuleDONE=`ls -1 ${here}/logs/capsule_????${st}_${varm}_DONE* | wc -l`

                if [ $ncapsuleDONE -eq $nyearcapsule ] ; then

                        break
                else
                        ncapsDONEfound=`ls -1 ${here}/logs/capsule_????${st}_${varm}_DONE | wc -l`
                        body="$ncapsDONEfound file found of the $nyearcapsule expected"
                        echo $body  | mail -s "SPS3.5 hindcast MONTHLY MEANS ERROR" ${mymail}
                        exit
                fi
                sleep 300
            done
	fi 
	listensm=`ls -1 ${datamm}/anom/CINECA/*_????${st}_ens_ano.${refperiod}.nc`
        ncecat -O $listensm ${datamm}/anom/CINECA/${varm}_SPS3.5_${st}_ens_ano.${refperiod}.nc
        ncrename -O -d record,year $datamm/anom/CINECA/${varm}_SPS3.5_${st}_ens_ano.${refperiod}.nc
       	finallist=`ls -1 ${datamm}/anom/CINECA/*_????${st}_all_ano.${refperiod}.nc`
       	ncecat -O $finallist $datamm/anom/CINECA/${varm}_SPS3.5_${st}_all_ano.${refperiod}.nc
       	ncrename -O -d record,year $datamm/anom/CINECA/${varm}_SPS3.5_${st}_all_ano.${refperiod}.nc	
fi
