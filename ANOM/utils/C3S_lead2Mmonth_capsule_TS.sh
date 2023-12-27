#!/bin/sh -l 

. ~/.bashrc
. $DIR_SPS3/descr_run_ICs.sh

set -evx

# Inputs
yy=$1
st=$2
nrun=$3
datamm=$4
workdir=$5
var=$6
freq=$7

outputfile="output.1_${yy}${st}.nc"  	#python_fst_output
intoutput="output.2_${yy}${st}.nc"		#cdo intermediate output

# check for CONDA ENVIRONMENT
isCMOR_5loaded="`echo $CONDA_DEFAULT_ENV`"
if [[ $isCMOR_5loaded  = "CMOR_5" ]]
then
  echo "CMOR_5 is UP, nothing to do" 
  CMOR_5flag=0
else
  echo "CMOR_5 is DOWN, activating it"
  source activate CMOR_5
  CMOR_5flag=1
fi
# Python CurrentDir
cdir="/users_home/csp/sp2/SPS/CMCC-SPS_SKILL_SCORES/ANOM"

# change time-axis function definition ---------------------------------------------------------------------------------------------

# function to setaxis and to setreftime
fixtimedd() {
  local yy=$1
  local mm=$2
  local dd=$3
  local hh=$4
  local incr=$5
  local infile=$6
  incr2=1
  outfile=${infile}

  cdo settaxis,${yy}-${mm}-${dd},${hh}:00,${incr} ${infile} temp_${yy}${mm}
  cdo setreftime,${yy}-${mm}-${dd},${hh}:00 temp_${yy}${mm} ${outfile}
  rm temp_${yy}${mm}
}

# function to setaxis and to setreftime (python version - 7 times faster)
fixtimedd2() {
  local yy=$1
  local mm=$2
  local dd=$3
  local hh=$4
  local incr=$5
  local infile=$6

  outfile=${infile}
  # export python log vars in order to catch from python
  export PYLOG=$DIR_REP
  # best practice (netcdf4 bug) input and  output files must have a shortest possible name
  shortinfile=tin_${yy}${mm}.nc
  shortoutfile=temp_${yy}${mm}
  ln -sf ${infile} ${shortinfile}
  isCMOR_5loaded="`echo $CONDA_DEFAULT_ENV`"
  python $cdir/C3S_lead2time.py -i ${shortinfile} -o ${shortoutfile} -ens $ppp
  unlink ${shortinfile}
  mv ${shortoutfile} ${outfile}
}

# -----------------------------------------------------------------------------------------------


# Create Dirs
mkdir -p $datamm
#[ -d $workdir ] && rm -rf $workdir
mkdir -p $workdir
cd $workdir

# Variables cases
case $var
in
	TREFHT) varC3S=tas ; option="-subc,273.15" ;;
	TS)     varC3S=tso ; option="" ;;
	PREC)   varC3S=lwepr ; option="" ;;
	PSL)    varC3S=psl ; option="-mulc,0.01" ;;
	Z500)   varC3S=zg ; option="-sellevel,50000" ;;
	T850)   varC3S=ta ; option="-subc,273.15 -sellevel,85000" ;;
esac
fc="${yy}${st}"  
datadir="/work/csp/sp1/CESM/archive/C3S/$fc"  
# GET Data
rsync -auv $datadir/*${varC3S}_*.nc .
# the two lines above will be substituted by the following
#datadir=/work/sp1/CESM/C3S_standard/output/work_${yy}${st}/

plist=`ls -1 *${varC3S}_*r*i00p00* | cut -d '_' -f9 | cut -d '.' -f1 | cut -c2-3`

for pp in $plist 
do
        case $varC3S
         in  
         tas)   freqout="6hr"   ; type="atmos" ; hh=00 ; incr="6hour" ; varnew=t2m   ;;  
         psl)   freqout="6hr"   ; type="atmos" ; hh=00 ; incr="6hour" ; varnew=mslp   ;;  
         tso)   freqout="6hr"   ; type="ocean" ; hh=00 ; incr="6hour" ; varnew=sst    ;;  
         lwepr) freqout="day"   ; type="atmos" ; hh=00 ; incr="1day"   ; varnew=precip ;;
         zg)    freqout="12hour" ; type="atmos" ; hh=00 ; incr="12hour" ; varnew=hgt500 ;;
         ta)    freqout="12hour" ; type="atmos" ; hh=00 ; incr="12hour" ; varnew=t850  ;;
        esac
        isCMOR_5loaded="`echo $CONDA_DEFAULT_ENV`"

	tfile=`ls -1 cmcc_CMCC-CM2-v20191201_*_S${yy}${st}0100_*_${varC3S}_r${pp}i00p00.nc`
	ppp=`printf "%03d" $(( 10#${pp} ))`  #`printf "%.03d" ${pp}`
	sps="sps_${yy}${st}_${ppp}"

	# decalring python input and final outputfile
	finalinputfile=${tfile}
	finaloutput=${var}_SPS3_${sps}.nc

        fixtimedd2 $yy $st 01 ${hh} ${incr} ${finalinputfile}
        if [ $varC3S = "tso" ] ; then
           ncatted -O -a grid_mapping,$varC3s,d,, ${finalinputfile} cio_${yy}${st}.nc
           cdo setmissval,1.e+20 cio_${yy}${st}.nc cio_${yy}${st}_setmissval.nc
           cdo monmean $option cio_${yy}${st}_setmissval.nc  ${outputfile}
           rm cio_${yy}${st}*
        elif [ $varC3S = "zg" ] || [ $varC3S = "ta" ] ; then
           ncwa -a plev ${finalinputfile} ${outputfile}_tmp
           ncks -O -x -v plev ${outputfile}_tmp ${outputfile}
           rm ${outputfile}_tmp
        else
           cdo monmean $option ${finalinputfile} ${outputfile}
        fi
        ncrename -O -v $varC3S,$var ${outputfile}

	# set output of python in months
	cdo settunits,months ${outputfile} ${intoutput} 
	# set calendar to C3S standard
	cdo setcalendar,365_day ${intoutput} ${finaloutput} 
	# clean intermediate files
	rm ${outputfile} && rm ${intoutput} 
	
	# End of Python Section ######################################################
	mv ${var}_SPS3_${sps}.nc $datamm
	
done  #end loop on plist

#Deactivate Python Environment
source deactivate

