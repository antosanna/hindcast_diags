#!/bin/sh -l

. $HOME/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo
. $DIR_TEMPL/load_nco

set -vx

iniy=$1
fyy=$2
st=$3
stlist=`printf '%.2d' $(( 10#$st ))`
datamm=$4
workdir=$5
prefix=$6

yy=$iniy
[ ! -d $datamm/anom ] && mkdir -p $datamm/anom
mkdir -p $workdir

cd $workdir

while [ $yy -le $fyy ] ; do
 for st in $stlist ; do

   cdo sub $datamm/${prefix}_${yy}${st}.nc $datamm/clim/${prefix}_clim_${iniy}-$fyy.${st}.nc $datamm/anom/${prefix}_${yy}${st}_ano.$iniy-$fyy.nc

 done
 yy=$(($yy + 1))
done

for st in $stlist ; do

   cdo -O mergetime $datamm/anom/${prefix}_????${st}_ano.$iniy-$fyy.nc $datamm/anom/${prefix}_${st}_ano.$iniy-$fyy.nc

done
