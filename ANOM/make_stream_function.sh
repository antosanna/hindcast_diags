#!/bin/sh -l

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -euvx

datadir_u=$FINALARCHC3S1
datadir_v=$FINALARCHC3S1

export yyyy=$1
export st=$2
export ppp=$3
cdir=$4

if [ $yyyy -gt 2016 ]
then
   . $DIR_SPS35/descr_forecast.sh
else
   . $DIR_SPS35/descr_hindcast.sh
fi

export ens=`echo $ppp | cut -c2-3`
export filein_u=$datadir_u/${yyyy}${st}/cmcc_CMCC-CM2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_atmos_day_pressure_ua_r${ens}i00p00.nc
export filein_v=$datadir_v/${yyyy}${st}/cmcc_CMCC-CM2-v${versionSPS}_${typeofrun}_S${yyyy}${st}0100_atmos_day_pressure_va_r${ens}i00p00.nc
dirout="$CLIM_DIR_DIAG/sf/C3S"
mkdir -p $dirout
export fileout=$dirout/sf_${SPSSYS}_sps_${yyyy}${st}_${ppp}.nc

ncl ${cdir}/make_stream_function.ncl

exit 0

