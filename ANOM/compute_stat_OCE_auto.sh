#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_SPS35/descr_hindcast.sh
. $DIR_TEMPL/load_cdo
. $DIR_TEMPL/load_nco


set -evx

yy=$1
fyy=$2
st=$3 #2 figures
refperiod=$4
#extrapolation of iniyy and finalyy from refperiod to evaluate the nyearscapsule
iniyy=`echo $refperiod | cut -d '-' -f1`
finalyy=`echo $refperiod | cut -d '-' -f2`
export varm=$5  # var name in the model
nrun=$6
typefore=$7
case $typefore
 in
 hc) nyearscapsule=$(($finalyy - $iniyy))
     nyearscapsule=$(($nyearscapsule + 1)) ;;
 fc) nyearscapsule=1
esac
modelversion=$8
scriptsdir=$9
filetype=${10}
make_statistics=${11}
make_anom=${12}
#


mymail=andrea.borrelli@cmcc.it

case $varm
 in
 vozocrtx|vomecrty|somixhgt) datamm=/work/csp/sp2/SPS3.5/CESM/monthly/$varm ;;
 votemper|sohtc040)          datamm=/work/csp/sp2/SPS3.5/CESM/daily/$varm  ;;
esac

for yyi in `seq $yy $fyy` ; do
       fileok=$scriptsdir/logs/ALLDONE_${varm}_${yyi}$st
       if [ -f $fileok ]
       then
           continue
       fi
       set +e
       ncapsuleyyyystDONE=`ls -1 ${scriptsdir}/logs/capsule_${yyi}${st}_oce_${varm}_DONE* | wc -l`
       set -e
       if [ $ncapsuleyyyystDONE -eq 0 ] ; then
          for ppp in `seq -w 001 $nrun` ; do
		workdir=/work/csp/sp2/SPS3.5/CESM/workdir/$varm/${yyi}${st}_${ppp}
		input="$yyi $st $ppp $datamm $workdir $varm $modelversion $scriptsdir $filetype"
		$scriptsdir/submitcommand.sh -M 20000 -m $machine -q $serialq_m -j capsule_oce_${yyi}${st}_${ppp} -l ${scriptsdir}/logs/ -d ${scriptsdir} -s C3S_lead2Mmonth_capsule_oce.sh -i "$input"

		while `true` ; do
			ncapsjob=`bjobs -w | grep capsule_oce | wc -l`
			if [ $ncapsjob -lt $nrun ] ; then
				break
			fi
			sleep 60
		done
         done #end loop over members
      # Check if no other capsule jobs are still running
         while `true` ; do
             ncapsjob=`bjobs -w | grep capsule_oce | wc -l`
	     if [ $ncapsjob -eq 0 ] ; then
		break
   	     fi
	     sleep 60
         done      
      fi
      echo "End loop over Members"
      if [ ! -f ${scriptsdir}/logs/capsule_${yyi}${st}_oce_${varm}_DONE ] ; then
         set +e
         ncapsuleyyyystDONE=`ls -1 ${scriptsdir}/logs/capsule_${yyi}${st}_???_oce_${varm}_DONE* | wc -l`
         set -e
         if [ $ncapsuleyyyystDONE -eq $nrun ] ; then
            rm ${scriptsdir}/logs/capsule_${yyi}${st}_???_oce_${varm}_DONE*
            touch ${scriptsdir}/logs/capsule_${yyi}${st}_oce_${varm}_DONE
         else
      	    ncapsyyyystDONEfound=`ls -1 ${scriptsdir}/logs/capsule_${yyi}${st}_???_oce_${varm}_DONE | wc -l`
 	    body="$ncapsyyyystDONEfound file found of the $nrun expected for $yyi$st hindcasts"
            echo $body  | mail -s "SPS3.5 hindcast OCE ERROR" ${mymail}
	    exit
         fi
      fi 
      # calculate min, max, ensmean, square of the yearly value
      # Compute summary statistics
      if [ $make_statistics -eq 1 ] ; then
      	export checkfilestd=$scriptsdir/logs//squaredvalues_${yyi}${st}_${varm}_ok
      	if [ -f $datamm/$checkfilestd -a -f $datamm/sps3.5_${yyi}${st}_${varm}_min.nc -a -f $datamm/sps3.5_${yyi}${st}_${varm}_max.nc -a -f $datamm/sps3.5_${yyi}${st}_${varm}_emean.nc ]
      	then
           echo "everything already compute exiting now"
           if [ ! -f $fileok ]
           then
              touch $fileok
           fi
           exit 0
      	else

           flist=`ls -1 $datamm/sps3.5_${yyi}${st}_0??_${varm}.zip.nc`
# min
           if [ ! -f $datamm/sps3.5_${yyi}${st}_${varm}_min.nc ]
           then
              nces -O -y min -v ${varm} ${flist} $datamm/sps3.5_${yyi}${st}_${varm}_min.nc 
           fi
#max
           if [ ! -f $datamm/sps3.5_${yyi}${st}_${varm}_max.nc ]
           then
              nces -O -y max -v ${varm} ${flist} ${datamm}/sps3.5_${yyi}${st}_${varm}_max.nc 
           fi
# Ensemble mean
           if [ ! -f $datamm/sps3.5_${yyi}${st}_${varm}_emean.nc ]
           then
              ncea -O -v ${varm} ${flist} $datamm/sps3.5_${yyi}${st}_${varm}_emean.nc 
           fi

           if [ ! -f $datamm/sps3.5_${yyi}${st}_${varm}_squaredvalues.nc ] 
           then
              export diri=${datamm}
              export varm=$varm
              export odir=$datamm
	      export flist="sps3.5_${yyi}${st}_???_${varm}.zip.nc"
              export filostd="sps3.5_${yyi}${st}_${varm}_squaredvalues.nc"
              if [ ! -f $checkfilestd ]
              then
                  ncl $scriptsdir/squared_values_oce.ncl
              fi
              if [ ! -f $checkfilestd ]
              then
                 echo "something rotten.... squared_values_C3S.ncl did not terminate correctly"
                 exit
              else
                 touch $fileok
              fi
           fi
      	fi
      fi
done  #end loop over years

while `true` ; do
	njobs=`bjobs -w | grep capsule | wc -l`
	if [ $njobs -eq 0 ] ; then
		break
	fi
	sleep 300
done
while `true` ; do
  	case $typefore
	 in
	 hc) ncapsuleDONE=`ls -1 ${scriptsdir}/logs/capsule_????${st}_oce_${varm}_DONE* | wc -l` ;;
	 fc) ncapsuleDONE=`ls -1 ${scriptsdir}/logs/capsule_${yy}${st}_oce_${varm}_DONE* | wc -l` ;;
	esac
	if [ $ncapsuleDONE -eq $nyearscapsule ] ; then
		break
	else
		set +e
  		case $typefore
		 in
		 hc) ncapsDONEfound=`ls -1 ${scriptsdir}/logs/capsule_????${st}_oce_${varm}_DONE | wc -l` ;;
		 fc) ncapsDONEfound=`ls -1 ${scriptsdir}/logs/capsule_${yy}${st}_oce_${varm}_DONE | wc -l` ;;
      		esac
		set -e
		body="$ncapsDONEfound file found of the $nyearscapsule expected for $st start-date hindcasts"
		echo $body  | mail -s "SPS3.5 hindcast OCE ERROR" ${mymail}
		exit
	fi
	sleep 300
done
if [ $typefore = "hc" ] ; then
	./oce_clim.sh $refperiod $st $datamm $varm $nrun
fi
if [ $makeanom -eq 1 ] ; then
   for yyi in `seq $yy $fyy` ; do
       	workdir=/work/csp/sp2/SPS3.5/CESM/workdir/$varm/${yyi}${st}
	mkdir -p $workdir
	./anom_SPS3.5_oce.sh $yyi $st $refperiod $nrun $datamm $varm
	ln -sf $datamm/anom/${varm}_SPS3.5_sps_${yyi}${st}_ens_ano.${refperiod}.nc $workdir
       	ln -sf $datamm/anom/${varm}_SPS3.5_sps_${yyi}${st}_all_ano.${refperiod}.nc $workdir
   done
   if [ $typefore = "hc" ] ; then
      listensm=`ls -1 $workdir/../????${st}/*_????${st}_ens_ano.${refperiod}.nc`
      ncecat -O $listensm $datamm/anom/${varm}_SPS3.5_${st}_ens_ano.${refperiod}.nc
      ncrename -O -d record,year $datamm/anom/${varm}_SPS3.5_${st}_ens_ano.${refperiod}.nc
#
      finallist=`ls -1 $workdir/../????${st}/*_????${st}_all_ano.${refperiod}.nc`
      ncecat -O $finallist $datamm/anom/${varm}_SPS3.5_${st}_all_ano.${refperiod}.nc
      ncrename -O -d record,year $datamm/anom/${varm}_SPS3.5_${st}_all_ano.${refperiod}.nc
   fi
fi
