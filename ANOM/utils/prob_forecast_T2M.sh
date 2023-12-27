#!/bin/sh

set -evx

yyyyfore=$1
mmfore=$2
refperiod=$3
nrun=$4
datamm=$5
workdir=$6
varm=$7

user=`whoami`

dir="$datamm/anom" 
tercdir="/work/${user}/SPS3/CESM/pctl"
dirout="$datamm/anom/prob"
mkdir -p $dirout

cd $workdir
flist=`ls -1 ${dir}/${varm}_SPS3_sps_${yyyyfore}${mmfore}_0??_ano.${refperiod}.nc`

pp=1
for ff in $flist ; do
  
 if [ $pp -le $nrun ] ; then
  
   ens=`echo $ff | cut -d '_' -f5`
   for l in 0 1 2 ; do 
      
      case $l 
       in
       0) l1=1 ; l2=3 ;;
       1) l1=2 ; l2=4 ;;
       2) l1=3 ; l2=5 ;;
      esac

      cdo lt -timmean -seltimestep,${l1}/${l2} ${dir}/${varm}_SPS3_sps_${yyyyfore}${mmfore}_${ens}_ano.${refperiod}.nc ${tercdir}/${varm}_${mmfore}_l${l}_33.nc ${varm}_${yyyyfore}${mmfore}_l${l}_${ens}_low_terc.nc
      cdo gt -timmean -seltimestep,${l1}/${l2} ${dir}/${varm}_SPS3_sps_${yyyyfore}${mmfore}_${ens}_ano.${refperiod}.nc ${tercdir}/${varm}_${mmfore}_l${l}_66.nc ${varm}_${yyyyfore}${mmfore}_l${l}_${ens}_up_terc.nc
      cdo le ${dir}/${varm}_SPS3_sps_${yyyyfore}${mmfore}_${ens}_ano.${refperiod}.nc ${tercdir}/${varm}_${mmfore}_l${l}_66.nc ${varm}_${yyyyfore}${mmfore}_${ens}_norm_1.nc 
      cdo ge ${dir}/${varm}_SPS3_sps_${yyyyfore}${mmfore}_${ens}_ano.${refperiod}.nc ${tercdir}/${varm}_${mmfore}_l${l}_33.nc ${varm}_${yyyyfore}${mmfore}_${ens}_norm_2.nc 
      cdo mul ${varm}_${yyyyfore}${mmfore}_${ens}_norm_1.nc ${varm}_${yyyyfore}${mmfore}_${ens}_norm_2.nc ${varm}_${yyyyfore}${mmfore}_l${l}_${ens}_norm_terc.nc

      rm ${varm}_${yyyyfore}${mmfore}_${ens}_norm_1.nc ${varm}_${yyyyfore}${mmfore}_${ens}_norm_2.nc
    
   done
 fi

 pp=$(($pp + 1))
done

# Calculate probability forecast for each event (E-/E=/E+)

for l in 0 1 2 ; do

   ncea -O ${varm}_${yyyyfore}${mmfore}_l${l}_0??_low_terc.nc ${dirout}/${varm}_SPS3_sps_${yyyyfore}${mmfore}_l${l}_prob_low.${refperiod}.nc
   ncea -O ${varm}_${yyyyfore}${mmfore}_l${l}_0??_norm_terc.nc ${dirout}/${varm}_SPS3_sps_${yyyyfore}${mmfore}_l${l}_prob_norm.${refperiod}.nc
   ncea -O ${varm}_${yyyyfore}${mmfore}_l${l}_0??_up_terc.nc ${dirout}/${varm}_SPS3_sps_${yyyyfore}${mmfore}_l${l}_prob_up.${refperiod}.nc
   
   rm ${varm}_${yyyyfore}${mmfore}_l${l}_0??_low_terc.nc ${varm}_${yyyyfore}${mmfore}_l${l}_0??_norm_terc.nc ${varm}_${yyyyfore}${mmfore}_l${l}_0??_up_terc.nc

done
