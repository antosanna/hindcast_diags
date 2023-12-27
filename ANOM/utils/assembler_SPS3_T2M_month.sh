#!/bin/ksh
#BSUB -o SPS3_assembler_%J.out  # Appends std output to file %J.out.
#BSUB -e SPS3_assembler_%J.err  # Appends std error to file %J.err.
#BSUB -q serial_6h       # queue
#BSUB -n 4    

set -vx

yy=$1
st=$2
nrun=$3
datamm=$4
workdir=$5
var=$6

nmi=1  #initial month to process from start-date
nmf=6  #number of months to process
mkdir -p $datamm
mkdir -p $workdir

cd  /work/sp1/CESM/archive/
plist=`ls |grep sps_${yy}$st`
count=`ls |grep sps_${yy}$st|wc -l`
if [ $count -lt $nrun ] 
then 
     echo " you cannot perform this analysis cause the number of ensemble members is less than " $nrun
     exit    
fi
cd $workdir
ic=0
  
for sps in $plist 
do
     datadir="/work/sp1/CESM/archive/$sps/atm/hist/postproc"
     nfile=`ls /work/sp1/CESM/archive/$sps/atm/hist/postproc/ |wc -l`
     if [ $nfile -ge 6 ] 
     then
        ic=`expr $ic + 1`
     else
        continue 1 # meaning that the job is still running and 
                   # the reforecast is not complete
     fi 

#
# Concateno i file dei singoli mesi per comporre un'unica serie
#
     [ -f ${var}_SPS3_${sps}.nc ] && rm ${var}_SPS3_${sps}.nc
     cdo -mergetime ${datadir}/$sps.cam.h0.????-??_grid.nc temp$yy$st.nc 
     cdo -selvar,$var temp$yy$st.nc temp2$yy$st.nc
     nt=`cdo -ntime temp2$yy$st.nc`
     if [ $nt -ne 6 ] 
     then
        cdo -seltimestep,1/6 temp2$yy$st.nc ${var}_SPS3_${sps}.nc      
     else
        mv temp2$yy$st.nc ${var}_SPS3_${sps}.nc
     fi
     [ -f temp2$yy$st.nc ] && rm temp2$yy$st.nc
     rm temp$yy$st.nc
#

     cdo settaxis,${yy}-$st-15,12:00,1mon ${var}_SPS3_${sps}.nc tmp_${sps}.nc
     cdo setreftime,${yy}-$st-15,12:00 tmp_${sps}.nc ${var}_SPS3_${sps}.nc 
     cdo settaxis,${yy}-$st-15,12:00,1mon ${var}_SPS3_${sps}.nc tmp_${sps}.nc
     cdo setreftime,${yy}-$st-15,12:00 tmp_${sps}.nc ${var}_SPS3_${sps}.nc 
     rm tmp_${sps}.nc

     mv ${var}_SPS3_${sps}.nc $datamm
   
     if [ $ic -eq $nrun ]   #do not account for more than $nrun ensembles
     then
          exit
     fi
done  #end loop on plist
