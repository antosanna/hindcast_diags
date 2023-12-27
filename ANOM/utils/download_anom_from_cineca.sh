#!/bin/sh -l

set -evx


varlist="t850"
st="02"

for var in $varlist ; do

    localdir="/work/csp/sp2/SPS3.5/CESM/monthly/${var}/C3S"
    remotedir="/gpfs/scratch/usera07cmc/a07cmc00/SKILL_SCORE/monthly/$var/C3S"
    hostname="a07cmc00@login01.galileo.cineca.it"
    
    echo "a(nU05wgJk"
    rsync -auv --progress $hostname:$remotedir/*sps_????${st}_*  $localdir
    echo "a(nU05wgJk"
    rsync -auv --progress $hostname:$remotedir/clim/*${st}.nc* $localdir/clim
    echo "a(nU05wgJk"
    #rsync -auv --progress $hostname:$remotedir/anom/*sps_????${st}_* $localdir/anom
    rsync -auv --progress $hostname:$remotedir/anom/*SPS3.5*${st}_* $localdir/anom

done


