#!/bin/sh -l
#BSUB -q s_long
#BSUB -J get_GPCC
#BSUB -o logs/get_GPCC_%J.out
#BSUB -e logs/get_GPCC_%J.err
#BSUB -N
#BSUB -u andrea.borrelli@cmcc.it

. ../modules4CDO.sh

set -euvx 


yyi=1993
fyy=2016

mmi=1
mmf=12

datadir="/work/csp/sp2/VALIDATION/monthly/precip"
mkdir -p $datadir
cd $datadir

for yy in `seq $yyi $fyy` ; do

	for mm in `seq $mmi $mmf` ; do
		mmstr=`printf "%.02d" $((10#$mm))`

                cdo selmon,$mm -selyear,$yy precip.mon.mean.nc precip_${yy}${mmstr}.nc
	done

done

