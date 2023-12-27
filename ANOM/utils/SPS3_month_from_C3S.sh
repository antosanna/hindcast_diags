#!/bin/ksh
#BSUB -o SPS3_assembler_%J.out  # Appends std output to file %J.out.
#BSUB -e SPS3_assembler_%J.err  # Appends std error to file %J.err.
#BSUB -q serial_6h       # queue
#BSUB -n 4    

set -vx

yy=$1
st=$2
nrun=$3
datamm=$4
workdir=$5
var=$6
freq=$7

mkdir -p $datamm
mkdir -p $workdir

cd $workdir

case $var
in
   TREFHT) varC3S=tas;;
   PREC) varC3S=lwepr;;
esac
fc="sps_${yy}${st}"  
datadir="/archive/sp1/CESM/archive/$fc/C3S_standard"
rsync -auv $datadir/*${varC3S}_*.tar .
# the two lines above will be substituted by the following
#datadir=/work/sp1/CESM/C3S_standard/output/work_${yy}${st}/
tarfile=`ls -1 *${varC3S}_*.tar`
tar -xvf $tarfile *${varC3S}_*.nc
#**********************************
# THIS WON'T BE REMOVED!!!!!!!!! consider the opportunity to leave *.nc files in tar_and_push.sh
#**********************************
rm $tarfile

plist=`ls -1 *${varC3S}_*r*i00p00* | cut -d '_' -f9 | cut -d '.' -f1 | cut -c2-3`

for pp in $plist 
do
     tfile=`ls -1 cmcc_CMCC-CM2-v20160423_*_S${yy}${st}0100_*_${varC3S}_r${pp}i00p00.nc`
     ppp=`printf "%.03d" ${pp}`
     sps="sps_${yy}${st}_${ppp}"
 
# Concateno i file dei singoli mesi per comporre un'unica serie
#

     if [ $freq -eq 6 ]
     then
        cdo settaxis,${yy}-$st-01,00:00,6hour $tfile tmp_${sps}.nc
     elif [ $freq -eq 24 ]
     then
        cdo settaxis,${yy}-$st-01,00:00,1day $tfile tmp_${sps}.nc
     fi
     cdo setreftime,${yy}-$st-01,00:00 tmp_${sps}.nc $tfile
     rm tmp_${sps}.nc

     cdo monmean $tfile ${var}_SPS3_${sps}_monmean.nc
     cdo chname,${varC3S},$var ${var}_SPS3_${sps}_monmean.nc ${var}_SPS3_${sps}.nc
     ncap2 -O -s 'lon=lon-0.5;' ${var}_SPS3_${sps}.nc ${var}_SPS3_${sps}_tmp.nc
     ncatted -O -h -a bounds,lat,d,, -a bounds,lon,d,, ${var}_SPS3_${sps}_tmp.nc
     ncks -O -x -v lat_bnds,lon_bnds ${var}_SPS3_${sps}_tmp.nc ${var}_SPS3_${sps}.nc
  
     mv ${var}_SPS3_${sps}.nc $datamm
     rm $tfile ${var}_SPS3_${sps}_monmean.nc ${var}_SPS3_${sps}_tmp.nc

   
done  #end loop on plist
