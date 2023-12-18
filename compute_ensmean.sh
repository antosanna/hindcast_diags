#!/bin/sh -l

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
. $DIR_UTIL/load_cdo
set -euxv
# SECTION TO BE MODIFIED BY USER
debug=0
nmaxens=$1
var=$2
st=$3
echo 'NOW MAX ENSEMBLE SET TO '$nmaxens
export inpdirroot=/work/csp/$utente/$model/archive/
         
mkdir -p $dirdiag/$var
cd $dirdiag/$var
for yyyy in `seq $iniy_hind $endy_hind`
do
		if [[ ! -f $dirdiag/$var/cam.$ftype.$yyyy$st.$var.tmp.nc ]]
		then
					nens=0
					inpfilelist=" "
					for ens in `seq -f "%03g" 1 $nrunmax`
					do
								caso=${SPSSystem}_${yyyy}${st}_${ens}
								inpfile=$DIR_ARCHIVE1/$caso/$comp/hist/$caso.cam.$ftype.$yyyy-$st-01-00000.nc
								if [[ ! -f $inpfile ]]
								then 
											continue
								fi
								inpfilevar=$dirdiag/$var/$caso.cam.$ftype.$var.$yyyy-$st-01-00000.nc
								if [[ ! -f $inpfilevar ]]
								then 
   								cdo selvar,$var $inpfile $inpfilevar
        fi
								inpfilelist+=" $inpfilevar"
								nens=$(($nens + 1))
								if [[ $nens -eq $nmaxens ]]
								then
											if [[ ! -f $dirdiag/$var/cam.$ftype.$var.$yyyy$st.monmean.$nmaxens.nc ]]
											then
														cdo ensmean $inpfilelist $dirdiag/$var/cam.$ftype.$yyyy$st.$var.tmp.nc
														cdo -O monmean $dirdiag/$var/cam.$ftype.$yyyy$st.$var.tmp.nc $dirdiag/$var/cam.$ftype.$var.$yyyy$st.monmean.$nmaxens.nc
														rm $inpfilelist $dirdiag/$var/cam.$ftype.$yyyy$st.$var.tmp.nc
											fi
											lasty=$yyyy
											break
								fi
					done #loop on ens
			else
					lasty=$yyyy
		fi
done #loop on years
if [[ ! -f $dirdiag/$var/cam.$ftype.$var.$st.monmean.$nmaxens.1993-$lasty.nc ]]
then
		cdo mergetime $dirdiag/$var/cam.$ftype.$var.????${st}.monmean.$nmaxens.nc $dirdiag/$var/cam.$ftype.$var.$st.monmean.$nmaxens.1993-$lasty.nc
fi
if [[ ! -f $dirdiag/$var/$var.cam.$ftype.$st.ymonmean.$nmaxens.1993-$lasty.nc ]]
then
		cdo seltimestep,1/6 -ymonmean $dirdiag/$var/cam.$ftype.$var.$st.monmean.$nmaxens.$iniy_hind-$lasty.nc $dirdiag/$var/$var.cam.$ftype.$st.ymonmean.$nmaxens.1993-$lasty.nc
fi
