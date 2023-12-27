#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh

set -euvx

yy=$1
mm="$2"
st=`printf '%.2d' $(( 10#$mm ))`
refperiod=$3
nrun=$4
datamm=$5
var=$6
vardir=$var

[ ! -d $datamm/anom ] && mkdir -p $datamm/anom


ensalllist=""
[ -f $datamm/anom/${var}_${SPSSYS}_sps_${yy}${st}_ens_ano.$refperiod.nc ] && rm $datamm/anom/${var}_${SPSSYS}_sps_${yy}${st}_ens_ano.$refperiod.nc
ic=0
cd $datamm
plist=`ls |grep sps_${yy}$st|cut -d '.' -f2|cut -d '_' -f2-5`

for sps in $plist ; do

	
	cdo sub -setmissval,1e+20 $datamm/${var}_${SPSSYS}_${sps}.nc -setmissval,1e+20 $datamm/../../$vardir/C3S/clim/${var}_${SPSSYS}_clim_$refperiod.${st}.nc $datamm/anom/${var}_${SPSSYS}_${sps}_ano.$refperiod.nc
	ic=`expr $ic + 1`
	ensalllist="$ensalllist $datamm/anom/${var}_${SPSSYS}_${sps}_ano.$refperiod.nc"
	if [ $ic -eq $nrun ]
	then
		break
	fi 
done #while on $plist
[ -f $datamm/anom/${var}_${SPSSYS}_sps_${yy}${st}_ens_ano.$refperiod.nc ] && rm $datamm/anom/${var}_${SPSSYS}_sps_${yy}${st}_ens_ano.$refperiod.nc
[ -f $datamm/anom/${var}_${SPSSYS}_sps_${yy}${st}_all_ano.$refperiod.nc ] && rm $datamm/anom/${var}_${SPSSYS}_sps_${yy}${st}_all_ano.$refperiod.nc
cdo -O ensmean $ensalllist $datamm/anom/${var}_${SPSSYS}_sps_${yy}${st}_ens_ano.$refperiod.nc
cdo -O ensstd  $ensalllist $datamm/anom/${var}_${SPSSYS}_sps_${yy}${st}_spread_ano.$refperiod.nc
cdo settaxis,$yy-$st-15,12:00,1mon $datamm/anom/${var}_${SPSSYS}_sps_${yy}${st}_ens_ano.$refperiod.nc tmp${var}_${SPSSYS}_sps_${yy}${st}_ens_ano.$refperiod.nc
cdo setreftime,$yy-$st-15,12:00 tmp${var}_${SPSSYS}_sps_${yy}${st}_ens_ano.$refperiod.nc $datamm/anom/${var}_${SPSSYS}_sps_${yy}${st}_ens_ano.$refperiod.nc
ncecat -O  $ensalllist $datamm/anom/${var}_${SPSSYS}_sps_${yy}${st}_all_ano.$refperiod.nc
ncrename -O -d record,ens $datamm/anom/${var}_${SPSSYS}_sps_${yy}${st}_all_ano.$refperiod.nc
#remove commented for testing phase#
rm $ensalllist
rm tmp${var}_${SPSSYS}_sps_${yy}${st}_ens_ano.$refperiod.nc
  
