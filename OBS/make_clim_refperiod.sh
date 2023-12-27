#!/bin/sh -l
#BSUB -J clim_refperiod
#BSUB -e logs/clim_refperiod_%J.err
#BSUB -o logs/clim_refperiod_%J.out
#BSUB -M 1000
#BSUB -P 0516

. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_cdo
set -euvx
dirobs=/work/csp/as34319/obs/

#temperature

cd $dirobs/ERA5/t2m
endy_SPS35=2016
listall=" "
for yyyy in `seq $iniy_hind $endy_SPS35`
do
   for st in {01..12}
   do
      listall+=" t2m_era5_${yyyy}${st}.nc"
   done
done
if [[ ! -f $SCRATCHDIR/tmp/t2m_era5_all.nc ]]
then
   cdo mergetime $listall $SCRATCHDIR/tmp/t2m_era5_all.nc
fi
if [[ ! -f $dirobs/../ERA5_1m_clim_t2m_${iniy_hind}-${endy_SPS35}.nc ]]
then
   cdo ymonmean $SCRATCHDIR/tmp/t2m_era5_all.nc $dirobs/ERA5_1m_clim_t2m_${iniy_hind}-${endy_SPS35}.nc
fi
