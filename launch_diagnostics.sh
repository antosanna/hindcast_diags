#!/bin/sh -l
#BSUB -M 100   #if you get BUS error increase this number
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
sec2=0  #flag to execute section2 (1=yes; 0=no) COMPUTE PERCENTILES
sec3=0  #flag to execute section3 (1=yes; 0=no) BIAS
sec4=0  #flag to execute section4 (1=yes; 0=no) ACC
#export clim3d="MERRA2"
export clim3d="ERA5"
sec5=1  #flag for section5 (web page creation)
machine="juno"
do_atm=1
do_lnd=0
do_ice=0  #not implemented yet
export do_timeseries=0
do_znl_lnd=0  #not implemented yet
do_znl_atm=1
do_znl_atm2d=0  #not implemented yet
export do_2d_plt=1
export do_anncyc=0

# model to diagnose
utente1=$operational_user
cam_nlev1=83
core1=FV
#
#
export startyear="$iniy_hind"
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
dirdiag=/work/$DIVISION/$USER/diagnostics/SPS4_hindcast
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
#
opt=""
if [[ $cmp2obs -eq 1 ]]
then
   echo 'compare to obs'
   cmp2mod=0
   explist="$SPSSystem"
fi

export pltype="png"
if [[ $debug -eq 1 ]]
then
   pltype="x11"
fi
export units
export title
allvars_atmh3="" #"PSL TREFHT PRECT"
allvars_atmh2="Z500 T850 U925"
allvars_atmh1="" #Z500 T850 U925"
#allvars_atm="TREFMNAV TREFMXAV T850 PRECC ICEFRAC Z500 PSL TREFHT TS PRECT"
allvars_lnd="SNOWDP FSH TLAI FAREA_BURNED";
allvars_ice="aice snowfrac ext Tsfc fswup fswdn flwdn flwup congel fbot albsni hi";
    
 
    ## NAMELISTS
tardir=$dirdiag/plots
declare -a nmaxens
for ic in {0..11}
do
   nmaxens[$ic]=0
done
for st in 05 #07 11
do
   dirdiagst=/work/$DIVISION/$USER/diagnostics/SPS4_hindcast/$st
   mkdir -p $dirdiagst/scripts
   ic=$((10#$st - 1))
   case $st in
      05) nmaxens[$ic]=13;;
      07) nmaxens[$ic]=13;;
      11) nmaxens[$ic]=13;;
   esac
   pltdir=$dirdiag/plots/$st
   mkdir -p $pltdir
   mkdir -p $pltdir/bias
   mkdir -p $pltdir/acc
   mkdir -p $pltdir/roc

   for yyyy in `seq $iniy_hind $endy_hind`
   do
     if [[ `ls $DIR_CASES1/${SPSSystem}_${yyyy}${st}_0??/logs/*${nmonfore}months_done|wc -l` -lt ${nmaxens[$ic]} ]]
     then 
# cases transferred from Zeus (DIR_CASES are not transferred)
        if [[ `ls $DIR_ARCHIVE1/${SPSSystem}_${yyyy}${st}_0??.transfer_from_Zeus_DONE|wc -l` -lt ${nmaxens[$ic]} ]]
        then        
           break
        fi  
     fi  
     lasty=$yyyy
   done
   echo 'Experiment : ' $SPSSystem
   echo "Processing year(s) period for start-date $st: $startyear - $lasty"
   ############################################
   #  First section: postprocessing
   ############################################
   echo 'NOW MAX ENSEMBLE SET TO '${nmaxens[$ic]}
   if [[ $sec1 -eq 1 ]]
   then
      model=CMCC-CM
      for comp in $comps
      do
         case $comp in
            atm)typelist="h1 h2 h3";;
            lnd)typelist="h0";; 
            ice)typelist="h";; 
         esac
         for ftype in $typelist
         do
            echo "-----going to postproc $comp"
            case $comp in
               atm) realm=cam
                    case $ftype in
                       h1) allvars=$allvars_atmh1;;
                       h2) allvars=$allvars_atmh2;;
                       h3) allvars=$allvars_atmh3;;
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
                  $DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -M 18000 -j compute_ensmean_and_anom_${st}${var} -l ${here}/logs/ -d ${here} -s compute_ensmean_and_anom.sh -i "${nmaxens[$ic]} ${var} $st $dirdiag $lasty"
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
   ############################################
   #  end of first section
   ############################################
   ############################################
   #  Second: time-series, percentiles
   ############################################
   if [[ $sec2 -eq 1 ]]
   then
       for comp in atm
       do
          case $comp in
            atm)typelist="h3 h2 h3";;
            lnd)typelist="h0";;
            ice)typelist="h";;
          esac
          for ftype in $typelist
          do
             case $comp in
               atm) realm=cam
                    case $ftype in
                       h1) allvars="minnie";;
                       h2) allvars=$allvars_atmh2;;
                       h3) allvars=$allvars_atmh3;;
                    esac
                    ;;
               lnd) allvars=$allvars_lnd; realm=clm2;;
               ice) allvars=$allvars_ice;realm=cice;;
             esac
             for var in $allvars
             do
   
                mkdir -p $dirdiag/$var/PCTL
                inputm=`ls -tr $dirdiag/$var/ANOM/cam.$ftype.$st.$var.all_anom.${iniy_hind}-????.${nmaxens[$ic]}.nc|tail -1`
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
         atm) realm=cam;typelist="h2 h3";;
         lnd) allvars=$allvars_lnd;typelist="h0";
             realm=clm2;;
         ice) allvars=$allvars_ice;realm=cice;typelist="h";;
      esac
      for ftype in $typelist
      do
         case $comp in
            atm) realm=cam;
              case $ftype in
                  h1) allvars=$allvars_atmh1;;
                  h2) allvars=$allvars_atmh2;;
                  h3) allvars=$allvars_atmh3;;
              esac;;
        
         esac
         export varmod
      
         units=""
         echo $allvars
         ijob=0
         for varmod in $allvars
         do
            $DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -M 1000 -j compute_BIAS_${st}${varmod} -l ${here}/logs/ -d ${here} -s compute_BIAS.sh -i "$lasty $cmp2obs $pltype $varmod $comp $do_timeseries $do_atm $do_lnd $do_ice $dirdiag ${nmaxens[$ic]} $st $cmp2obs $do_anncyc $do_2d_plt $pltdir/bias"
            while `true`
            do
               ijob=`$DIR_UTIL/findjobs.sh -m $machine -n compute_BIAS -c yes`
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
   
   ############################################
   #  End of third section
   ############################################
   ############################################
   #  section 4 : ACC
   ############################################
   if [[ $sec4 -eq 1 ]]
   then
       for comp in atm
       do
          case $comp in
            atm)typelist="h2 h3";;
            lnd)typelist="h0";;
            ice)typelist="h";;
          esac
          for ftype in $typelist
          do
             case $comp in
               atm) realm=cam
                    case $ftype in
                       h1) allvars="minnie";;
                       h2) allvars=$allvars_atmh2;;
                       h3) allvars=$allvars_atmh3;;
                    esac
                    ;;
               lnd) allvars=$allvars_lnd; realm=clm2;;
               ice) allvars=$allvars_ice;realm=cice;;
             esac
             for var in $allvars
             do
   
                mkdir -p $pltdir/acc
                inputm=`ls -tr $dirdiag/$var/ANOM/cam.$ftype.$st.$var.all_anom.${iniy_hind}-????.${nmaxens[$ic]}.nc|tail -1`
                for region in global
                do
                   $DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -M 3000 -j compute_ACC_${st}${var} -l ${here}/logs/ -d ${here} -s compute_ACC.sh -i "$lasty ${nmaxens[$ic]} $st $pltdir/acc $var $ftype $dirdiag $region"
                done
   
             done
          done
       done
   fi
   ############################################
   #  end of section 4
   ############################################

done
if [[ $sec5 -eq 1 ]]
then
   cd $here
   sed -e "s/NENS01/${nmaxens[0]}/g;s/NENS02/${nmaxens[1]}/g;s/NENS03/${nmaxens[2]}/g;s/NENS04/${nmaxens[3]}/g;s/NENS05/${nmaxens[4]}/g;s/NENS06/${nmaxens[5]}/g;s/NENS07/${nmaxens[6]}/g;s/NENS08/${nmaxens[7]}/g;s/NENS09/${nmaxens[8]}/g;s/NENS10/${nmaxens[9]}/g;s/NENS11/${nmaxens[10]}/g;s/NENS12/${nmaxens[11]}/g;" create_plot_web.sh > create_plot_web_now.sh
   chmod u+x create_plot_web_now.sh
   $DIR_UTIL/submitcommand.sh -m $machine -q $serialq_l -M 1000 -j create_plot_web -l ${here}/logs/ -d ${here} -s create_plot_web_now.sh 
fi
