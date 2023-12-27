#!/bin/sh -l
#BSUB -q s_long
#BSUB -J extr_h1
#BSUB -o logs/extr_h1_%J.out
#BSUB -e logs/extr_h1_%J.err


. ~/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh

set -evx

. ./modules4CDO.sh 

yy=2000
fyy=2006
st=04
nrun=20
export varm="TREFHT"

# YOU SHOULD USE THIS FOR FILES NOT YET ARCHIVED

ARCHIVE=/data/csp/sp1/archive/CESM/SPS3.5
DATAMM=/work/csp/sp2/SPS3.5/CESM/monthly/${varm}
workdir=/work/csp/sp2/SPS3.5/CESM/workdir/${varm}
here=`pwd`


while [ $yy -le $fyy ] ; do

	cd $ARCHIVE
	caselist=`ls -1d sps3.5_${yy}${st}_??? | head -${nrun}`
	interpolator=$here/regridSE_reg1x1.ncl

	for caso in $caselist ; do
		dirfile=$ARCHIVE/$caso/atm/hist
		cd $dirfile
		list=`ls -1 *cam.h1*nc | head -1`
                cd $workdir

		year=$yy
		mon=$st
		for file in $list
		do
			[ $mon -gt 12 ] && { mon=1 ; year=$(($year + 1)) ; }
			month=`printf "%.02d" $((10#$mon))`
			export inputSE=${caso}_${varm}_${year}${month}_monthly.nc
			export out="${DATAMM}/${caso}_${varm}_${year}${month}_reg1x1.nc"
			ncks -O -6 $dirfile/$file ${caso}_${year}${month}_m0_tmp.nc
			cdo monmean -selmon,$month ${caso}_${year}${month}_m0_tmp.nc $inputSE
			ncl ${interpolator}
			rm $inputSE
			mon=$(($mon + 1))
			
		done
	done
	yy=$(($yy + 1))
done

exit
