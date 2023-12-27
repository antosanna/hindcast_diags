#!/bin/sh -l
#BSUB -J test_NAO
#BSUB -e ../../../logs/test_NAO_%J.err
#BSUB -o ../../../logs/test_NAO_%J.out
#BSUB -P 0490

. $HOME/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -evxu

st=11
yini=$iniy_hind
fyy=$endy_hind
stlist=`printf '%.2d' $(( 10#$st ))`
datamm=/work/csp/sp2/VALIDATION/monthly/mslp
refperiod=$yini-$fyy

case $st 
 in
 01) SS="FMA" ;;
 02) SS="MAM" ;;
 03) SS="AMJ" ;;
 04) SS="MJJ" ;;
 05) SS="JJA" ;;
 06) SS="JAS" ;;
 07) SS="ASO" ;;
 08) SS="SON" ;;
 09) SS="OND" ;;
 10) SS="NDJ" ;;
 11) SS="DJF" ;;
 12) SS="JFM" ;;
esac

DIRDATA=$SCRATCHDIR/NAO_LiWang_2018_obs
mkdir -p $DIRDATA

yy=$yini
 while [ $yy -le $fyy ] ; do
   
set +e
   gunzip $datamm/anom/mslp_${yy}${st}_ano.${refperiod}.nc.gz 
set -evx

     cdo timmean -seltimestep,2/4 $datamm/anom/mslp_${yy}${st}_ano.${refperiod}.nc $datamm/anom/mslp_${yy}${SS}_ano.${refperiod}.nc

     cdo fldmean -sellonlatbox,-80.,30.,34.,36. $datamm/anom/mslp_${yy}${st}_ano.${refperiod}.nc $DIRDATA/mslp_${yy}${st}_ano.${refperiod}.A1.nc
     cdo fldmean -sellonlatbox,-80.,30.,34.,36. $datamm/anom/mslp_${yy}${SS}_ano.${refperiod}.nc $DIRDATA/mslp_${yy}${SS}_ano.${refperiod}.A1.nc

     cdo fldmean -sellonlatbox,-80.,30.,64.,66. $datamm/anom/mslp_${yy}${st}_ano.${refperiod}.nc $DIRDATA/mslp_${yy}${st}_ano.${refperiod}.A2.nc
     cdo fldmean -sellonlatbox,-80.,30.,64.,66. $datamm/anom/mslp_${yy}${SS}_ano.${refperiod}.nc $DIRDATA/mslp_${yy}${SS}_ano.${refperiod}.A2.nc
 
     yy=$(($yy + 1))


 done

#calulate the ensemble mean and total standard deviation on Southern Area
cdo -O ensmean $DIRDATA/mslp_????${st}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${st}_mean.A1.nc
cdo -O ensstd1 $DIRDATA/mslp_????${st}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${st}_std1.A1.nc

cdo -O ensmean $DIRDATA/mslp_????${SS}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${SS}_mean.A1.nc
cdo -O ensstd1 $DIRDATA/mslp_????${SS}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${SS}_std1.A1.nc
#calulate the ensemble mean and total standard deviation on Northern Area
cdo -O ensmean $DIRDATA/mslp_????${st}_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${st}_mean.A2.nc
cdo -O ensstd1 $DIRDATA/mslp_????${st}_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${st}_std1.A2.nc

cdo -O ensmean $DIRDATA/mslp_????${SS}_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${SS}_mean.A2.nc
cdo -O ensstd1 $DIRDATA/mslp_????${SS}_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${SS}_std1.A2.nc
exit

yy=$yini
while [ $yy -le $fyy ] ; do

#calculate NAO Index on Southern Area
     #cdo sub $DIRDATA/mslp_${yy}${st}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${st}_mean.A1.nc $DIRDATA/mslp_${yy}${st}_ano.${refperiod}.A1.diff.nc
     cdo div $DIRDATA/mslp_${yy}${st}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${st}_std.A1.nc $DIRDATA/NAO_${yy}${st}.${refperiod}.A1.diff.nc
     cdo div $DIRDATA/mslp_${yy}${SS}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${SS}_std.A1.nc $DIRDATA/NAO_${yy}${SS}.${refperiod}.A1.diff.nc

#calculate NAO Index on Northern Area
     #cdo sub $DIRDATA/mslp_${yy}${st}_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${st}_mean.A2.nc $DIRDATA/mslp_${yy}${st}_ano.${refperiod}.A2.diff.nc
     cdo div $DIRDATA/mslp_${yy}${st}_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${st}_std.A2.nc $DIRDATA/NAO_${yy}${st}.${refperiod}.A2.diff.nc
     cdo div $DIRDATA/mslp_${yy}${SS}_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${SS}_std.A2.nc $DIRDATA/NAO_${yy}${SS}.${refperiod}.A2.diff.nc
        
     cdo sub $DIRDATA/NAO_${yy}${st}.${refperiod}.A1.diff.nc $DIRDATA/NAO_${yy}${st}.${refperiod}.A2.diff.nc $DIRDATA/NAO_${yy}${st}.nc
     cdo sub $DIRDATA/NAO_${yy}${SS}.${refperiod}.A1.diff.nc $DIRDATA/NAO_${yy}${SS}.${refperiod}.A2.diff.nc $DIRDATA/NAO_${yy}${SS}.nc


#calculate NAO Index on Southern Area
  cdo div $DIRDATA/mslp_${yy}${st}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${st}_std.A1.nc $DIRDATA/NAO_${yy}${st}.${refperiod}.A1.diff.nc
  cdo div $DIRDATA/mslp_${yy}${SS}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${SS}_std.A1.nc $DIRDATA/NAO_${yy}${SS}.${refperiod}.A1.diff.nc

#calculate NAO Index on Northern Area
  cdo div $DIRDATA/mslp_${yy}${st}_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${st}_std.A2.nc $DIRDATA/NAO_${yy}${st}.${refperiod}.A2.diff.nc
  cdo div $DIRDATA/mslp_${yy}${SS}_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${SS}_std.A2.nc $DIRDATA/NAO_${yy}${SS}.${refperiod}.A2.diff.nc

#calculate NAO Index (Li and Wang, 2003)
  cdo sub $DIRDATA/NAO_${yy}${st}.${refperiod}.A1.diff.nc $DIRDATA/NAO_${yy}${st}.${refperiod}.A2.diff.nc $DIRDATA/NAO_${yy}${st}_standardized.nc
  cdo sub $DIRDATA/NAO_${yy}${SS}.${refperiod}.A1.diff.nc $DIRDATA/NAO_${yy}${SS}.${refperiod}.A2.diff.nc $DIRDATA/NAO_${yy}${SS}_standardized.nc
  
  yy=$(($yy + 1))
done

cdo -O ensstd1 $DIRDATA/NAO_????${SS}_standardized.nc $DIRDATA/NAO_hind_${SS}_std.nc
#Now standardize each yearly NAO index for verification
yy=$yini
while [ $yy -le $fyy ] ; do

   cdo div $DIRDATA/NAO_${yy}${SS}_standardized.nc $DIRDATA/NAO_hind_${SS}_std.nc $DIRDATA/NAO_${yy}${SS}_standardized2.nc
   
   gzip $datamm/anom/mslp_${yy}${st}_ano.${refperiod}.nc

   yy=$(($yy + 1))
done

cdo -O mergetime $DIRDATA/NAO_????${SS}_standardized2.nc $DIRDATA/NAO_${refperiod}_${SS}_standardized_l1.nc


exit
