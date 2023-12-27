#!/bin/sh -l

set -euvx

iniy=$1
st=$2
#st=`printf "%.02d" $((10#$sttmp))`
refperiod=$3
datamm=$4
workdir=$5
varobs=$6

yy=$iniy
[ ! -d $datamm/anom ] && mkdir -p $datamm/anom
mkdir -p $workdir

cd $workdir

cdo sub $datamm/${varobs}_${yy}${st}.nc $datamm/clim/${varobs}_clim_${refperiod}.${st}.nc $datamm/anom/${varobs}_${yy}${st}_ano.${refperiod}.nc



