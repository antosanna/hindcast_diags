#!/bin/sh
#BSUB -J T_capsule_lead
#BSUB -o TEST_SPS3_assembler_%J.out  # Appends std output to file %J.out.
#BSUB -e TEST_SPS3_assembler_%J.err  # Appends std error to file %J.err.
#BSUB -q serial_6h       # queue
#BSUB -n 4    

. $HOME/.bashrc

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
isCMOR_4loaded="`echo $CONDA_DEFAULT_ENV`"
if [[ $isCMOR_4loaded  = "CMOR_4" ]]
then
  echo "CMOR_4 is UP, nothing to do" 
  CMOR_4flag=0
else
  echo "CMOR_4 is DOWN, activating it"
  source activate CMOR_4
  CMOR_4flag=1
fi
# Python CurrentDir
cdir="/users/home/sp2/SPS3/postproc/SeasonalForecast/FORECAST"

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
  isCMOR_4loaded="`echo $CONDA_DEFAULT_ENV`"
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
fc="sps_${yy}${st}"  
case $st
 in
#OLD DIRECTORY /ARCHIVE 
 01|02|03) datadir="/archive/sp1/CESM/archive/$fc/C3S_standard" ;; 
#TEMPORARY /ARCHIVE --> /tier2
 *) datadir="login2-ib:/tier2/CSP/sp1/CESM/archive/$fc/C3S_standard" ;;
#TEMPORARY /ARCHIVE --> /$HOME/NO_backup/archive_tmp
#datadir="/users/home/sp1/NO_backup/archive_tmp/$fc/C3S_standard"
esac
# GET Data
rsync -auv $datadir/*${varC3S}_*.tar .
# the two lines above will be substituted by the following
#datadir=/work/sp1/CESM/C3S_standard/output/work_${yy}${st}/
tarfilelist=`ls -1 *S${yy}${st}0100*${varC3S}_*.tar`
for tarfile in $tarfilelist ; do
   tar -xvf $tarfile 
   rm *S${yy}${st}0100*${varC3S}_*.sha256
#**********************************
# THIS WON'T BE REMOVED!!!!!!!!! consider the opportunity to leave *.nc files in tar_and_push.sh
#**********************************
   rm $tarfile
done

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
        isCMOR_4loaded="`echo $CONDA_DEFAULT_ENV`"

	tfile=`ls -1 cmcc_CMCC-CM2-v20160423_*_S${yy}${st}0100_*_${varC3S}_r${pp}i00p00.nc`
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

