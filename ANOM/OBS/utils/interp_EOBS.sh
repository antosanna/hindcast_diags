#!/bin/sh -l
#BSUB -P 0287
#BSUB -q s_short
#BSUB -J interp_EOBS
#BSUB -o logs/interp_EOBS_%J.out
#BSUB -e logs/interp_EOBS_%J.err
#BSUB -N
#BSUB -u andrea.borrelli@cmcc.it

. $HOME/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh

set -euvx

var=tmin
dir="/work/csp/sp2/VALIDATION/daily/E-OBS/${var}"
C3Soriggridfile="$REPOSITORY/SLM_r360x180_2_C3S.nc"
workdir="$SCRATCHDIR/ANDREA/E-OBS"
EuC3Soriggridfile="EU_SLM_r360x180_2_C3S.nc"
[ -d $workdir ] && rm -r $workdir
mkdir -p $workdir
cd $workdir

cdo sellonlatbox,-40.,75.,25.,75. $C3Soriggridfile $EuC3Soriggridfile
cdo griddes $EuC3Soriggridfile > grid_EU_C3S.txt
cdo remapcon,grid_EU_C3S.txt ${dir}/tmin_1993-2017_0.25deg.nc tmin_1993-2017_1deg.nc
mv tmin_1993-2017_1deg.nc ${dir}
