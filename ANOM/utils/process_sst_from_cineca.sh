#!/bin/sh -l
#BSUB -P 0287
#BSUB -q s_medium
#BSUB -J proc_sst_cineca
#BSUB -o logs/proc_sst_cineca_%J.out
#BSUB -e logs/proc_sst_cineca_%J.err
#BSUB -N
#BSUB -u andrea.borrelli@cmcc.it

. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -euvx


iyy=1993
fyy=2016

st="12"

dirmm="/work/csp/sp2/SPS3.5/CESM/monthly/sst/C3S"
cd $dirmm

for yyyy in `seq $iyy $fyy` ; do

    for ppp in `seq -w 001 040` ; do

        cdo -setmissval,1e+20 -setctomiss,271.35 sst_SPS3.5_sps_${yyyy}${st}_${ppp}.nc sst_SPS3.5_sps_${yyyy}${st}_${ppp}_tmp.nc
	mv sst_SPS3.5_sps_${yyyy}${st}_${ppp}_tmp.nc sst_SPS3.5_sps_${yyyy}${st}_${ppp}.nc
        

    done 

done
