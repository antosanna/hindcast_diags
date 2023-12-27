#!/bin/sh -l

set -euvx

iniy=$1
sttmp=$2
st=`printf '%.2d' $(( 10#$sttmp ))`
refperiod=$3
datamm=$4
workdir=$5
varobs=$6

case $varobs
 in
 t2m)    var=var167 ;;
 mslp)   var=var134 ;;
 precip) var=PREC ;;
 z500)   var=var129 ;;
 t850)   var=var130 ;;
 sst)    var=SST ;;
esac

yy=$iniy
[ ! -d $datamm/anom ] && mkdir -p $datamm/anom
mkdir -p $workdir

cd $workdir

cdo sub $datamm/${varobs}_${yy}${st}.nc $datamm/clim/${varobs}_clim_${refperiod}.${st}.nc $datamm/anom/${varobs}_${yy}${st}_ano.${refperiod}.nc
cdo remapbil,r360x180 $datamm/anom/${varobs}_${yy}${st}_ano.${refperiod}.nc $datamm/anom/${varobs}_${yy}${st}_ano.${refperiod}_1x1.nc
rm $datamm/anom/${varobs}_${yy}${st}_ano.${refperiod}.nc
mv $datamm/anom/${varobs}_${yy}${st}_ano.${refperiod}_1x1.nc $datamm/anom/${varobs}_${yy}${st}_ano.${refperiod}.nc



