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
dirdiag=$4
lasty=$5
echo 'NOW MAX ENSEMBLE SET TO '$nmaxens
         
dirdiagstvar=$dirdiag/$st/$var
dirdiagvar=$dirdiag/$var
mkdir -p $dirdiagstvar
mkdir -p $dirdiagvar
cd $dirdiagstvar
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
					if [[ ! -f $check_6months_done ]]
					then 
# cases transferred from Zeus (DIR_CASES are not transferred)
        if [[ ! -f $DIR_ARCHIVE1/${caso}.transfer_from_Zeus_DONE ]]
        then
           echo "$caso not completed"
			   					continue
        fi
					fi
# do the monthly mean
					filevarmonmean=$dirdiagvar/$caso.cam.$ftype.$var.$yyyy$st.monmean.nc
					if [[ ! -f $filevarmonmean ]]
					then 
# extract single var
					   filevar=$dirdiagvar/$caso.cam.$ftype.$var.$yyyy-$st-01-00000.nc
					   filevartime=$dirdiagvar/$caso.cam.$ftype.$var.$yyyy-$st-01-00000.nc
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
								yfilevarensmean=$dirdiagvar/cam.$ftype.$var.$yyyy$st.ensmean.$nmaxens.nc
								if [[ ! -f $yfilevarensmean ]]
								then
											cdo ensmean $inpfilelist $yfilevarensmean
								fi
        break
					fi
		done #loop on ens
done #loop on years
mkdir -p $dirdiagvar/CLIM
hindclimfile=$dirdiagvar/CLIM/cam.$ftype.$st.$var.clim.$iniy_hind-$lasty.$nmaxens.nc
list4hindclim=""
if [[ ! -f $hindclimfile ]]
then
   for yyyy in `seq $iniy_hind $lasty`
   do
      list4hindclim+=" $dirdiagvar/cam.$ftype.$var.$yyyy$st.ensmean.$nmaxens.nc"
   done
   cdo -ensmean $list4hindclim $hindclimfile
fi
anomdir=$dirdiagstvar/ANOM
mkdir -p $anomdir
cd $dirdiagvar
for yyyy in `seq $iniy_hind $lasty`
do
   listfull=""
   listanom=""
   listfull=`ls ${SPSSystem}_${yyyy}${st}_0??.cam.$ftype.$var.$yyyy$st.monmean.nc|head -n $nmaxens`
   for ff in $listfull
   do
      caso=`echo $ff|cut -d '.' -f1`
      cdo sub $ff $hindclimfile $anomdir/${caso}_${var}.$ftype.anom.$iniy_hind-$lasty.$nmaxens.nc
      listanom+=" $anomdir/${caso}_${var}.$ftype.anom.$iniy_hind-$lasty.$nmaxens.nc"
   done
   if [[ ! -f $anomdir/cam.$ftype.$yyyy$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc ]]
   then
      ncecat $listanom $anomdir/cam.$ftype.$yyyy$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc
      ncrename -O -d record,ens $anomdir/cam.$ftype.$yyyy$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc
   fi
   if [[ ! -f $anomdir/cam.$ftype.$yyyy$st.$var.ens_anom.$iniy_hind-$lasty.$nmaxens.nc ]]
   then
      cdo ensmean $listanom $anomdir/cam.$ftype.$yyyy$st.$var.ens_anom.$iniy_hind-$lasty.$nmaxens.nc
   fi
done
if [[ ! -f $anomdir/cam.$ftype.$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc ]]
then
   ncecat  $anomdir/cam.$ftype.????$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc $anomdir/cam.$ftype.$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc
   ncrename -O -d record,year $anomdir/cam.$ftype.$st.$var.all_anom.$iniy_hind-$lasty.$nmaxens.nc
fi
