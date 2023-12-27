#!/bin/sh -l
#BSUB -P 0287
#BSUB -q s_short
#BSUB -J extract_EOBS
#BSUB -o logs/extract_EOBS_%J.out
#BSUB -e logs/extract_EOBS_%J.err
#BSUB -N
#BSUB -u andrea.borrelli@cmcc.it

. $HOME/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -euvx

var=tmax
dirEOBS=/work/csp/sp2/VALIDATION/daily/${var}

yyyyi=1993
yyyyf=2016
st="05"

for yyyy in `seq $yyyyi $yyyyf` ; do

    yyyymmddi=`date -d "${yyyyi}${st}15" +%Y-%m-%d`
    yyyymmddf=`date -d "${yyyyi}${st}01+4 month-1 day" +%Y-%m-%d`
    cdo seldate,$yyyymmddi,$yyyymmddf ${dirEOBS}/${var}_1993-2017_1deg.nc ${dirEOBS}/${var}_${yyyy}${st}.nc 

done
ncecat -O ${dirEOBS}/${var}_????${st}.nc ${dirEOBS}/${var}_${st}.${yyyyi}-${yyyyf}.nc
ncrename -O -d record,year ${dirEOBS}/${var}_${st}.${yyyyi}-${yyyyf}.nc
