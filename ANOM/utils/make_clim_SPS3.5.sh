#!/bin/sh -l
#BSUB -q s_short
#BSUB -J clim_SPS3.5
#BSUB -o logs/clim_SPS3.5_%J.out
#BSUB -e logs/clim_SPS3.5_%J.err

set -euvx

yy=2000
fyy=2006

st="04"

here=`pwd`
dirmm="/work/csp/sp2/SPS3.5/CESM/monthly/TREFHT"

mkdir -p $dirmm/clim/tmpdir
cd $dirmm/clim/tmpdir
while [ $yy -le $fyy ] ; do
	
        filelist=`ls -1 $dirmm/sps3.5_${yy}${st}_???_TREFHT_*.nc`
        ncea -O $filelist TREFHT_SPS3.5_${yy}${st}_en.nc
	yy=$(($yy + 1))    
done

ncea -O TREFHT_SPS3.5_????${st}_en.nc ../TREFHT_SPS3.5_clim_2000-2006.${st}.nc
rm TREFHT_SPS3.5_????${st}_en.nc
exit
