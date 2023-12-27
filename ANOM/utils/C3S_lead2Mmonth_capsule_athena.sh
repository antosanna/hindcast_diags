#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_SPS3}/descr_run_ICs.sh

set -evx

# Inputs
yy=$1
st=$2
nrun=$3
datamm=$4
workdir=$5
var=$6
freq=$7

outputfile="output.1.nc"  	#python_fst_output
intoutput="output.2.nc"		#cdo intermediate output

# Python CurrentDir
cdir="/users_home/csp/sp2/SPS/CMCC-SPS_SKILL_SCORES/ANOM"
pythoncommand=${cdir}/C3S_lead2Mmonth.py

# Create Dirs
mkdir -p $datamm
[ -d $workdir ] && rm -rf $workdir
mkdir -p $workdir
cd $workdir

# Variables cases
case $var
in
	TREFHT) varC3S=tas ; option="" ;;
	TS)     varC3S=tso ; option="" ;;
	PREC)   varC3S=lwepr ; option="" ;;
	PSL)    varC3S=psl ; option="" ;;
	Z500)   varC3S=zg ; option="-plev 50000.0" ;;
	T850)   varC3S=ta ; option="-plev 85000.0" ;;
esac
fc="${yy}${st}"  
datadir="/work/csp/sp1/CESM/archive/C3S/${fc}"


# GET Data
rsync -auv $datadir/*${varC3S}_*.nc .
# the two lines above will be substituted by the following
#datadir=/work/sp1/CESM/C3S_standard/output/work_${yy}${st}/

plist=`ls -1 *${varC3S}_*r*i00p00* | cut -d '_' -f9 | cut -d '.' -f1 | cut -c2-3`

#Activate Python Environment (must be called by sp2/sp1)
#source activate PYNIO
source activate CMOR_4

for pp in $plist 
do
	tfile=`ls -1 cmcc_CMCC-CM2-v20191201_*_S${yy}${st}0100_*_${varC3S}_r${pp}i00p00.nc`
	ppp=`printf "%03d" $(( 10#${pp} ))`  #`printf "%.03d" ${pp}`
	sps="sps_${yy}${st}_${ppp}"

	# decalring python input and final outputfile
	finalinputfile=${tfile}
	finaloutput=${var}_SPS3_${sps}.nc

	# Python section ############################################################
	# (I) common style: use python hardcoded dictionary to convert variables (see py script)
	python -d ${pythoncommand} -i ${finalinputfile} -o ${outputfile} ${option} common -v "${varC3S}"

	# (II) usdef style: user defined variable conversion (see py script here an example for a NO converted tas var)
	#python C3S_lead2Mmonth.py -i ${finalinputfile} -o ${outputfile} usdef -cvn "${varC3S}" -cvo T2M -cvu K -cvc 1 -cvm multiply

	#python C3S_lead2Mmonth.py -h
		# usage: C3S_lead2Mmonth.py [-h] -i INPUTFILE -o OUTPUTFILE [-t]
		#                           [-plev {92500.0,85000.0,50000.0,20000.0,10000.0}]
		#                           [--version]
		#                           {common,usdef} ...

		# Convert C3S files into a monthly mean prost processed files. Any file contain
		# only one field.

		# positional arguments:
		#   {common,usdef}        Input nc file vars dictionary. 2 way (i) common - pass
		#                         standard varname (ii) usdef - you define all
		#     common              -v option is required only when option custom var
		#                         (-cv*) is not used
		#     usdef               Custom var allow to add a custom defined variable to
		#                         convert any given file. ex -cvn NAMEIN -cvo NAMEOUT
		#                         -cvu K -cvc 1 -cvm multiply

		# optional arguments:
		#   -h, --help            show this help message and exit
		#   -i INPUTFILE          C3S input file name
		#   -o OUTPUTFILE         Output file name
		#   -t                    Perform a test
		#   -plev {92500.0,85000.0,50000.0,20000.0,10000.0}
		#                         Level of pressure [92500., 85000., 50000., 20000.,
		#                         10000.]
		#   --version             show program's version number and exit	

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
conda deactivate

