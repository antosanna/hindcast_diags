#!/bin/sh -l

. $HOME/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -evx

##############################################

yy=$1
fyy=$2
stp1=$3
var=$4
dataset=$5
datamm=$6
workdir=$7

tr="$yy-$fyy"
iniy=1993
finy=2016

ANOMDIR="$datamm/$var/anom"
mkdir -p $ANOMDIR
if [ -d $workdir/$var ] ; then 
   rm -rf $workdir/$var
fi
mkdir $workdir/$var
cd $workdir/$var

if [ $stp1 -eq 1 ] ; then
  st=12
  yy=$(($yy - 1))
  fyy=$(($fyy - 1))
else
  st=$(($stp1 - 1))
  yy=$1
  fyy=$2
fi

stm1=`printf "%.02d" $(( 10#$st ))`

while [ $yy -le $fyy ] ; do
  cdo selmon,${stm1} -selyear,${yy} $ANOMDIR/${var}_${yy}${stm1}_ano.${tr}.nc ${var}_${yy}${stm1}_1_ano.nc
  
  nm=1
  mmm=$st
  year=$yy
  while [ $nm -le 6 ] ; do
    if [ $mmm -gt 12 ] ; then 
	{ mm="1" ; year=$(($year + 1)) ; }
    else
	 mm=`printf "%.02d" $(( 10#$mmm ))`
    fi
	 
    if [ $nm -eq 1 ] ; then
      cp ${var}_${yy}${stm1}_1_ano.nc Obs_${var}_${yy}${stm1}_${nm}_ano.nc
    else
      cp ${var}_${yy}${stm1}_1_ano.nc ${var}_${yy}${stm1}_${nm}_ano.nc
      cdo settaxis,${year}-${mm}-01,12:00,1mon ${var}_${yy}${stm1}_${nm}_ano.nc ${var}_${yy}${stm1}_${nm}_ano2.nc
      cdo setreftime,${year}-${mm}-01,12:00 ${var}_${yy}${stm1}_${nm}_ano2.nc Obs_${var}_${yy}${stm1}_${nm}_ano.nc
    fi 

    nm=$(($nm + 1))
    mmm=$(($mmm + 1))
  done 
  nm=1
 yy=`expr $yy + 1`
done

yy=$1
fyy=$2
if [ $stp1 -eq 1 ] ; then
  st2=12
  yy=$(($yy - 1))
  fyy=$(($fyy - 1))
else
  st2=$(($stp1 - 1))
  yy=$1
  fyy=$2
fi

  nm=1
  let "mm=$st2"
  year=$yy
  stp1=$(($st2 + 1))
  if [ $stp1 -gt 12 ] ; then
    stp1=1
  fi
  stp1=`printf "%.02d" ${stp1}`
  st2=`printf "%.02d" ${st2}`
  while [ $nm -le 6 ] ; do
      l=$((nm - 1))
      ncrcat -O Obs_${var}_????${st2}_${nm}_ano.nc Obs_${var}_${st2}_${nm}_pers_ano.nc
      cdo settaxis,${year}-${stp1}-01,12:00,1year Obs_${var}_${st2}_${nm}_pers_ano.nc tmp.nc
      cdo setreftime,${year}-${stp1}-01,12:00 tmp.nc Obs_${var}_${st2}_${nm}_pers_ano.nc
    
      nm=$(($nm + 1))
  done
  ncecat -O Obs_${var}_${st2}_?_pers_ano.nc $ANOMDIR/${var}_${stp1}_ano_pers.${iniy}-${finy}.nc
  if [[ ${var} = "precip" ]] ;then
     ncrename -O -d time,year -v time,year $ANOMDIR/${var}_${stp1}_ano_pers.${iniy}-${finy}.nc
     ncrename -O -d record,time $ANOMDIR/${var}_${stp1}_ano_pers.${iniy}-${finy}.nc
  else
     ncrename -O -d time,year $ANOMDIR/${var}_${stp1}_ano_pers.${iniy}-${finy}.nc
     ncrename -O -d record,time $ANOMDIR/${var}_${stp1}_ano_pers.${iniy}-${finy}.nc
  fi

  rm -r $workdir/${var}
							   
exit
