#!/bin/sh -l

. $HOME/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/load_ncl
  
set -evx

st=$1
export var=$2
echo $var
export inputm=$3
DIROUT=$4

for l in 0 1 2 3
do
    export outfile33="$DIROUT/${var}_${st}_l${l}_33.nc"
    export outfile66="$DIROUT/${var}_${st}_l${l}_66.nc"
    export lead=$l
 
    ncl tercile_summary_var_lead.ncl
 
done
