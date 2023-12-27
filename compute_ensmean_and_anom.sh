#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_nco
module load intel-2021.6.0/cdo-threadsafe/2.1.1-lyjsw
set -euxv
# SECTION TO BE MODIFIED BY USER
debug=0
nmaxens=$1
var=$2
st=$3
echo 'NOW MAX ENSEMBLE SET TO '$nmaxens
         
mkdir -p $dirdiag/$var
cd $dirdiag/$var
#for yyyy in `seq $iniy_hind $endy_hind`
lasty=1999
for yyyy in `seq $iniy_hind $lasty`
do
		nens=0
		inpfilelist=" "
		for ens in `seq -f "%03g" 1 40`
		do
					caso=${SPSSystem}_${yyyy}${st}_${ens}
					inpfile=$DIR_ARCHIVE1/$caso/$comp/hist/$caso.cam.$ftype.$yyyy-$st-01-00000.nc
     set +euvx
     . $dictionary
     set -euvx
					if [[ ! -f $inpfile ]]
					then 
        echo "$caso not completed"
								continue
					fi
# do the monthly mean
					filevarmonmean=$dirdiag/$var/$caso.cam.$ftype.$var.$yyyy$st.monmean.nc
					if [[ ! -f $filevarmonmean ]]
					then 
# extract single var
					   filevar=$dirdiag/$var/$caso.cam.$ftype.$var.$yyyy-$st-01-00000.nc
					   filevartime=$dirdiag/$var/$caso.cam.$ftype.$var.$yyyy-$st-01-00000.nc
								cdo selvar,$var $inpfile $filevar
# exclude first output timestep (IC)
								ncks -O -F -d time,2, $filevar $filevartime
# monthly mean single variable single caso
								cdo seltimestep,1/6 -monmean $filevartime $filevarmonmean
        rm $filevar $filevartime
        fi
								inpfilelist+=" $filevarmonmean"
								nens=$(($nens + 1))
								if [[ $nens -eq $nmaxens ]]
								then
											yfilevarensmean=$dirdiag/$var/cam.$ftype.$var.$yyyy$st.ensmean.$nmaxens.nc
											if [[ ! -f $yfilevarensmean ]]
											then
														cdo ensmean $inpfilelist $yfilevarensmean
											fi
#											lasty=$yyyy
           break
								fi
					done #loop on ens
done #loop on years
mkdir -p $dirdiag/$var/CLIM
hindclimfile=$dirdiag/$var/CLIM/cam.$ftype.$st.$var.clim.$iniy_hind-$lasty.$nmaxens.nc
list4hindclim=""
if [[ ! -f $hindclimfile ]]
then
   for yyyy in `seq $iniy_hind $lasty`
   do
      list4hindclim+=" $dirdiag/$var/cam.$ftype.$var.$yyyy$st.ensmean.$nmaxens.nc"
   done
   cdo -ensmean $list4hindclim $hindclimfile
fi
mkdir -p $dirdiag/$var/ANOM
for yyyy in `seq $iniy_hind $lasty`
do
   listfull=""
   listanom=""
   listfull=`ls ${SPSSystem}_${yyyy}${st}_0??.cam.$ftype.$var.$yyyy$st.monmean.nc`
   for ff in $listfull
   do
      caso=`echo $ff|cut -d '.' -f1`
      cdo sub $ff $hindclimfile $dirdiag/$var/ANOM/$caso.cam.$ftype.$var.monmean.nc
      listanom+=" $dirdiag/$var/ANOM/$caso.cam.$ftype.$var.monmean.nc"
   done
   if [[ ! -f $dirdiag/$var/ANOM/cam.$ftype.$yyyy$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc ]]
   then
      ncecat $listanom $dirdiag/$var/ANOM/cam.$ftype.$yyyy$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc
      ncrename -O -d record,ens $dirdiag/$var/ANOM/cam.$ftype.$yyyy$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc
   fi
done
if [[ ! -f $dirdiag/$var/ANOM/cam.$ftype.$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc ]]
then
   ncecat  $dirdiag/$var/ANOM/cam.$ftype.????$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc $dirdiag/$var/ANOM/cam.$ftype.$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc
   ncrename -O -d record,year $dirdiag/$var/ANOM/cam.$ftype.$yyyy$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc
fi
