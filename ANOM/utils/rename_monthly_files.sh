#!/bin/sh -l 
#BSUB -q s_short
#BSUB -J rename_monthly_files
#BSUB -o logs/rename_monthly_files_%J.out
#BSUB -e logs/rename_monthly_files_%J.err
#BSUB -N
#BSUB -u andrea.borrelli@cmcc.it

set -euvx

dirmm=/work/csp/sp2/SPS3.5/CESM/monthly
cd $dirmm

varlist="precip mslp sst z500 t850"

for var in $varlist ; do
	case $var
	in
	 t2m)    varold=TREFHT ;;
	 t850)   varold=T850 ;;
	 mslp)   varold=PSL ;;
	 sst)    varold=TS ;;
	 precip) varold=PREC ;;
	 z500)   varold=Z500 ;;
	esac
	cd $var/C3S
	set +e
	flist=`ls -1 ${varold}_*`
        ret=$?
	set -e
        if [ $ret -eq 0 ] ; then
		for file in $flist ; do
			file_novar=`echo $file | cut -d '_' -f2-`
			filenew=`echo ${var}_${file_novar}`
			mv $file $filenew
		done
	fi
	cd $dirmm
done

