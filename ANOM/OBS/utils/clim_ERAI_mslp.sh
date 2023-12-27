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
[ -d $workdir ] && rm -r $workdir

mkdir -p $datamm/clim
mkdir -p $workdir
[ ! -d $datamm/clim/tmpdir ] && mkdir -p $datamm/clim/tmpdir
rm $datamm/clim/tmpdir/*

cd $workdir

while [ $yy -le $fyy ] ; do
   for st in $stlist ; do
   
      ncea -O ${datamm}/${prefix}_${yy}${st}.nc $datamm/clim/tmpdir/${prefix}_${yy}${st}.nc

   done
   yy=$(($yy + 1))
done

for st in $stlist ; do
     
  ncea -O $datamm/clim/tmpdir/${prefix}_????${st}.nc $datamm/clim/${prefix}_clim_${iniy}-$fyy.${st}.nc
  cdo settaxis,0001-$st-15,12:00,1mon $datamm/clim/${prefix}_clim_${iniy}-$fyy.${st}.nc $datamm/clim/temp_0001$st
  cdo settaxis,0001-$st-15,12:00,1mon $datamm/clim/${prefix}_clim_${iniy}-$fyy.${st}.nc $datamm/clim/temp_0001$st
  cdo setreftime,0001-${st}-15,12:00 $datamm/clim/temp_0001$st $datamm/clim/${prefix}_clim_${iniy}-$fyy.${st}.nc
  cdo setreftime,0001-${st}-15,12:00 $datamm/clim/temp_0001$st $datamm/clim/${prefix}_clim_${iniy}-$fyy.${st}.nc
  rm $datamm/clim/temp_0001$st

done
