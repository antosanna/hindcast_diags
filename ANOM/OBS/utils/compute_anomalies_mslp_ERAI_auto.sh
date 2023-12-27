#!/bin/sh -l
#BSUB -P 0287
#BSUB -J mslp_ERAI_anom
#BSUB -o logs/mslp_ERAI_anom_%J.out  # Appends std output to file %J.out.
#BSUB -e logs/mslp_ERAI_anom_%J.err  # Appends std error to file %J.err.
#BSUB -q s_medium       # queue
#BSUB -N
#BSUB -u andrea.borrelli@cmcc.it

. $HOME/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh

set -evx

export iniy=1993
export endy=2016
st=11 #2 figures
export nrun=40
varm=mslp
#
datamm=/work/csp/sp2/VALIDATION/ERAI/monthly/mslp
workdir=/work/csp/sp2/VALIDATION/ERAI/workdir/mslp

prefix=mslp_ERAI
./assembler_mslp_ERAI_month.sh $iniy $endy $st $datamm $workdir $prefix
./clim_ERAI_mslp.sh $iniy $endy $st $datamm $workdir $prefix
./anom_ERAI_mslp.sh $iniy $endy $st $datamm $workdir  $prefix
