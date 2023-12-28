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

export lasty=1999
export nmaxens=15
export st=07
export region=global
export titreg="nonna"
export latitude1=0
export latitude2=360
export lingitude1=-90
export longitude2=90
export var="precip"
ftype=h3
export dirplots=$PWD
export dirdiag=/work/csp/as34319/diagnostics/SPS4_hindcast
mkdir -p $dirplots
export pltype=png

diro=/work/csp/as34319/diagnostics/SPS4_hindcast/OBS/VALIDATION/
export mod=SPS4
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

case $var
 in
 u850) export varo="var131" 
      case $mod 
       in
       SPS4) export varmstr="U850" ; dirvarm=$varmstr ; varm=$varmstr ;;
       SPS3.5) export varmstr="ua" ; dirvarm=$var ; varm=$var ;;
      esac ;;
 u200) export varo="var131" 
      case $mod 
       in
       SPS4) export varmstr="U200" ; dirvarm=$varmstr ; varm=$varmstr ;;
       SPS3.5) export varmstr="ua" ; dirvarm=$var ; varm=$var ;;
      esac ;;
 v200) export varo="var132" 
      case $mod 
       in
       SPS4) export varmstr="V200" ; dirvarm=$varmstr ; varm=$varmstr ;;
       SPS3.5) export varmstr="va" ; dirvarm=$var ; varm=$var ;;
      esac ;;
 t850) export varo="var130" 
      case $mod 
       in
       SPS4) export varmstr="T850" ; dirvarm=$varmstr ; varm=$varmstr ;;
       SPS3.5) export varmstr="ta" ; dirvarm=$var ; varm=$var ;;
      esac ;;
 z500) export varo="var129" 
      case $mod 
       in
       SPS4) export varmstr="Z500" ; dirvarm=$varmstr ; varm=$varmstr ;;
       SPS3.5) export varmstr="zg" ; dirvarm=$var ; varm=$var ;;
      esac ;;
 t2m) export varo="var167" 
      case $mod 
       in
       SPS4) export varmstr="TREFHT" ; diro=$diro/ERA5/$var ;dirvarm=$varmstr ; varm=$varmstr ;;
       SPS3.5) export varmstr="tas" ; dirvarm=$var ; varm=$var ;;
      esac ;;
 sst) export varo="var34"   #varo="sst" 
      case $mod 
       in
       SPS4) export varmstr="TS" ; dirvarm=$varmstr ; varm=$varmstr ;;
       SPS3.5) export varmstr="tso" ; dirvarm=$var ; varm=$var ;;
      esac ;;

 precip) export varo="precip"  
         diro=$diro/GPCP/$varo
         case $mod
          in
          SPS4) export varmstr="PRECT" ; dirvarm="PRECT" ; varm=$varmstr ;;
       	  SPS3.5) export varmstr="lwepr" ; dirvarm=$var ; varm=$var ;;
         esac ;;
 mslp)   export varo="var151"  
         case $mod
          in
          SPS4) export varmstr="PSL" ; dirvarm="MSLP" ; varm=$varmstr ;;
	         SPS3.5) export varmstr="psl" ; dirvarm=$var ; varm=$var ;;
         esac ;;
 mrlsl)  export varo="var39"  
         case $mod
          in
          SPS4) export varmstr="mrlsl" ; dirvarm="mrlsl" ; varm=$varmstr ;;
	         SPS3.5) export varmstr="mrlsl" ; dirvarm=$var ; varm=$var ;;
         esac ;;
esac
case $mod
 in
   SPS4) dirm=$dirdiag/$varm/ANOM;;
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
   export plname=$dirplots/${mod}_ACC_${region}_${var}_${st}_l${l}.png
#   ncl SPS_acc_regional_newproj.ncl 
   ncl SPS_acc.ncl 
exit

   convert_opt="-trim +repage"
   convert ${convert_opt} $plname ${plname}_tmp
   mv ${plname}_tmp $plname
done
