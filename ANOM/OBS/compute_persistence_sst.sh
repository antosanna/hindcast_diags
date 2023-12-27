#!/bin/sh -l
#BSUB -P 0490
#BSUB -J persistence
#BSUB -o logs/persistence_%J.out  # Appends std output to file %J.out.
#BSUB -e logs/persistence_%J.err  # Appends std error to file %J.err.
#BSUB -q s_medium       # queue
#BSUB -u andrea.borrelli@cmcc.it
#BSUB -N
#BSUB -n 1

. ~/.bashrc_skill_scores
. ${DIR_ROOT_SCORES}/descr_SKILL_SCORES.sh

set -evx

export iniy=1993
export endy=2016
stlist="1"  #3 4 6 7 9 10 12"  #2 5 8 11"  #8 9 10 11 12" #not 2 figures
var="sst"
dataset="ERA5"
#

datamm=${CLIM_OBS_DIR_DIAG}
workdir=${CLIM_OBS_DIR_DIAG}/../workdir


for st in $stlist ; do

    ./calc_PERSISTENCE.sh $iniy $endy $st $var $dataset $datamm $workdir

done

exit

