#!/bin/sh -l
#BSUB -M 850   #if you get BUS error increase this number
#BSUB -P 0566
#BSUB -J create_web_page
#BSUB -e logs/create_web_page%J.err
#BSUB -o logs/create_web_page%J.out
#BSUB -q s_medium

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
. $DIR_UTIL/load_cdo
set -eux  
here=$PWD
# SECTION TO BE MODIFIED BY USER
cam_nlev1=83
core1=FV
#
export startyear="$iniy_hind"
# select if you compare to model or obs 
export climobs=1993-2016

echo 'Experiment : ' $SPSSystem
tardir=/work/csp/$USER/diagnostics/SPS4_hindcast/plots
if [[ -f $tardir/index.html ]]
then
   rm -f $tardir/index.html
fi
cp index_tmpl.html $tardir/index.html
nmaxens=0
for st in {01..12}
do
   case $st in
      01) nmaxens=0;;
      02) nmaxens=0;;
      03) nmaxens=0;;
      04) nmaxens=0;;
      05) nmaxens=10;;
      06) nmaxens=0;;
      07) nmaxens=13;;
      08) nmaxens=14;;
      09) nmaxens=0;;
      10) nmaxens=13;;
      11) nmaxens=11;;
      12) nmaxens=0;;
   esac
   if [[ $nmaxens -eq 0 ]]
   then
      continue
   fi
   lasty=0
   for yyyy in `seq $iniy_hind $endy_hind`
   do
     if [[ `ls $DIR_CASES1/${SPSSystem}_${yyyy}${st}_0??/logs/*${nmonfore}months_done|wc -l` -lt $nmaxens ]] 
     then
# cases transferred from Zeus (DIR_CASES are not transferred)
        if [[ `ls $DIR_ARCHIVE1/${SPSSystem}_${yyyy}${st}_0??.transfer_from_Zeus_DONE|wc -l` -lt $nmaxens ]]
        then 
           break
        fi  
     fi  
     lasty=$yyyy
   done
   echo $lasty
   if [[ $lasty -eq 0 ]]
   then 
      continue
   fi
   echo "Processing year(s) period start-date $st: $startyear - $lasty"

   bias=""
   for fld in `ls $tardir/$st/bias/*$st*${startyear}-${lasty}.??.png |cut -d '_' -f 4|sort -n |uniq`
   do
      bias+=" \"$fld\","
   done

   acc=""
   for fld in `ls $tardir/$st/acc/*$st*${startyear}-${lasty}.??.png|cut -d '_' -f 4|sort -n |uniq`
   do
      acc+=" \"$fld\","
   done
   roc=""
   sed -i "s/DUMMYCLIM/$startyear-${endy_hind}/g;s/nmaxens$st/$nmaxens/g;s/DUMMYEXPID/$SPSSystem/g;s/lasty$st/$lasty/g;s/biaslist/"$bias"/g;s/acclist/"$acc"/g;s/roclist/"$roc"/g" $tardir/index.html 
done

$here/copy2ftp.sh
#cd $tardir


#tar -cvf $SPSSystem.hindcast.VSobs.tar ??/bias ??/acc ??/roc index.html
#gzip -f $SPSSystem.hindcast.VSobs.tar

