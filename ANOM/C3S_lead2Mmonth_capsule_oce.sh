#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -euvx

mymail=andrea.borrelli@cmcc.it

# Inputs
export yy=$1
export st=$2
export ppp=$3
datamm=$4
workdir=$5
export var=$6
version=$7
scriptsdir=$8
export filetype=$9
export SPSsystem

# CurrentDir
cdir=$scriptsdir

# Create Dirs
mkdir -p $datamm
[ -d $workdir ] && rm -rf $workdir
mkdir -p $workdir
cd $workdir

# Variables cases

fc="${yy}${st}"  


#CHECK if the files was already produced
export finaloutput=${var}_${SPSSYS}_sps_${yy}${st}
if [ ! -f $datamm/$finaloutput.nc ] ; then
  
 	sps="${SPSsystem}_${yy}${st}_${ppp}"
	case $st
	 in
	 08|10|11|12) export datadir="/data/csp/sp1/ocn${SPSSYS}" ;;
           02) export datadir="/data/csp/sp1/archive/CESM/${SPSSYS}_cineca" ;;
  	         *) export datadir="/data/csp/sp1/archive/CESM/${SPSSYS}" ;;
	esac
        set +e
        nf=`ls -1 $datadir/${sps}/ocn/hist/${sps}_1d_*_*_grid_T_EquT.zip.nc | wc -l`
        set -e
        if [ $nf -eq 0 ] ; then
	   datadir="/work/csp/sp1/archive_${SPSSYS}"
           nf2=`ls -1 $datadir/${sps}/ocn/hist/${sps}_1d_*_*_grid_T_EquT.zip.nc | wc -l`
           if [ $nf2 -eq 0 ] ; then
		datadir="/work/csp/sp1/CESM/archive"
	   fi
        fi
	tfileTEquT="$datadir/${sps}/ocn/hist/${sps}_1d_*_*_grid_T_EquT.zip.nc"
	tfileTglobal="$datadir/${sps}/ocn/hist/${sps}_1d_*_*_grid_Tglobal.zip.nc"
	tfileT="$datadir/${sps}/ocn/hist/${sps}_1m_*_*_grid_T.zip.nc"
	tfileU="$datadir/${sps}/ocn/hist/${sps}_1m_*_*_grid_U.zip.nc"
	tfileV="$datadir/${sps}/ocn/hist/${sps}_1m_*_*_grid_V.zip.nc"

	case $var
	 in
	 votemper)  tfile=`ls -1 $tfileTEquT` ;;
	 sohtc040)  tfile=`ls -1 $tfileTglobal` ;;
	 somixhgt)  tfile=`ls -1 $tfileT` ;;
	 vozocrtx)  tfile=`ls -1 $tfileU` ;;	
	 vomecrty)  tfile=`ls -1 $tfileV` ;;	
	esac
	# declaring and final outputfile
	export meshmaskfile="$REPOSITORY/mesh_mask_from2000.nc"
	export finalinputfile=${tfile}
	export filo=$datamm/${sps}_${var}.zip.nc
	export checkfile=$datamm/${sps}_${var}_OK
		
	ncl $scriptsdir/C3S_lead2Mmonth_capsule_oce.ncl
       
 	if [ $var = "votemper" -o $var = "sohtc040" ] ; then
	   cdo settaxis,$yy-$st-01,12:00:00,1day $filo ${filo}_tmp
  	   cdo setreftime,$yy-$st-01,12:00:00 ${filo}_tmp $filo
	   rm ${filo}_tmp
	fi
fi
rm -rf $workdir
touch $scriptsdir/logs/capsule_${yy}${st}_${ppp}_oce_${var}_DONE
