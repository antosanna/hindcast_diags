#!/bin/sh
##BSUB -o detect_%J.out  # Appends std output to file %J.out.
##BSUB -e detect_%J.out  # Appends std error to file %J.err.
##BSUB -q poe_short       # queue
##BSUB -u sp1@cmcc.it
##BSUB -n 4               # Number of CPUs

. $HOME/.bashrc
set -evx

yy=$1
yy2=$yy
yym1=$((yy - 1))
st=$2
if [ $st = "01" ] ; then
    yy2=$(($yy - 1))
fi
refperiod=$3
nrun=$4
datamm=$5



enslist=`ls -1 ${datamm}/anom/TS_SPS3_sps_${yy}${st}_0??_ano.${refperiod}.nc | cut -d '_' -f5`

workdir=${datamm}/anom/workdir

[ -d $workdir ] && rm -r $workdir
mkdir $workdir
cd $workdir

for en in $enslist ; do

  DIR="${datamm}/anom" 

#  cdo -seltimestep,1 ${DIR}/TS_SPS3_sps_${yy}${st}_${en}_ano.${refperiod}.nc ${DIR}/TS_SPS3_sps_${yy}${st}_${en}_ano.${refperiod}.tmp.nc
#  cdo setrtomiss,-100,100 ${DIR}/TS_SPS3_sps_${yy}${st}_${en}_ano.${refperiod}.tmp.nc miss.nc
#  rm ${DIR}/TS_SPS3_sps_${yy}${st}_${en}_ano.${refperiod}.tmp.nc
#  ii=1
#  while [ $ii -le 12 ] ; do
#    
#    cdo cat miss.nc miss_12.nc
#    ii=$(($ii + 1))
#  done
  ncrcat -O $HOME/SPS3/postproc/SeasonalForecast/FORECAST_20190306/TS/miss_12.nc ${DIR}/TS_SPS3_sps_${yy}${st}_${en}_ano.${refperiod}.nc TS_SPS3_sps_${yy}${st}_${en}_ano.${refperiod}_miss.nc
  fixtimedd $yym1 ${st} 15 12:00 1mon TS_SPS3_sps_${yy}${st}_${en}_ano.${refperiod}_miss.nc
#  rm miss.nc miss_12.nc
done

ncecat -O TS_SPS3_sps_${yy}${st}_0??_ano.${refperiod}_miss.nc ${DIR}/TS_SPS3_sps_${yy}${st}_all_ano.${refperiod}_miss.nc
#ncrename -O -d record,ensemble ${DIR}/TS_SPS3_sps_${yy}${st}_all_ano.${refperiod}_miss.nc
  
# month before start-date one
yym1=$yy
case $st
    in
    01) stm1=12 
        yym1=$(($yy - 1)) ;;
    * ) stm1=$((10#$st - 1))
        stm1=`printf "%.02d" $stm1` ;;
esac

cd /work/sp2/seasonal/ENSO/
[ -f sstoi.indices ] && rm sstoi.indices
wget -4 --no-check-certificate http://www.cpc.ncep.noaa.gov/data/indices/sstoi.indices
 
#$HOME/SPS3/postproc//SeasonalForecast/FORECAST/TS/make_update_sst_series.sh ${yym1} ${stm1}

