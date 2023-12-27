#!/bin/sh
##BSUB -J WEB_PLOTS
##BSUB -o logs/ANOM_%J.out  # Appends std output to file %J.out.
##BSUB -e logs/ANOM_%J.err  # Appends std error to file %J.err.
##BSUB -q serial_6h       # queue
##BSUB -u antonella.sanna@cmcc.it
##BSUB -N
##BSUB -n 4    

set -evx

yy=$1
st=$2 #2 figures
refperiod=$3
varm=$4  # var name in the model
nrun=$5
all=$6
export reglist="$7"
ensoreglist=$8
#
datamm=/work/sp2/SPS3/CESM/monthly/$varm/C3S
workdir=/work/sp2/SPS3/CESM/workdir/$varm

if [ $all -eq 3 ]
then
	# old method (Andrea) - slow
	#./SPS3_month_from_C3S.sh $yy $st $nrun $datamm $workdir $varm $freq
        #if [ $varm = "TS" ] ; then
        #   ./C3S_lead2Mmonth_capsule_TS.sh $yy $st $nrun $datamm $workdir $varm $freq
        #else
	   ./C3S_lead2Mmonth_capsule_test.sh  $yy $st $nrun $datamm $workdir $varm $freq
        #fi
	./anom_SPS3_C3S.sh $yy $st $refperiod $nrun $datamm $workdir $varm
elif [ $all -eq 2 ]
then
	./anom_SPS3_C3S.sh $yy $st $refperiod $nrun $datamm $workdir $varm
fi 
if [ $varm = "TS" ] ; then
   ./nino_plume.sh $yy $st $refperiod $nrun $datamm $workdir $varm
   for ensoreg in $ensoreglist ; do
       ./ENSO_plot.sh $yy $st $ensoreg
   done
fi
./single_var_forecast_C3S_auto_test.sh $yy $st $varm "$reglist"
