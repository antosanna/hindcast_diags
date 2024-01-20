#!/bin/sh -l 
#BSUB -P 0516
#BSUB -J test
#BSUB -e logs/test%J.err
#BSUB -o logs/test%J.out
#BSUB -M 10000
. ~/.bashrc
. $DIR_UTIL/load_nco
. $DIR_UTIL/load_cdo
. $DIR_UTIL/load_ncl
module load intel-2021.6.0/cdo-threadsafe/2.1.1-lyjsw
set -euvx

export lasty=$1
export nmaxens=$2
export st=$3
export dirplots=$4
export varm=$5
ftype=$6
export dirdiag=$7
export region=$8
#export latitude1=0
#export latitude2=360
#export lingitude1=-90
#export longitude2=90
mkdir -p $dirplots
export pltype=png

# climatologies computed on Zeus /users_home/csp/as34319/diagnostics/hindcast_diags/make_clim_refperiod.sh
diro=/work/csp/$USER/diagnostics/SPS4_hindcast/OBS/VALIDATION/
mod=SPS4
export iniy=$iniy_hind
case $st
 in
 01)  export mon="January" ;; 
 02)  export mon="February" ;;
 03)  export mon="March" ;;
 04)  export mon="April" ;;
 05)  export mon="May" ;;
 06)  export mon="June" ;;
 07)  export mon="July" ;;
 08)  export mon="August" ;;
 09)  export mon="September" ;;
 10)  export mon="October" ;;
 11)  export mon="November" ;;
 12)  export mon="December" ;;
esac

case $varm
 in
 TREFHT) export varo="var167" 
      var=t2m
      diro=$diro/ERA5/$var ;;
 PRECT) export varo="precip"  
        var=$varo
         diro=$diro/GPCP/$var;;
 PSL)   export varo="var151"  
        var=mslp
         diro=$diro/ERA5/$var;;
esac
case $mod
 in
   SPS4) dirm=$dirdiag/$st/$varm/ANOM;;
   SPS3) dirm=$WORK/$mod/CESM/monthly/$dirvarm/anom/ ;;
esac

#

targetgridC3S=dstGrd_reg1x1.txt
for l in 0 1 2 3
do
   export inputm=$dirm/cam.$ftype.$st.${varm}.all_anom.${iniy_hind}-${lasty}.$nmaxens.nc
   export inputo=$diro/${var}_${st}_all_ano.${iniy_hind}-2016.nc
   if [[ ! -f $inputo ]]
   then
      for yyyy in `seq $iniy_hind 2016`
      do 
         listaf+=" $diro/${var}_${yyyy}${st}_ano.$iniy_hind-2016.nc"
      done
      ncecat $listaf $inputo
   fi
   export leadtime=$l
   export plname=$dirplots/${mod}_ACC_${region}_${varm}_${st}_l${l}.$nmaxens.$iniy-$lasty.png
#   ncl SPS_acc_regional_newproj.ncl 
   ncl SPS_acc.ncl 

#   convert_opt="-trim +repage"
#   convert ${convert_opt} $plname ${plname}_tmp
#   mv ${plname}_tmp $plname
done
