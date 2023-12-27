#!/bin/sh -l

. $HOME/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo
. $DIR_TEMPL/load_nco

set -vx

yy=$1
fyy=$2
stlist=$3
dir=$4
datamm=$4
workdir=$5
prefix=$6

nmf=6
mkdir -p $datamm
mkdir -p $workdir

cd $workdir

while [ $yy -le $fyy ] ; do
   for st in $stlist ; do

      nm=1
      mm=${st}
      st2=`printf "%.2d" $(( 10#$mm ))`
      year=$yy

      [ -f ${prefix}_mm.${yy}${st2}.nc ] && rm  ${prefix}_mm.${yy}${st2}.nc
      while [ $nm -le $nmf ] ; do
          [ $mm -gt 12 ] && { mm="1" ; year=$(($year + 1)) ; }

          mm2=`printf "%.2d" $(( 10#$mm ))`
                    
          cdo -selyear,${year} /data/delivery/csp/ecaccess/ERAI/mslp_erai_199301-201712_mm.nc tmp${year}$mm2.nc
          cdo -selmon,${mm} tmp${year}$mm2.nc ${prefix}_${yy}${st}_${nm}.nc

          cdo cat ${prefix}_${yy}${st}_${nm}.nc ${prefix}_${yy}${st2}.nc
          rm ${prefix}_${yy}${st}_${nm}.nc
          rm tmp${year}${mm2}.nc
              
          mm=$(($mm + 1))
          nm=$(($nm + 1))
      done

      mm2=$st2
      cdo settaxis,${yy}-${mm2}-15,12:00,1mon ${prefix}_${yy}${mm2}.nc temp_${yy}${mm2}
      cdo setreftime,${yy}-${mm2}-15,12:00 temp_${yy}${mm2} ${prefix}_${yy}${mm2}.nc
      cdo settaxis,${yy}-${mm2}-15,12:00,1mon ${prefix}_${yy}${mm2}.nc temp_${yy}${mm2}
      cdo setreftime,${yy}-${mm2}-15,12:00 temp_${yy}${mm2} ${prefix}_${yy}${mm2}.nc
      rm temp_${yy}${mm2}

      mv ${prefix}_${yy}${mm2}.nc $datamm

  done
  yy=$(($yy + 1))
done
