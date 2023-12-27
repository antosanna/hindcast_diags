#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh

set -evx

refperiod=$1
iniy=`echo $refperiod | cut -c1-4`
fyy=`echo $refperiod | cut -c6-9`
mm="$2"
st=`printf '%.2d' $(( 10#$mm ))`
datamm=$3
var=$4
nrun=$5

yy=$iniy

climdir=$datamm/clim
stclimdir=$climdir/tmpdir/${st}

mkdir -p $stclimdir
if [ ! -d $stclimdir ] ; then 
   mkdir -p $stclimdir
else
   rm -r $stclimdir
   mkdir -p $stclimdir
fi

for yyi in `seq $yy $fyy` ; do
#   # AA + 28/08/20
#   # 90's are still running 
#   if [ $yyi -gt 1995 -a $yyi -le 1999 ]; then
#      continue
#   fi
#   # AA -    
# mean over ensemble members
	list=`ls -1 ${datamm}/${var}_${SPSSYS}_sps_${yyi}${st}_*.nc | head -n $nrun`
	cdo -O ensmean $list $stclimdir/${var}_${SPSSYS}_sps_${yyi}${st}_en.nc


done

#mean over seleceted years
cdo -O ensmean $stclimdir/${var}_${SPSSYS}_*${st}_en.nc $climdir/${var}_${SPSSYS}_clim_$iniy-$fyy.${st}.nc
cdo settaxis,${yy}-$st-15,12:00,1mon $climdir/${var}_${SPSSYS}_clim_$iniy-$fyy.$st.nc $climdir/tmp_${st}_clim.$iniy-$fyy.nc
cdo setreftime,${yy}-$st-15,12:00 $climdir/tmp_${st}_clim.$iniy-$fyy.nc $climdir/${var}_${SPSSYS}_clim_$iniy-$fyy.$st.nc 
cdo settaxis,${yy}-$st-15,12:00,1mon $climdir/${var}_${SPSSYS}_clim_$iniy-$fyy.$st.nc $climdir/tmp_${st}_clim.$iniy-$fyy.nc
cdo setreftime,${yy}-$st-15,12:00 $climdir/tmp_${st}_clim.$iniy-$fyy.nc $climdir/${var}_${SPSSYS}_clim_$iniy-$fyy.$st.nc 
rm $climdir/tmp_${st}_clim.$iniy-$fyy.nc
