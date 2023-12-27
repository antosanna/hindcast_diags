#!/bin/sh -l

. ~/.bashrc
. ~/.bashrc_skill_scores
. ${DIR_SPS35}/descr_SPS3.5.sh
. ${DIR_ROOT_SCORES}/descr_SKILL_SCORES.sh
. ${DIR_TEMPL}/load_cdo

set -euvx

yy=$1
st=$2
datamm=$3
workdir=$4
varobs=$5

case $varobs
 in
 t2m)    var=var167 ;;
 mslp)   var=var151 ;;
 precip) var=precip ;;
 evap)   var=var182 ;;
 z500)   var=var129 ;;
 t850)   var=var130 ;;
 u200)   var=var131 ; lev=20000 ;;
 u850)   var=var131 ; lev=85000 ;;
 v850)   var=var132 ; lev=85000 ;;
 u925)   var=var131 ; lev=92500 ;;
 v925)   var=var132 ; lev=92500 ;;
 v200)   var=var132 ; lev=20000 ;;
 sst)    var=var34 ;;
 ssh)    var=zos   ;;
 snwdpt) var=sd    ;;
 mrlsl)  var=var39 ;;
esac
 


mkdir -p $datamm
mkdir -p $workdir

scriptsdir=${DIR_ROOT_SCORES}/ANOM/OBS

cd $workdir

cp ${DIR_ROOT_SCORES}/static/C3Sgrid.txt .

nm=1
nmf=6
mm=${st}
#st2=$st
year=$yy

if [ ! -f $datamm/${varobs}_${yy}${st}.nc ] ; then
	while [ $nm -le $nmf ] ; do
		#[ $mm -gt 12 ] && { mm="1" ; year=$(($year + 1)) ; }

		#mm2=${mm}
                    
		case $varobs
		 in
		 t2m) cdo -f nc copy -remapbil,C3Sgrid.txt -timmean -selvar,${var} /work/csp/sp1/CMCC-SPS3.5/WORK_INST_ERA5/era5_inst_${year}${mm}.grib ${varobs}_${yy}${st}_${nm}.nc ;;
   mslp) cdo -f nc copy -remapbil,C3Sgrid.txt -timmean ${DATA_ECACCESS}/ERA5/6hourly/${varobs}/${varobs}_era5_inst_${year}${mm}01.grib ${varobs}_${yy}${st}_${nm}.nc ;;
		 z500) cdo -f nc copy -remapbil,C3Sgrid.txt -timmean -divc,9.8081 -selvar,${var} ${DATA_ECACCESS}/ERA5/6hourly/${varobs}/${varobs}_era5_inst_${year}${mm}01.grib ${varobs}_${yy}${st}_${nm}.nc ;;
		 t850) cdo -f nc copy -remapbil,C3Sgrid.txt -timmean -selvar,${var} ${DATA_ECACCESS}/ERA5/6hourly/${varobs}/${varobs}_era5_inst_${year}${mm}01.grib ${varobs}_${yy}${st}_${nm}.nc ;;
		 u925|u850|u200) cdo remapbil,C3Sgrid.txt -selvar,${var} -sellevel,${lev} ${DATA_ECACCESS}/ERA5/monthly/ua/ua_era5_${year}${mm}.nc ${varobs}_${yy}${st}_${nm}.nc ;;
		 v925|v850|v200) cdo remapbil,C3Sgrid.txt -selvar,${var} -sellevel,${lev} ${DATA_ECACCESS}/ERA5/monthly/va/va_era5_${year}${mm}.nc ${varobs}_${yy}${st}_${nm}.nc ;;
		 precip) cdo -remapbil,C3Sgrid.txt -selmon,$mm -selyear,$year ${CLIM_OBS_DIR_DIAG}/$varobs/${varobs}.199301-202212.nc ${varobs}_${yy}${st}_${nm}.nc ;;
   evap)   cdo -f nc copy -remapbil,C3Sgrid.txt -selmon,$mm -selyear,$year ${CLIM_OBS_DIR_DIAG}/$varobs/${varobs}_1993-2016.grib ${varobs}_${yy}${st}_${nm}.nc ;;
   sst) cdo -f nc copy -remapbil,C3Sgrid.txt -timmean -setrtoc,200,271.5,271.5 -setmissval,1e+20 -selvar,${var} ${DATA_ECACCESS}/ERA5/6hourly/${varobs}/${varobs}_era5_inst_${year}${mm}01.grib ${varobs}_${yy}${st}_${nm}.nc ;; 
   ssh) cdo remapbil,C3Sgrid.txt -selmon,$mm -selyear,$year ${CLIM_OBS_DIR_DIAG}/$varobs/global-reanalysis-${var}-monthly_199301-201705.nc ${varobs}_${yy}${st}_${nm}.nc ;;
   mrlsl) cdo -f nc copy -remapbil,C3Sgrid.txt -selvar,${var} ${DATA_ECACCESS}/ERA5/monthly/swvl/swvl_era5_${year}${mm}.grib ${varobs}_${yy}${st}_${nm}.nc ;; 
   snwdpt) cdo -f nc copy -remapbil,C3Sgrid.txt -selvar,${var} -selmon,$mm -selyear,$year ${CLIM_OBS_DIR_DIAG}/$varobs/${varobs}_ERA5_land_1993-2017.grib ${varobs}_${yy}${st}_${nm}.nc ;;
		esac

		cdo cat ${varobs}_${yy}${st}_${nm}.nc ${varobs}_${yy}${st}.nc
		rm ${varobs}_${yy}${st}_${nm}.nc

              
		year=`date -d "${year}${mm}01+1 month" +%Y`
		mm=`date -d "${year}${mm}01+1 month" +%m`
		nm=$(($nm + 1))
	done

	cdo settaxis,${yy}-${st}-15,12:00,1mon ${varobs}_${yy}${st}.nc temp_${yy}${st}
	cdo setreftime,${yy}-${st}-15,12:00 temp_${yy}${st} ${varobs}_${yy}${st}.nc
	rm temp_${yy}${st}

	mv ${varobs}_${yy}${st}.nc $datamm

fi
exit 0
