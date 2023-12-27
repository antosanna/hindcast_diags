#!/bin/sh

set -evx

yy=$1
st=$2
var=$3
refperiod="1993-2016"

vardir=$var

case $var
in
   TREFHT) export varobs=t2m;;
   TS)     export varobs=sst;;
   PREC)   export varobs=precip;;
   Z500)   export varobs=hgt500;;
   T850)   export varobs=t850;;
   PSL)    export varobs=mslp;;
esac

leadlist="0 1 2 3"
diaglist="problow probup probmid ensmean spread"
#filedir=$HOME/SPS3/postproc/SeasonalForecast/FORECAST/ncl/files
filedir=ncl/files
monthlydir="/work/`whoami`/SPS3/CESM/monthly/${var}/C3S/anom"

cd $filedir

for lead in $leadlist ; do

   for diag in $diaglist ; do

      file=`ls -1 SPS3_${diag}_${varobs}_${yy}${st}_l${lead}.nc | cut -d '.' -f1`
      cdo remapbil,r144x73 ${file}.nc ${file}_2.5x2.5.nc
      

   done
done
flagunit=0
if [ $var = "PREC" ] ; then
   chunit="-mulc,30000"
   flagunit=1
   cdo $chunit $monthlydir/${var}_SPS3_sps_${yy}${st}_ens_ano.${refperiod}.nc tmp_SPS3_ensmean_${varobs}_${yy}${st}_2.5x2.5.nc
   cdo $chunit $monthlydir/${var}_SPS3_sps_${yy}${st}_spread_ano.${refperiod}.nc tmp_SPS3_spread_${varobs}_${yy}${st}_2.5x2.5.nc
   cdo remapbil,r144x73 tmp_SPS3_ensmean_${varobs}_${yy}${st}_2.5x2.5.nc SPS3_ensmean_${varobs}_${yy}${st}_2.5x2.5.nc
   cdo remapbil,r144x73 tmp_SPS3_spread_${varobs}_${yy}${st}_2.5x2.5.nc SPS3_spread_${varobs}_${yy}${st}_2.5x2.5.nc
   rm tmp_SPS3_*_${varobs}_${yy}${st}_2.5x2.5.nc
else
   cdo remapbil,r144x73 $monthlydir/${var}_SPS3_sps_${yy}${st}_ens_ano.${refperiod}.nc SPS3_ensmean_${varobs}_${yy}${st}_2.5x2.5.nc
   cdo remapbil,r144x73 $monthlydir/${var}_SPS3_sps_${yy}${st}_spread_ano.${refperiod}.nc SPS3_spread_${varobs}_${yy}${st}_2.5x2.5.nc
fi


if [ $flagunit -eq 1 ] ; then
   ncatted -O -a units,PREC,c,c,"mm/month" SPS3_ensmean_${varobs}_${yy}${st}_2.5x2.5.nc
   ncatted -O -a units,PREC,c,c,"mm/month" SPS3_spread_${varobs}_${yy}${st}_2.5x2.5.nc
fi



