#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo
. $DIR_TEMPL/load_nco

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
#   # AA + 28/08/20
#   # 90's are still running 
#   if [ $yyi -gt 1995 -a $yyi -le 1999 ]; then
#      continue
#   fi
#   # AA -    
   for st in $stlist ; do
# mean over ensemble members
	list=`ls -1 ${datamm}/${SPSsystem}_${yyi}${st}_*_${var}.zip.nc | head -n $nrun`
	cdo -O ensmean $list $datamm/clim/tmpdir/${SPSsystem}_${yyi}${st}_en_${var}.zip.nc

   done

done

for st in $stlist ; do
#mean over seleceted years
   cdo -O ensmean $datamm/clim/tmpdir/${SPSsystem}_????${st}_en_${var}.zip.nc $datamm/clim/${var}_${SPSSYS}_clim_$iniy-$fyy.${st}.nc
   cdo settaxis,${yy}-$st-15,12:00,1mon $datamm/clim/${var}_${SPSSYS}_clim_$iniy-$fyy.$st.nc $datamm/clim/tmp_${st}_clim.$iniy-$fyy.nc
   cdo setreftime,${yy}-$st-15,12:00 $datamm/clim/tmp_${st}_clim.$iniy-$fyy.nc $datamm/clim/${var}_${SPSSYS}_clim_$iniy-$fyy.$st.nc 
   cdo settaxis,${yy}-$st-15,12:00,1mon $datamm/clim/${var}_${SPSSYS}_clim_$iniy-$fyy.$st.nc $datamm/clim/tmp_${st}_clim.$iniy-$fyy.nc
   cdo setreftime,${yy}-$st-15,12:00 $datamm/clim/tmp_${st}_clim.$iniy-$fyy.nc $datamm/clim/${var}_${SPSSYS}_clim_$iniy-$fyy.$st.nc 
   rm $datamm/clim/tmp_${st}_clim.$iniy-$fyy.nc
   rm $datamm/clim/tmpdir/${SPSsystem}_????${st}_en_${var}.zip.nc
done
