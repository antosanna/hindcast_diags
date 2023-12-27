#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh

set -euvx

yy=$1
st=$2
datamm=$3
workdir=$4
varobs=$5

case $varobs
 in
 t2m)    var=var167 ;;
 mslp)   var=var134 ;;
 precip) var=precip ;;
 z500)   var=var129 ;;
 t850)   var=var130 ;;
 sst)    var=sst ;;
esac
 


mkdir -p $datamm
mkdir -p $workdir

HERE=`pwd`

cd $workdir

cp $HERE/../C3Sgrid.txt .

nm=1
nmf=6
mm=${st}
st2=`printf "%.2d" $(( 10#$mm ))`
year=$yy

if [ ! -f $datamm/${varobs}_${yy}${st2}.nc ] ; then
	while [ $nm -le $nmf ] ; do
		[ $mm -gt 12 ] && { mm="1" ; year=$(($year + 1)) ; }

		mm2=`printf "%.2d" $(( 10#$mm ))`
                    
		case $varobs
		 in
		 t2m|mslp) cdo -f nc copy -remapbil,C3Sgrid.txt -timmean -selvar,${var} /work/csp/sp1/CMCC-SPS3.5/WORK_INST_ERA5/era5_inst_${year}${mm2}.grib ${varobs}_${yy}${st}_${nm}.nc ;;
		 precip) cdo -remapbil,C3Sgrid.txt -selmon,$mm2 -selyear,$year /work/csp/sp2/VALIDATION/monthly/$varobs/${varobs}.mon.mean.nc ${varobs}_${yy}${st}_${nm}.nc ;;
		 z500) cdo remapbil,C3Sgrid.txt -selmon,$mm2 -selyear,$year -divc,9.8081 -selvar,${var} /data/delivery/csp/ecaccess/ERAI/monthly/${varobs}_erai_199301-201712_mm.nc ${varobs}_${yy}${st}_${nm}.nc ;;
		 t850) cdo -f nc copy -remapbil,C3Sgrid.txt -timmean -selvar,${var} /data/delivery/csp/ecaccess/ERA5/VALIDATION/${varobs}_era5_inst_${year}${mm2}01.grib ${varobs}_${yy}${st}_${nm}.nc ;;
                 sst) cdo setmissval,-1000. -selmon,$mm2 -selyear,$year -selvar,sst /work/csp/sp2/VALIDATION/monthly/sst/sst_HadISST_198001-201712_mm.nc ${varobs}_${yy}${st}_${nm}.nc ;; 

		esac

		cdo cat ${varobs}_${yy}${st}_${nm}.nc ${varobs}_${yy}${st2}.nc
		rm ${varobs}_${yy}${st}_${nm}.nc

              
		mm=$(($mm + 1))
		nm=$(($nm + 1))
	done

	cdo settaxis,${yy}-${st2}-15,12:00,1mon ${varobs}_${yy}${st2}.nc temp_${yy}${st2}
	cdo setreftime,${yy}-${st2}-15,12:00 temp_${yy}${st2} ${varobs}_${yy}${st2}.nc
	rm temp_${yy}${st2}

	mv ${varobs}_${yy}${st2}.nc $datamm

fi
exit 0
