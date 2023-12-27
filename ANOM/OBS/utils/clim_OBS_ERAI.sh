#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh

set -euvx

refperiod=$1
iniy=`echo $refperiod | cut -c1-4`
fyy=`echo $refperiod | cut -c6-9`
st=$2
stlist=`printf '%.2d' $(( 10#$st ))`
datamm=$3
workdir=$4
varobs=$5

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
[ -d $workdir ] && rm -r $workdir

mkdir -p $datamm/clim
mkdir -p $workdir
[ ! -d $datamm/clim/tmpdir/${st} ] && mkdir -p $datamm/clim/tmpdir/${st}
set +e
rm $datamm/clim/tmpdir/${st}/*
set -e 

cd $workdir

while [ $yy -le $fyy ] ; do
   for st in $stlist ; do
   
      ncea -O ${datamm}/${varobs}_${yy}${st}.nc $datamm/clim/tmpdir/${st}/${varobs}_${yy}${st}.nc

   done
   yy=$(($yy + 1))
done

for st in $stlist ; do
     
  ncea -O $datamm/clim/tmpdir/${st}/${varobs}_????${st}.nc $datamm/clim/${varobs}_clim_${refperiod}.${st}.nc
  cdo settaxis,0001-$st-15,12:00,1mon $datamm/clim/${varobs}_clim_${refperiod}.${st}.nc $datamm/clim/temp_0001$st
  cdo setreftime,0001-${st}-15,12:00 $datamm/clim/temp_0001$st $datamm/clim/${varobs}_clim_${refperiod}.${st}.nc
  rm $datamm/clim/temp_0001$st
  rm -r $datamm/clim/tmpdir/${st}

done
