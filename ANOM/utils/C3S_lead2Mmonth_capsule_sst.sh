#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -euvx

# Inputs
yy=$1
st=$2
nrun=$3
datamm=$4
workdir=$5
var=$6
#freq=$7
version=$7
here=$8


# CurrentDir
cdir="/users_home/csp/`whoami`/SPS/CMCC-SPS_SKILL_SCORES/ANOM"

# Create Dirs
mkdir -p $datamm
[ -d $workdir ] && rm -rf $workdir
mkdir -p $workdir
cd $workdir

# Variables cases
case $var
in
	t2m)     varC3S=tas   ; option="-subc,273.15"       ; hour="00:00:00" ; incr="6hour";;
	sst)     varC3S=tso   ; option=""                   ; hour="00:00:00" ; incr="day";;
	precip)  varC3S=lwepr ; option="-mulc,1000"         ; hour="12:00:00" ; incr="day";;
	mslp)    varC3S=psl   ; option="-divc,100"          ; hour="00:00:00" ; incr="6hour";;
	z500)    varC3S=zg    ; option="-sellevel,50000"   ; hour="00:00:00" ; incr="12hour";;
	t850)    varC3S=ta    ; option="-sellevel,85000"   ; hour="00:00:00" ; incr="12hour";;
esac

fc="${yy}${st}"  
datadir="/data/products/C3S/CMCC-SPS3.5/daily/${fc}"

#CHECK if the files was already produced
flist=`ls -1 $datadir/*${varC3S}_*.nc | head -n $nrun`
for ff in $flist ; do
  
        pp=`basename $ff | cut -d '_' -f9 | cut -d '.' -f1 | cut -c2-3`
	ppp=`printf "%03d" $(( 10#${pp} ))`
	sps="sps_${yy}${st}_${ppp}"
        finaloutput=${var}_SPS3.5_${sps}.nc
	outputfile="${var}_${sps}.output.1.nc"  	#python_fst_output
	intoutput="${var}_${sps}.output.2.nc"		#cdo intermediate output

	if [ ! -f $datamm/$finaloutput ] ; then
		# GET Data
		#rsync -auv $datadir/*${varC3S}_*r${pp}i00p00.nc .
  
		#tfile=`ls -1 cmcc_CMCC-CM2-v${version}_*_S${yy}${st}0100_*_${varC3S}_r${pp}i00p00.nc`
		cd $datadir
		tfile=`ls -1 cmcc_CMCC-CM2-v*_*_S${yy}${st}0100_*_${varC3S}_r${pp}i00p00.nc`
		cd -
		ppp=`printf "%03d" $(( 10#${pp} ))` 
		sps="sps_${yy}${st}_${ppp}"

		# declaring and final outputfile
		finalinputfile=${tfile}
		finaloutput=${var}_SPS3.5_${sps}.nc

		ncks -O -6 $datadir/${finalinputfile} ${finalinputfile}_tmp.nc
		cdo settaxis,$yy-$st-01,$hour,$incr ${finalinputfile}_tmp.nc ${finalinputfile}_tmp2.nc
		cdo setreftime,$yy-$st-01,$hour ${finalinputfile}_tmp2.nc ${finalinputfile}_tmp3.nc
		#Decide to do mean or sum if precipitation
		case $varC3S
		 in
		 lweprsn) stat="monsum" ;;
		 *)     stat="monmean" ;;
		esac
		cdo $stat $option ${finalinputfile}_tmp3.nc ${outputfile}

		# set output of python in months
		cdo settunits,months ${outputfile} ${intoutput} 
		# set calendar to C3S standard
		cdo setcalendar,365_day ${intoutput} ${finaloutput} 
		# clean intermediate files
		rm ${finalinputfile}_tmp*.nc
		rm ${outputfile} && rm ${intoutput} 
	
		mv ${var}_SPS3.5_${sps}.nc $datamm
	else
		continue	
	fi
	
done  #end loop on plist

touch $here/logs/capsule_${yy}${st}_${var}_DONE
