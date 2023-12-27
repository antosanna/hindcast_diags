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
[ -f $datamm/anom/${var}_SPS3.5_sps_${yy}${st}_ens_ano.$refperiod.nc ] && rm $datamm/anom/${var}_SPS3.5_sps_${yy}${st}_ens_ano.$refperiod.nc
ic=0
cd $datamm/CINECA
plist=`ls |grep sps_${yy}$st|cut -d '.' -f2|cut -d '_' -f2-5`
cd -

for sps in $plist ; do

        if [ $yy -eq 1995 -a $mm == "02" ] ; then	
	    cdo sub $datamm/${var}_SPS3.5_${sps}.nc $datamm/../../$vardir/C3S/clim/${var}_SPS3.5_clim_$refperiod.${st}.nc $datamm/anom/${var}_SPS3.5_${sps}_ano.$refperiod.nc
        else
	    cdo sub $datamm/CINECA/${var}_SPS3.5_${sps}.nc $datamm/../../$vardir/C3S/clim/${var}_SPS3.5_clim_$refperiod.${st}.nc $datamm/anom/${var}_SPS3.5_${sps}_ano.$refperiod.nc
        fi 
	ic=`expr $ic + 1`
	ensalllist="$ensalllist $datamm/anom/${var}_SPS3.5_${sps}_ano.$refperiod.nc"
	if [ $ic -eq $nrun ]
	then
		break
	fi 
done #while on $plist
[ -f $datamm/anom/${var}_SPS3.5_sps_${yy}${st}_ens_ano.$refperiod.nc ] && rm $datamm/anom/${var}_SPS3.5_sps_${yy}${st}_ens_ano.$refperiod.nc
[ -f $datamm/anom/${var}_SPS3.5_sps_${yy}${st}_all_ano.$refperiod.nc ] && rm $datamm/anom/${var}_SPS3.5_sps_${yy}${st}_all_ano.$refperiod.nc
cdo -O ensmean $ensalllist $datamm/anom/${var}_SPS3.5_sps_${yy}${st}_ens_ano.$refperiod.nc
cdo -O ensstd  $ensalllist $datamm/anom/${var}_SPS3.5_sps_${yy}${st}_spread_ano.$refperiod.nc
cdo settaxis,$yy-$st-15,12:00,1mon $datamm/anom/${var}_SPS3.5_sps_${yy}${st}_ens_ano.$refperiod.nc tmp${var}_SPS3.5_sps_${yy}${st}_ens_ano.$refperiod.nc
cdo setreftime,$yy-$st-15,12:00 tmp${var}_SPS3.5_sps_${yy}${st}_ens_ano.$refperiod.nc $datamm/anom/${var}_SPS3.5_sps_${yy}${st}_ens_ano.$refperiod.nc
ncecat -O  $ensalllist $datamm/anom/${var}_SPS3.5_sps_${yy}${st}_all_ano.$refperiod.nc
ncrename -O -d record,ens $datamm/anom/${var}_SPS3.5_sps_${yy}${st}_all_ano.$refperiod.nc
#remove commented for testing phase#
#rm $ensalllist
rm tmp${var}_SPS3.5_sps_${yy}${st}_ens_ano.$refperiod.nc
  
