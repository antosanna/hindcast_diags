#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh

set -evx

refperiod=$1
iniy=`echo $refperiod | cut -c1-4`
fyy=`echo $refperiod | cut -c6-9`
mm="$2"
stlist=`printf '%.2d' $(( 10#$mm ))`
datamm=$3
var=$4
nrun=$5

yy=$iniy

mkdir -p $datamm/clim
if [ ! -d $datamm/clim/tmpdir ] ; then 
   mkdir -p $datamm/clim/tmpdir
else
   rm -r $datamm/clim/tmpdir
   mkdir -p $datamm/clim/tmpdir
fi

for yyi in `seq $yy $fyy` ; do
   for st in $stlist ; do
	if [ $yyi -eq 1995 -a $st = "02" ] ; then
# mean over ensemble members
		list=`ls -1 ${datamm}/${var}_SPS3.5_sps_${yyi}${st}_*.nc | head -n $nrun`
	else
		list=`ls -1 ${datamm}/CINECA/${var}_SPS3.5_sps_${yyi}${st}_*.nc | head -n $nrun`
	fi 
	cdo -O ensmean $list $datamm/clim/tmpdir/${var}_SPS3.5_sps_${yyi}${st}_en.nc

   done

done

for st in $stlist ; do
#mean over seleceted years
   cdo -O ensmean $datamm/clim/tmpdir/${var}_SPS3.5_*${st}_en.nc $datamm/clim/${var}_SPS3.5_clim_$iniy-$fyy.${st}.nc
   cdo settaxis,${yy}-$st-15,12:00,1mon $datamm/clim/${var}_SPS3.5_clim_$iniy-$fyy.$st.nc $datamm/clim/tmp_${st}_clim.$iniy-$fyy.nc
   cdo setreftime,${yy}-$st-15,12:00 $datamm/clim/tmp_${st}_clim.$iniy-$fyy.nc $datamm/clim/${var}_SPS3.5_clim_$iniy-$fyy.$st.nc 
   cdo settaxis,${yy}-$st-15,12:00,1mon $datamm/clim/${var}_SPS3.5_clim_$iniy-$fyy.$st.nc $datamm/clim/tmp_${st}_clim.$iniy-$fyy.nc
   cdo setreftime,${yy}-$st-15,12:00 $datamm/clim/tmp_${st}_clim.$iniy-$fyy.nc $datamm/clim/${var}_SPS3.5_clim_$iniy-$fyy.$st.nc 
   rm $datamm/clim/tmp_${st}_clim.$iniy-$fyy.nc
done
