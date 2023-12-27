#!/bin/ksh
#BSUB -o NAO_%J.out  # Appends std output to file %J.out.
#BSUB -e NAO_%J.err  # Appends std error to file %J.err.
#BSUB -J NAO
#BSUB -q serial_6h       # queue
#BSUB -u sp1@cmcc.it
#BSUB -n 4    

. ~/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -evx

yy=$1
fyy=$2
st=$3
stlist=`printf '%.2d' $(( 10#$st ))`
nrun=$4
datamm=$5
workdir=$6
var=$7
refperiod=$yy-$fyy

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

DIRDATA=${datamm}/anom/NAO
mkdir -p $DIRDATA

redo=1
if [ $redo -eq 1 ] ; then

 while [ $yy -le $fyy ] ; do
   npp=1
   
set +e
   gunzip $datamm/anom/mslp_SPS3.5_sps_${yy}${st}_0??_ano.${refperiod}.nc.gz 
set -evx
   plist=`ls -1 ${datamm}/anom/mslp_SPS3.5_sps_${yy}${st}_0??_ano.${refperiod}.nc | cut -d '_' -f5`
   for pp in $plist ; do

     yyp1=$(($yy + 1))
   
     cdo timmean -seltimestep,2/4 $datamm/anom/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.nc $datamm/anom/mslp_SPS3.5_sps_${yy}${SS}_${pp}_ano.${refperiod}.nc
# Lisbon area
     cdo fldmean -sellonlatbox,-10.,-8.,37.,39. $datamm/anom/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.nc $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.A1.nc
     cdo fldmean -sellonlatbox,-10.,-8.,37.,39. $datamm/anom/mslp_SPS3.5_sps_${yy}${SS}_${pp}_ano.${refperiod}.nc $DIRDATA/mslp_SPS3.5_sps_${yy}${SS}_${pp}_ano.${refperiod}.A1.nc
# Reykjavik area
     cdo fldmean -sellonlatbox,-23.,-21.,63.,65. $datamm/anom/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.nc $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.A2.nc
     cdo fldmean -sellonlatbox,-23.,-21.,63.,65. $datamm/anom/mslp_SPS3.5_sps_${yy}${SS}_${pp}_ano.${refperiod}.nc $DIRDATA/mslp_SPS3.5_sps_${yy}${SS}_${pp}_ano.${refperiod}.A2.nc

     cdo sub $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.A2.nc $DIRDATA/NAO_hind_${yy}${st}_${pp}_mm.nc
     cdo sub $DIRDATA/mslp_SPS3.5_sps_${yy}${SS}_${pp}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_sps_${yy}${SS}_${pp}_ano.${refperiod}.A2.nc $DIRDATA/NAO_hind_${yy}${SS}_${pp}_mm.nc

     #rm $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.A1.nc
     #rm $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.A2.nc
     npp=$(($npp + 1))
     if [ $npp -gt 40 ] ; then
       break
     fi
   done
   cdo -O ensmean $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_???_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_ensm_ano.${refperiod}.A1.nc
   cdo -O ensmean $DIRDATA/mslp_SPS3.5_sps_${yy}${SS}_???_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_sps_${yy}${SS}_ensm_ano.${refperiod}.A1.nc
   cdo -O ensmean $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_???_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_ensm_ano.${refperiod}.A2.nc
   cdo -O ensmean $DIRDATA/mslp_SPS3.5_sps_${yy}${SS}_???_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_sps_${yy}${SS}_ensm_ano.${refperiod}.A2.nc


   yy=$(($yy + 1))
 done

#calulate the ensemble mean and total standard deviation on Southern Area
cdo -O ensmean $DIRDATA/mslp_SPS3.5_sps_????${st}_???_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${st}_mean.A1.nc
cdo -O ensstd $DIRDATA/mslp_SPS3.5_sps_????${st}_???_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${st}_std.A1.nc

cdo -O ensmean $DIRDATA/mslp_SPS3.5_sps_????${SS}_???_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${SS}_mean.A1.nc
cdo -O ensstd $DIRDATA/mslp_SPS3.5_sps_????${SS}_???_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${SS}_std.A1.nc

#calulate the ensemble mean and total standard deviation on Northern Area
cdo -O ensmean $DIRDATA/mslp_SPS3.5_sps_????${st}_???_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${st}_mean.A2.nc
cdo -O ensstd $DIRDATA/mslp_SPS3.5_sps_????${st}_???_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${st}_std.A2.nc

cdo -O ensmean $DIRDATA/mslp_SPS3.5_sps_????${SS}_???_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${SS}_mean.A2.nc
cdo -O ensstd $DIRDATA/mslp_SPS3.5_sps_????${SS}_???_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${SS}_std.A2.nc

fi #end redo

yy=$1
fyy=$2
st=$3
while [ $yy -le $fyy ] ; do
  npp=1
  plist2=`ls -1 ${datamm}/anom/mslp_SPS3.5_sps_${yy}${st}_0??_ano.${refperiod}.nc | cut -d '_' -f5`
  for pp in $plist2 ; do

#calculate NAO Index on Southern Area
#     cdo sub $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${st}_mean.A1.nc $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.A1.diff.nc
     cdo div $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${st}_std.A1.nc $DIRDATA/NAO_${yy}${st}_${pp}.${refperiod}.A1.diff.nc
     cdo div $DIRDATA/mslp_SPS3.5_sps_${yy}${SS}_${pp}_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${SS}_std.A1.nc $DIRDATA/NAO_${yy}${SS}_${pp}.${refperiod}.A1.diff.nc

#calculate NAO Index on Northern Area
     #cdo sub $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${st}_mean.A2.nc $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.A2.diff.nc
     cdo div $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_${pp}_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${st}_std.A2.nc $DIRDATA/NAO_${yy}${st}_${pp}.${refperiod}.A2.diff.nc
     cdo div $DIRDATA/mslp_SPS3.5_sps_${yy}${SS}_${pp}_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${SS}_std.A2.nc $DIRDATA/NAO_${yy}${SS}_${pp}.${refperiod}.A2.diff.nc
        
     cdo sub $DIRDATA/NAO_${yy}${st}_${pp}.${refperiod}.A1.diff.nc $DIRDATA/NAO_${yy}${st}_${pp}.${refperiod}.A2.diff.nc $DIRDATA/NAO_${yy}${st}_${pp}.nc
     cdo sub $DIRDATA/NAO_${yy}${SS}_${pp}.${refperiod}.A1.diff.nc $DIRDATA/NAO_${yy}${SS}_${pp}.${refperiod}.A2.diff.nc $DIRDATA/NAO_${yy}${SS}_${pp}.nc
     npp=$(($npp + 1))
     if [ $npp -gt 40 ] ; then
       break
     fi

  done 
  [ -f $DIRDATA/NAO_${yy}${st}_ens.nc ] && rm $DIRDATA/NAO_${yy}${st}_ens.nc
  ncecat -O $DIRDATA/NAO_${yy}${st}_???.nc $DIRDATA/NAO_${yy}${st}_ens.nc
  ncrename -O -d record,ens $DIRDATA/NAO_${yy}${st}_ens.nc

#calculate NAO Index on Southern Area
  cdo div $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_ensm_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${st}_std.A1.nc $DIRDATA/NAO_${yy}${st}_ensm.${refperiod}.A1.diff.nc
  cdo div $DIRDATA/mslp_SPS3.5_sps_${yy}${SS}_ensm_ano.${refperiod}.A1.nc $DIRDATA/mslp_SPS3.5_${SS}_std.A1.nc $DIRDATA/NAO_${yy}${SS}_ensm.${refperiod}.A1.diff.nc

#calculate NAO Index on Northern Area
  cdo div $DIRDATA/mslp_SPS3.5_sps_${yy}${st}_ensm_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${st}_std.A2.nc $DIRDATA/NAO_${yy}${st}_ensm.${refperiod}.A2.diff.nc
  cdo div $DIRDATA/mslp_SPS3.5_sps_${yy}${SS}_ensm_ano.${refperiod}.A2.nc $DIRDATA/mslp_SPS3.5_${SS}_std.A2.nc $DIRDATA/NAO_${yy}${SS}_ensm.${refperiod}.A2.diff.nc

#calculate NAO Index (Li and Wang, 2003)
  cdo sub $DIRDATA/NAO_${yy}${st}_ensm.${refperiod}.A1.diff.nc $DIRDATA/NAO_${yy}${st}_ensm.${refperiod}.A2.diff.nc $DIRDATA/NAO_${yy}${st}_standardized.nc
  cdo sub $DIRDATA/NAO_${yy}${SS}_ensm.${refperiod}.A1.diff.nc $DIRDATA/NAO_${yy}${SS}_ensm.${refperiod}.A2.diff.nc $DIRDATA/NAO_${yy}${SS}_standardized.nc
  
  yy=$(($yy + 1))
done
ncecat -O -F -d ens,1,40 $DIRDATA/NAO_????${st}_ens.nc $DIRDATA/NAO_${st}_ens_all.${refperiod}.nc
ncrename -O -d record,year $DIRDATA/NAO_${st}_ens_all.${refperiod}.nc

cdo ensstd $DIRDATA/NAO_????${SS}_???.nc $DIRDATA/NAO_hind_${SS}_std.nc

#Now standardize each yearly NAO index for verification
yy=$1
fyy=$2
st=$3
while [ $yy -le $fyy ] ; do

   cdo div $DIRDATA/NAO_${yy}${SS}_standardized.nc $DIRDATA/NAO_hind_${SS}_std.nc $DIRDATA/NAO_${yy}${SS}_standardized2.nc
   
   gzip $datamm/anom/mslp_SPS3.5_sps_${yy}${st}_0??_ano.${refperiod}.nc

   yy=$(($yy + 1))
done

cdo -O mergetime $DIRDATA/NAO_????${SS}_standardized2.nc $DIRDATA/NAO_1993-2016_${SS}_standardized_l1.nc


rm $DIRDATA/mslp_SPS3.5_sps_????${st}_???_ano.${refperiod}.A1.nc
rm $DIRDATA/mslp_SPS3.5_sps_????${st}_???_ano.${refperiod}.A2.nc
rm $DIRDATA/mslp_SPS3.5_sps_????${SS}_???_ano.${refperiod}.A1.nc
rm $DIRDATA/mslp_SPS3.5_sps_????${SS}_???_ano.${refperiod}.A2.nc

#cdo -O ensmean $DIRDATA/NAO_hind_????${st}_0??_mm.nc $DIRDATA/NAO_hind_${st}_mean.nc
#cdo -O ensstd $DIRDATA/NAO_hind_????${st}_0??_mm.nc $DIRDATA/NAO_hind_${st}_std.nc



exit
