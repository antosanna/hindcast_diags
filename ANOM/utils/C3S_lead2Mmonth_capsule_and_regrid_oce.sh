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
export datamm=$4
workdir=$5
export var=$6
version=$7
here=$8
export filetype=$9

# CurrentDir
cdir="/users_home/csp/`whoami`/SPS/CMCC-SPS_SKILL_SCORES/ANOM"

# Create Dirs
mkdir -p $datamm
[ -d $workdir ] && rm -rf $workdir
mkdir -p $workdir
cd $workdir

# Variables cases

fc="${yy}${st}"  
export datadir="/data/csp/sp1/ocnSPS3.5"


#CHECK if the files was already produced
export finaloutput=${var}_SPS3.5_sps_${yy}${st}
if [ ! -f $datamm/$finaloutput.nc ] ; then
  
	sps="sps3.5_${yy}${st}_${ppp}"
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
        if [ ! -f $SCRATCHDIR/ANDREA/ORCA_SCRIP_gridT.nc ] ; then
           cp $REPOSITORY/ORCA_SCRIP_gridT.nc $SCRATCHDIR/ANDREA
        fi
        export srcGridName="$SCRATCHDIR/ANDREA/ORCA_SCRIP_gridT.nc"
        if [ ! -f $SCRATCHDIR/ANDREA/World1deg_SCRIP_gridT.nc ] ; then
           cp $REPOSITORY/World1deg_SCRIP_gridT.nc $SCRATCHDIR/ANDREA
        fi
	export dstGridName="$SCRATCHDIR/ANDREA/World1deg_SCRIP_gridT.nc"
 	if [ ! -f $SCRATCHDIR/ANDREA/ORCA_2_World_SCRIP_gridT.nc ] ; then
           cp $REPOSITORY/ORCA_2_World_SCRIP_gridT.nc $SCRATCHDIR/ANDREA
        fi
	export wgtFile="$SCRATCHDIR/ANDREA/ORCA_2_World_SCRIP_gridT.nc"
	export finalinputfile=${tfile}
	export filo=$datamm/${sps}_${var}.zip.nc
	export checkfile=$datamm/${sps}_${var}_OK
		
	ncl $here/C3S_lead2Mmonth_capsule_and_regrid_oce.ncl
       
 	#if [ $var = "votemper" -o $var = "sohtc040" ] ; then
	#   cdo settaxis,$yy-$st-01,12:00:00,1day $filo ${filo}_tmp
  	#   cdo setreftime,$yy-$st-01,12:00:00 ${filo}_tmp $filo
	#   rm ${filo}_tmp
	#fi
fi
touch $here/logs/capsule_${yy}${st}_${ppp}_oce_${var}_DONE
