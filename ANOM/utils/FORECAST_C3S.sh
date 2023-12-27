#!/bin/sh
set -evx

#WARNING!!!
# Before performing this analysis make sure you have precomputed the climatologies for the reference period (/users/home/sp2/CESM/CESM1.2/GIT/cesm/postproc/SPS3/SKILL_SCORES/ANOM)
yy=`date +%Y`
st=`date +%m`
refperiod=1993-2016
nrun=50
all=1      #3-if monthly mean + anom +plot;2 -if only anom and plot; 1-if only plot
reglist="NH SH global Europe Tropics"
cd $HOME/SPS3/postproc/SeasonalForecast/FORECAST
# IF YOU WANT TO COMPUTE TERCILES FOR REFERNCE PERIOD SET TO 1
for var in PSL PREC TREFHT #T850 Z500 PSL PREC TREFHT #TS
do
   cd $HOME/SPS3/postproc/SeasonalForecast/FORECAST

   echo 'postprocessing $var '$st
   bsub -q serial_6h -J ${var}_WEB_PLOTS -e logs/${var}_WEB_PLOTS_%J.err -o logs/${var}_WEB_PLOTS_%J.out compute_anomalies_C3S_auto.sh $yy $st $refperiod $var $nrun $all "$reglist"
   #./compute_anomalies_C3S_auto.sh $yy $st $refperiod $var $nrun $all

   cd ../
done
