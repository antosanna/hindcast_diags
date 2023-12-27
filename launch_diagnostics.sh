#!/bin/sh -l
#BSUB -M 85000   #if you get BUS error increase this number
#BSUB -P 0566
#BSUB -J launch_diagnostics_parallel
#BSUB -e logs/launch_diagnostics_parallel_%J.err
#BSUB -o logs/launch_diagnostics_parallel_%J.out
#BSUB -q s_medium

#ALBEDO=(FSUTOA)/SOLIN  [ con SOLIN=FSUTOA+FSNTOA]
#https://atmos.uw.edu/~jtwedt/GeoEng/CAM_Diagnostics/rcp8_5GHGrem-b40.20th.track1.1deg.006/set5_6/set5_ANN_FLNT_c.png
#LAI
#/work/csp/dp16116/data/LAI_CGLS/LAI_2000-2011_GLOBE_VGT_V2.0.2_05x05_12mon.nc

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
. $DIR_UTIL/load_cdo
set -eux  
# SECTION TO BE MODIFIED BY USER
debug=0
nmaxproc=6
sec1=1  #flag to execute section1 (1=yes; 0=no) COMPUTE ENSMEAN
sec2=0  #flag to execute section1 (1=yes; 0=no) COMPUTE ENSMEAN
sec3=1  #flag to execute section2 (1=yes; 0=no) TIMESERIES, 2D-MAPS, ANNCYC
sec4=0  #flag to execute section3 (1=yes; 0=no)  ZONAL PLOT 3D VARS
#export clim3d="MERRA2"
export clim3d="ERA5"
sec4=0  #flag for section4 (=nemo postproc) (1=yes; 0=no)
sec5=0  #flag for section5 (=QBO postproc) (1=yes; 0=no)
machine="juno"
do_atm=1
do_lnd=0
do_ice=0  #not implemented yet
export do_timeseries=0
do_znl_lnd=0  #not implemented yet
do_znl_atm=1
do_znl_atm2d=0  #not implemented yet
export do_2d_plt=1
export do_anncyc=1

# model to diagnose
utente1=$operationa_user
cam_nlev1=83
core1=FV
#
st=07
#
export startyear="$iniy_hind"
export finalyear="1999"
# select if you compare to model or obs 
export cmp2obs=1
# END SECTION TO BE MODIFIED BY USER

if [[ $cmp2obs -eq 0 ]]
then
   export cmp2mod=1
else
   export cmp2mod=0
fi
here=$PWD
export mftom1=1
export varobs
export cmp2obstimeseries=0
i=1
do_compute=1
dirdiag=/work/$DIVISION/$USER/diagnostics/SPS4_hindcast/$st
mkdir -p $dirdiag
if [[ $machine == "juno" ]]
then
   export dir_lsm=/work/csp/as34319/CMCC-SPS3.5/regrid_files/
   dir_obs1=/work/csp/as34319/obs
   dir_obs2=$dir_obs1/ERA5
   dir_obs3=/work/csp/mb16318/obs/ERA5
   dir_obs4=/work/csp/as34319/obs/ERA5
   dir_obs5=/work/csp/as34319/obs
elif [[ $machine == "zeus" ]]
then
   export dir_lsm=/work/csp/sps-dev/CESMDATAROOT/CMCC-SPS3.5/regrid_files/
   dir_obs1=/data/inputs/CESM/inputdata/cmip6/obs/
   dir_obs2=/data/delivery/csp/ecaccess/ERA5/monthly/025/
   dir_obs3=/work/csp/mb16318/obs/ERA5
   dir_obs4=/work/csp/as34319/obs/ERA5
   dir_obs5=/work/csp/as34319/obs/
fi
export climobs=1993-2016
export iniclim=$startyear

#
export rootinpfileobs
icelist=""
atmlist=""
lndlist=""
ocnlist=""
export lasty=$finalyear
export autoprec=True
user=$USER
    # model components
comps=""
if [[ $do_atm -eq 1 ]]
then
       comps="atm"
fi
if [[ $do_ice -eq 1 ]]
then
       comps+=" ice"
fi
if [[ $do_lnd -eq 1 ]]
then
       comps+=" lnd"
fi
    # read arguments
echo 'Experiment : ' $SPSSystem
echo 'Processing year(s) period : ' $startyear ' - ' $finalyear
#
opt=""
if [[ $cmp2obs -eq 1 ]]
then
   echo 'compare to obs'
   cmp2mod=0
   explist="$SPSSystem"
fi
mkdir -p $dirdiag/scripts

    # time-series zonal plot (3+5)
 
    ## NAMELISTS
pltdir=$dirdiag/plots
mkdir -p $pltdir

export pltype="png"
if [[ $debug -eq 1 ]]
then
   pltype="x11"
fi
export units
export title
allvars_atm="TREFHT"
#allvars_atm="TREFMNAV TREFMXAV T850 PRECC ICEFRAC Z500 PSL TREFHT TS PRECT"
allvars_lnd="SNOWDP FSH TLAI FAREA_BURNED";
allvars_ice="aice snowfrac ext Tsfc fswup fswdn flwdn flwup congel fbot albsni hi";
    
############################################
#  First section: postprocessing
############################################
nmaxens=15
echo 'NOW MAX ENSEMBLE SET TO '$nmaxens
if [[ $sec1 -eq 1 ]]
then
   model=CMCC-CM
   for comp in $comps
   do
      case $comp in
         atm)typelist="h3";; #"h1 h2 h3"
         lnd)typelist="h0";; 
         ice)typelist="h";; 
      esac
      for ftype in $typelist
      do
         echo "-----going to postproc $comp"
         case $comp in
            atm) realm=cam
                 case $ftype in
                    h1) allvars="minnie";;
                    h2) allvars="Z500 T850 U010 U250";;
                    h3) allvars=$allvars_atm;;
                 esac
                 ;;
            lnd) allvars=$allvars_lnd; realm=clm2;;
            ice) allvars=$allvars_ice;realm=cice;;
         esac
         if [[ $do_compute -eq 1 ]]
         then
            echo $allvars
            for var in $allvars
            do

               isrunning=`$DIR_UTIL/findjobs.sh -n ensmean_${yyyy}${st}${var} -c yes`
               if [[ $isrunning -ne 0 ]]
               then
                  continue
               fi
               $DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -M 18000 -j compute_ensmean_and_anom_${yyyy}${st}${var} -l ${here}/logs/ -d ${here} -s compute_ensmean_and_anom.sh -i "${nmaxens} ${var} $st"
            done #loop on vars
            while `true`
            do
               ijob=`$DIR_UTIL/findjobs.sh -m $machine -n compute_ensmean_ -c yes`
               if [[ $ijob -gt $nmaxproc ]]
               then
                  sleep 45
               else
                  break
               fi
            done

         fi  #if do_compute
      done #realm
   done
fi # end of section 1
############################################
#  end of first section
############################################
############################################
#  Second: time-series, percentiles
############################################
if [[ $sec2 -eq 1 ]]
then
    while `true`
    do
       ijob=`$DIR_UTIL/findjobs.sh -m $machine -n compute_ensmean_ -c yes`
       if [[ $ijob -ne 0 ]]
       then
          sleep 45
       else
          break
       fi
    done
    for comp in atm
    do
       case $comp in
         atm)typelist="h3";; # h2 h3";;
         lnd)typelist="h0";;
         ice)typelist="h";;
       esac
       for ftype in $typelist
       do
          case $comp in
            atm) realm=cam
                 case $ftype in
                    h1) allvars="minnie";;
                    h2) allvars="Z500 T850 U010 U250";;
                    h3) allvars=$allvars_atm;;
                 esac
                 ;;
            lnd) allvars=$allvars_lnd; realm=clm2;;
            ice) allvars=$allvars_ice;realm=cice;;
          esac
          for var in $allvars
          do

             mkdir -p $dirdiag/$var/PCTL
             inputm=`ls -tr $dirdiag/$var/ANOM/cam.$ftype.$st.$var.all_anom.${iniy_hind}-????.$nmaxens.nc|tail -1`
             $DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -M 1800 -j compute_percentiles_${st}${var} -l ${here}/logs/ -d ${here} -s make_seasonal_tercile.sh -i "$st ${var} $inputm $dirdiag/$var/PCTL "

          done
       done
    done
fi
############################################
#  end of second section
############################################
############################################
#  Third: BIAS, 2d maps and annual cycles
############################################
if [[ $sec3 -eq 1 ]]
then
for comp in $comps
do
   case $comp in
      atm) allvars=$allvars_atm;realm=cam;typelist="h3";;
      lnd) allvars=$allvars_lnd;typelist="h0";
          realm=clm2;;
      ice) allvars=$allvars_ice;realm=cice;typelist="h";;
   esac
   for ftype in $typelist
   do
#      outnml=$dirdiag/nml
   # copy locally the namelists
#      mkdir -p $outnml
#      if [[  `ls $rundir/namelist* |wc -l` -gt 0 ]]
#      then
#         rsync -auv $rundir/namelist* $outnml
#      fi
#      if [[  `ls $rundir/file_def*xml |wc -l` -gt 0 ]]
#      then
#         rsync -auv $rundir/file_def*xml  $outnml
#      fi
   
      export varmod
   
      units=""
      echo $allvars
      ijob=0
      for varmod in $allvars
      do
         DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -M 1800 -j diagnostics_single_var_${st}${varmod} -l ${here}/logs/ -d ${here} -s diagnostics_single_var.sh -i "$lasty $cmp2obs $pltype $varmod $comp $do_timeseries $do_atm $do_lnd $do_ice $dirdiag $nmaxens"
         while `true`
         do
            ijob=`$DIR_UTIL/findjobs.sh -m $machine -n compute_ensmean_ -c yes`
            if [[ $ijob -gt $nmaxproc ]]
            then
               sleep 45
            else
               break
            fi
         done
      done
        
   done   #loop on ftype
done   #loop on comp
fi   # end of section3
exit

############################################
#  End of third section
############################################


cd $here


if [[ -f $pltdir/index.html ]]
then
   rm -f $pltdir/index.html
fi
for fld in `ls $dirdiag/plots/atm/*${startyear}-${lasty}*|rev|cut -d '.' -f 4|rev|sort -n |uniq`
do
   if [[ $fld == "Z3" ]] || [[ $fld == "T" ]] || [[ $fld == "U" ]]
   then
      continue
   fi
   atmlist+=" \"$fld\","
done
for fld in `ls $dirdiag/plots/lnd/*${startyear}-${lasty}*|rev|cut -d '.' -f 4|rev|sort -n |uniq`
do
   lndlist+=" \"$fld\","
done
for fld in `ls $dirdiag/plots/ocn/*${startyear}-${lasty}*|rev|cut -d '.' -f 4|rev|sort -n |uniq`
do
   ocnlist+=" \"$fld\","
done
for fld in `ls $dirdiag/plots/ice/*${startyear}-${lasty}*|rev|cut -d '.' -f 4|rev|sort -n |uniq`
do
   icelist+=" \"$fld\","
done
sed -e 's/DUMMYCLIM/'$startyear-${lasty}'/g;s/DUMMYEXPID/'$SPSSystem'/g;s/atmlist/'"$atmlist"'/g;s/lndlist/'"$lndlist"'/g;s/icelist/'"$icelist"'/g;s/ocnlist/'"$ocnlist"'/g' index_tmpl.html > $pltdir/index.html
cd $pltdir
if [[ $cmp2mod -eq 0 ]] 
then
   tar -cvf $SPSSystem.$startyear-${lasty}.VSobs.tar atm lnd ice ocn index.html
   gzip -f $SPSSystem.$startyear-${lasty}.VSobs.tar
else
   tar -cvf $SPSSystem.$startyear-${lasty}.VS$expid2.tar atm lnd ice ocn index.html
   gzip -f $SPSSystem.$startyear-${lasty}.VS$expid2.tar
fi


