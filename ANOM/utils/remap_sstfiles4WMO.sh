#!/bin/sh

set -e

yy=$1
st=$2
case $st
 in
 08|09) mm=`echo $st | cut -c2`;;
     *) mm=$st ;;
esac 

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

      file=`ls -1 SPS3_${diag}_${varobs}_${yy}${st}_l${lead}.nc | cut -d '.' -f1` ; 
      case $lead 
       in
       0) fixtimedd $yy $st 01 12:00:00 1mon ${file}.nc ;;
       1) stp1=$(($mm + 1)) ; fixtimedd $yy $stp1 01 12:00:00 1mon ${file}.nc ;;
       2) stp2=$(($stp1 + 1)) ; fixtimedd $yy $stp2 01 12:00:00 1mon ${file}.nc ;;
       3) stp3=$(($stp2 + 1)) ; fixtimedd $yy $stp3 01 12:00:00 1mon ${file}.nc ;;
      esac
      export in="files/${file}.nc"
      export out="files/${file}_2.5x2.5.nc"
      case $diag 
       in
       problow|probup|probmid) export varm="prob" ;;
       ensmean|spread) export varm="sst" ;;
      esac
      cd ..
      echo "sto usando il file $file che ha $varm"
      ncl interpolate_sst.ncl
      cd -


   done
done
export ensmmonthlyf="$monthlydir/${var}_SPS3_sps_${yy}${st}_ens_ano.${refperiod}.nc"
export ensmmonthlyfout="files/SPS3_ensmean_${varobs}_${yy}${st}_2.5x2.5.nc"
export spredmonthlyf="$monthlydir/${var}_SPS3_sps_${yy}${st}_spread_ano.${refperiod}.nc"
export spredmonthlyfout="files/SPS3_spread_${varobs}_${yy}${st}_2.5x2.5.nc"
for diag in ensmean spread ; do
   case $diag
    in 
    ensmean) export in=$ensmmonthlyf ; export out=$ensmmonthlyfout ;;
    spread)  export in=$spredmonthlyf ; export out=$spredmonthlyfout ;;
   esac
   cd ..
   export varm="$var" 
   ncl interpolate_sst.ncl
   cd -
done
