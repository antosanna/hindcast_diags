#!/bin/sh -l
#BSUB -P 0287
#BSUB -q s_short
#BSUB -J preproc_u_v
#BSUB -o logs/preproc_u_v_%J.out
#BSUB -e logs/preproc_u_v_%J.err
#BSUB -N
#BSUB -u andrea.borrelli@cmcc.it

. $HOME/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -euvx

DIR="/data/delivery/csp/ecaccess/ERA5/monthly"

yyi=2017
yyf=2017

varlist="u850 u200 v200"

for yyyy in `seq $yyi $yyf` ; do
   for mm in `seq -w 01 05` ; do
       for var in $varlist ; do
			         
						     case $var
            in
            u850) vardir=u ; lev=85000 ;;
            u200) vardir=u ; lev=20000 ;;
					       v200) vardir=v ; lev=20000 ;;
										 esac
           varname=$vardir
           
           cdo sellevel,$lev $DIR/$vardir/${varname}_era5_${yyyy}${mm}.grib $DIR/$vardir/${var}_era5_${yyyy}${mm}.grib
           
       done
   done
done
