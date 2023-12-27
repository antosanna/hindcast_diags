#!/bin/sh -l
#BSUB -q s_short
#BSUB -J clim_noECMWF
#BSUB -o logs/clim_noECMWF_%J.out
#BSUB -e logs/clim_noECMWF_%J.err

set -euvx

yy=2000
fyy=2006

st="04"

here=`pwd`
dirmm="/work/csp/sp2/SPS3.5/CESM/monthly/t2m/C3S"

while [ $yy -le $fyy ] ; do
	
	[ -f ${here}/filelist_${yy}${st}.txt ] && rm ${here}/filelist_${yy}${st}.txt
	scriptdir="/work/csp/sp1/CMCC-SPS3.5/SUBM_SCRIPTS/${st}/${yy}${st}_scripts"
        cd $scriptdir

	listpp=`grep -i "$yy $st" ensemble3.5_${yy}${st}_0??.sh | grep -v "2 [1,2,3,4]S" | awk {'print $20'} | sed 's/\"//g'`
        n=1
	for pp in $listpp ; do

		ppp=`printf "%.03d" $((10#$pp))`
                if [ -f ${dirmm}/t2m_SPS3.5_sps_${yy}${st}_${ppp}.nc ] ; then
			echo ${dirmm}/t2m_SPS3.5_sps_${yy}${st}_${ppp}.nc >> ${here}/filelist_${yy}${st}.txt
	        	if [ $n -eq 20 ] ; then
				break
			fi
			n=$(($n + 1))	
		fi
	done
        filelist=`cat ${here}/filelist_${yy}${st}.txt`
	cd $dirmm/clim/tmpdir
        ncea -O $filelist t2m_SPS3.5_sps_${yy}${st}_en_noECMWF.nc
        cd -
	yy=$(($yy + 1))    
done

cd $dirmm/clim/tmpdir
ncea -O t2m_SPS3.5_sps_????${st}_en_noECMWF.nc t2m_SPS3.5_clim_2000-2006.${st}_noECMWF.nc

exit
