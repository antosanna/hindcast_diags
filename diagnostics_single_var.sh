#!/bin/sh -l 
. ~/.bashrc 
. $DIR_UTIL/descr_CPS.sh 
. $DIR_UTIL/descr_ensemble.sh 1993 
. $DIR_UTIL/load_cdo 
set -eux  
# 
export lasty=${1} 
# select if you compare to model or obs 
export cmp2obs=${2}
export pltype=${3}
export var=${4}
export comp=${5}
case $comp in
   atm)realm=cam;;
   lnd)realm=clm2;;
   ice)realm=cice;;
esac
export do_timeseries=${6}
export do_atm=${7}
export do_lnd=${8}

dirdiag=${10}
nmaxens=${11}
export st=${12}
export cmp2obs=${13}
export do_anncyc=${14}
do_2d_plt=${15}
#fi
# END SECTION TO BE MODIFIED BY USER

mkdir -p $dirdiag
export startyear=${iniy_hind}
export mftom1=1
export varobs
export cmp2obstimeseries=0
i=1
export expname1=$SPSSystem
if [[ $machine == "juno" ]]
then
   export dir_lsm=/work/csp/as34319/CMCC-SPS3.5/regrid_files/
   dir_obs1=/work/csp/as34319/obs
   dir_obs2=$dir_obs1/ERA5
   dir_obs3=/work/csp/mb16318/obs/ERA5
   dir_obs4=/work/csp/as34319/obs/ERA5
   dir_obs5=/work/csp/as34319/obs
set +euvx 
   . $DIR_UTIL/load_ncl
set -euvx 
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
echo 'Processing year(s) period : ' $startyear ' - ' $lasty
#
opt=""
if [[ $cmp2obs -eq 1 ]]
then
   echo 'compare to obs'
fi

    # time-series zonal plot (3+5)
 
    ## NAMELISTS
pltdir=$dirdiag/plots/bias
mkdir -p $pltdir

export units
export title
    
model=CMCC-SPS4
var2plot=" "
if [[ $do_timeseries -eq 1 ]]
then
for comp in $comp
do
      case $comp in
         atm)typelist="h3";; 
         lnd)typelist="h0";; 
         ice)typelist="h";; 
      esac
      for ftype in $typelist
      do
         echo "-----going to postproc $comp"
         case $comp in
   # ALBEDOC
            atm) realm=cam;;
            lnd) realm=clm2;;
            ice) realm=cice;;
         esac
         #serie di valori annui
#         ymeanfilevar=$dirdiag/${exp}.$realm.$var.$startyear-$lasty.ymean.nc
#         if [[ ! -f $dirdiag/${exp}.$realm.$var.$startyear.nc ]]
#         then
#            continue
#         fi
#         if [[ ! -f $ymeanfilevar ]]
#         then
#            cdo yearmean -mergetime $listaf $ymeanfilevar
#         fi
         #ciclo annuo
#         anncycfilevar=$dirdiag/${exp}.$realm.$var.$startyear_anncyc-$lasty.anncyc.nc
#         cdo ymonmean -mergetime $listaf_anncyc $anncycfilevar
      done
done #expid
fi
   
export varmod=$var
   
units=""
export units_from_here=0
export name_from_here=0
#if [[ ! -f $dirdiag/${SPSSystem}.$realm.$varmod.$startyear-${lasty}.ymean.nc ]]
#then
#            continue
#fi
export cf=0
export mf=1
export yaxis
export title=""
export title2=""
export units=""
export varmod2=""
export ncl_plev=0
export obsfile
export computedvar=""
export compute=0
export cmp2obs=1
export ncl_lev=0
export cmp2obs_ncl
export delta
export deltadiff
export maxplot
export minplot
export maxplotdiff
export minplotdiff
export cmp2obs_anncyc=$cmp2obs
case $varmod in
   CLDHGH)varobs=var188;export maxplot=0.9;export minplot=0.1;delta=.1;title="High-level cloud 50-400hPa";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=.6;export minplotdiff=-.6;deltadiff=.1;obsfile="$dir_obs2/cldhgh_era5_${climobs}_ann_cyc.nc";export title2="ERA5 $climobs";export cmp2obs_ncl=$cmp2obs;cmp2obs_anncyc=0;;
   CLDLIQ)varobs=var186;export maxplot=0.001;export minplot=0.;delta=.0001;title="Liquid water cloud content";units_from_here=1;units="kg/kg";name_from_here=1;export maxplotdiff=0.0001;export minplotdiff=-0.0001;deltadiff=.00001;obsfile="$dir_obs2/cldlow_era5_${climobs}_ann_cyc.nc";export title2="ERA5 $climobs";cmp2obs_ncl=0;cmp2obs_anncyc=0;;
   CLDICE)varobs=var186;export maxplot=0.0001;export minplot=0.;delta=.00001;title="Ice water cloud content";units_from_here=1;units="kg/kg";name_from_here=1;export maxplotdiff=0.00001;export minplotdiff=-0.00001;deltadiff=.000001;obsfile="$dir_obs2/cldlow_era5_${climobs}_ann_cyc.nc";export title2="ERA5 $climobs";cmp2obs_ncl=0;cmp2obs_anncyc=0;;
   CLDLOW)varobs=var186;export maxplot=0.9;export minplot=0.1;delta=.1;title="Low-level cloud 700-1200hPa";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=0.6;export minplotdiff=-0.6;deltadiff=.1;obsfile="$dir_obs2/cldlow_era5_${climobs}_ann_cyc.nc";export title2="ERA5 $climobs";cmp2obs_ncl=$cmp2obs;cmp2obs_anncyc=$cmp2obs;;
   CLDMED)varobs=var187;export maxplot=0.9;export minplot=0.1;delta=.1;title="Mid-level cloud 400-700hPa";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=.6;export minplotdiff=-.6;deltadiff=.1;obsfile="$dir_obs2/cldmed_era5_${climobs}_ann_cyc.nc";export title2="ERA5 $climobs";export cmp2obs_ncl=$cmp2obs;cmp2obs_anncyc=$cmp2obs;;
   CLDTOT)varobs=var164;export maxplot=0.9;export minplot=0.1;delta=.1;title="Total cloud cover";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=.6;export minplotdiff=-.6;deltadiff=.1;obsfile="$dir_obs2/cldtot_era5_${climobs}_ann_cyc.nc";export title2="ERA5 $climobs";name_from_here=1;export cmp2obs_ncl=$cmp2obs;;
   EmP)varobs=var167;mf=86400000;units="mm/d";export maxplot=10.;export minplot=-10.;delta=2.;title="Evaporation - Precipitation";units_from_here=1;name_from_here=1;cmp2obs_anncyc=0;cmp2obs_ncl=0;export maxplotdiff=3.;export minplotdiff=-3.;deltadiff=.5;;
   EnBalSrf)varobs=ftot;units="W/m2";export maxplot=20.;export minplot=-20.;delta=2.;title="Surface Radiative Balance";name_from_here=1;units_from_here=1;export maxplotdiff=10.;export minplotdiff=-10.;deltadiff=1.;export cmp2obs_ncl=$cmp2obs;obsfile="$dir_obs3/ftot_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobs";;
   FLUT)varobs=FLUT;export maxplot=300;export minplot=120;delta=20.;export maxplotdiff=40;export minplotdiff=-40;deltadiff=10.;obsfile="$dir_obs1/CERES-EBAF_1m_1deg_2000-2009.nc";name_from_here=1;title="Up lw Top of Model";export title2="CERES 2000-2009";export cmp2obs_ncl=$cmp2obs;;
   FSH)varobs=var167;export maxplot=100.;export minplot=-100.;delta=10.;title="Sensible Heat";units_from_here=1;name_from_here=1;export maxplotdiff=10.;export minplotdiff=-10.;deltadiff=1.;export cmp2obs_ncl=0;;
   H2OSOI) title="Volumetric Soil Water at 1.36m";name_from_here=1;export cmp2obs_ncl=$cmp2obs;;
   ICEFRAC)cf=0;units="frac";obsfile="";export cmp2obs_ncl=0;cmp2obs_anncyc=0;title2="ERA5 $climobs";export maxplot=0.95;export minplot=0.15;delta=.05;units_from_here=0; title="Sea-Ice Fraction";name_from_here=1;minplotdiff=-0.5;maxplotdiff=0.5;deltadiff=0.05;;
   H2OSNO)varobs=sd; title="Snow Depth (liquid water)";varobs=var167;mf=0.01;export maxplot=10;export minplot=0.5;delta=0.5;units_from_here=1;units="m";name_from_here=1;export cmp2obs_ncl=$cmp2obs;;
   T850)varobs=T2M;cf=-273.15;units="Celsius deg";obsfile="$dir_obs1";title2="ERA5 $climobs";export maxplot=36;export minplot=-20;delta=4;units_from_here=1;export cmp2obs_ncl=0;;
   TREFMNAV)varobs=T2M;cf=-273.15;units="Celsius deg";obsfile="$dir_obs1";title2="ERA5 $climobs";export maxplot=36;export minplot=-20;delta=4;units_from_here=1;export cmp2obs_ncl=0;;
   TREFMXAV)varobs=T2M;cf=-273.15;units="Celsius deg";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";title2="ERA5 $climobs";export maxplot=36;export minplot=-20;delta=4;units_from_here=1;export cmp2obs_ncl=0;;
   TREFHT)varobs=var167;cf=-273.15;units="Celsius deg";obsfile="$dir_obs1/t2m_ERA5_1m_clim_1993-2016.nc";title2="ERA5 $climobs";export maxplot=36;export minplot=-20;delta=4;units_from_here=1;export cmp2obs_ncl=$cmp2obs;;
   U010)varobs=var131;units="m/s";obsfile="$dir_obs4/uplev_era5_1979-2018_anncyc.nc";ncl_lev=1;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;deltadiff=2.;cmp2obs_anncyc=1;export cmp2obs_ncl=$cmp2obs;;
   U100)varobs=var131;units="m/s";obsfile="$dir_obs4/uplev_era5_1979-2018_anncyc.nc";ncl_lev=2;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;deltadiff=2.;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   U200)varobs=U;units="m/s";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=1;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;deltadiff=2.;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   U700)varobs=var131;units="m/s";obsfile="$dir_obs4/uplev_era5_1979-2018_anncyc.nc";ncl_lev=4;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;deltadiff=2.;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   Z010)varobs=var129;cf=0;units="m";obsfile="$dir_obs4/Zplev_era5_1979-2018_anncyc.nc";ncl_lev=1;title2="ERA5 $climobs";export maxplot=31600.;export minplot=28800;delta=100;units_from_here=1;export maxplotdiff=200;export minplotdiff=-200;deltadiff=20.;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   Z100)varobs=var129;cf=0;units="m";obsfile="$dir_obs4/Zplev_era5_1979-2018_anncyc.nc";ncl_lev=2;title2="ERA5 $climobs";export maxplot=16800.;export minplot=15000;delta=100;units_from_here=1;export maxplotdiff=200;export minplotdiff=-200;deltadiff=20.;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   Z500)varobs=Z;cf=0;units="m";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=3;title2="ERA5 $climobs";export maxplot=5900.;export minplot=4800;delta=100;units_from_here=1;export maxplotdiff=50;export minplotdiff=-50;deltadiff=5.;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   Z700)varobs=var129;cf=0;units="m";obsfile="$dir_obs4/Zplev_era5_1979-2018_anncyc.nc";ncl_lev=4;title2="ERA5 $climobs";export maxplot=3200.;export minplot=2600;delta=100;units_from_here=1;export maxplotdiff=100;export minplotdiff=-100;deltadiff=20.;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   Z850)varobs=Z;cf=0;units="m";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=5;title2="ERA5 $climobs";export maxplot=1550.;export minplot=1050.;delta=50;units_from_here=1;export maxplotdiff=50.;export minplotdiff=-50;deltadiff=5.;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   TS)varobs=var235;cf=-273.15;units="Celsius deg";obsfile="$dir_obs1/sst_HadISST_1m_clim_1993-2016.nc";export title2="ERA5 $climobs";export maxplot=36;export minplot=-20;delta=4;units_from_here=1;export cmp2obs_ncl=$cmp2obs;;
   PRECT)varobs=precip;mf=86400000;units="mm/d";export maxplot=18;export minplot=2;delta=2.;export maxplotdiff=5.;export minplotdiff=-5.;deltadiff=1.;obsfile="$dir_obs1/precip_GPCP_1m_clim_1993-2016.nc";export title2="GPCP $climobs";title="Total precipitation";units_from_here=1;name_from_here=1;export cmp2obs_ncl=$cmp2obs;;
   PRECC)varobs=var167;mf=86400000;units="mm/d";export maxplot=18;export minplot=2;delta=2.;title="Convective precipitation";units_from_here=1;name_from_here=1;cmp2obs_ncl=0;cmp2obs_anncyc=0;;
   PSL)varobs=var151;mf=0.01;units="hPa";export maxplot=1030;export minplot=990;delta=4.;export maxplotdiff=8;export minplotdiff=-8;deltadiff=2.;obsfile="$dir_obs1/mslp_ERA5_1m_clim_1993-2016.nc";export cmp2obs_ncl=$cmp2obs;;
   QFLX)varobs=var167;mf=1000000;units="10^-6 kgm-2s-1";export maxplot=100.;export minplot=0.;delta=10.;title="Surface Water Flux";units_from_here=1;name_from_here=1;cmp2obs_ncl=0;export maxplotdiff=10.;export minplotdiff=-10.;deltadiff=1.;;
   SOLIN)varobs=var167;units="W/m2";export maxplot=450;export minplot=60;delta=30.;title="Insolation";units_from_here=1;name_from_here=1;cmp2obs_ncl=0;cmp2obs_anncyc=0;axplotdiff=0.00005;export minplotdiff=-0.00005;deltadiff=.00001;;
   FLDS)varobs=var175;export maxplot=400;export minplot=100;delta=50.;name_from_here=1;title="Down lw surface";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/strd_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobs";export cmp2obs_ncl=$cmp2obs;;
   FLNT)varobs=var179;export maxplot=310;export minplot=115;delta=15.;name_from_here=1;title="Net lw Top of Model";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/tntr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobs" ;export cmp2obs_ncl=$cmp2obs;;
   FSDS)varobs=var169;export maxplot=300;export minplot=25;delta=25.;name_from_here=1;title="Downward sw surface";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/ssrd_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobs";export cmp2obs_ncl=$cmp2obs;;
   FSNS)varobs=var176;export maxplot=300;export minplot=25;delta=25.;name_from_here=1;title="Net sw surface";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/snsr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobs";export cmp2obs_ncl=$cmp2obs;;
   FSNTOA)varobs=var178;export maxplot=420;export minplot=30;delta=30.;name_from_here=1;title="Net sw Top of the Atmosphere";export maxplotdiff=40;export minplotdiff=-40;deltadiff=10.;obsfile="$dir_obs3/tnsr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobs";export cmp2obs_ncl=$cmp2obs;;
   FSNT)varobs=var178;export maxplot=420;export minplot=30;delta=30.;name_from_here=1;title="Net sw Top of Model";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/tnsr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobs";export cmp2obs_ncl=$cmp2obs;;
   FLNS)varobs=var177;export maxplot=200.;export minplot=0.;delta=20.;name_from_here=1;title="Net lw surface";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/sntr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobs";export cmp2obs_ncl=$cmp2obs;;
   LHFLX)varobs=var147;export maxplot=300;export minplot=-20;delta=20.;name_from_here=1;title="Latent Heat Flux";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/slhf_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobs";export cmp2obs_ncl=$cmp2obs;;
   SHFLX)varobs=var146;export maxplot=300;export minplot=-20;delta=20.;name_from_here=1;title="Sensible Heat Flux";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/sshf_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobs";export cmp2obs_ncl=$cmp2obs;;

   SNOW) title="Atmospheric Snow";cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
   SNOWDP)title="Snow Depth ";varobs=sd;export maxplot=3.;export minplot=0.1;delta=.1;units_from_here=1;name_from_here=1;units="m";obsfile="$dir_obs1/ERA5T/sd/sd_1993-2017.ymean.nc";cmp2obs_anncyc=0;export cmp2obs_ncl=0;maxplotdiff=5;minplotdiff=-5;deltadiff=1;;
   TWS) title="Total Water Storage";cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
   TSOI) title="Soil Temp at 80cm";name_from_here=1;cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
   TLAI)varobs=var167;export maxplot=11.;export minplot=1.;delta=1.;cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
   QOVER)title="Total Surface Runoff";export maxplot=0.0003;export minplot=0.;delta=.00005;name_from_here=1;cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
   *)title="";delta=0.;name_from_here=0;cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
esac
#            export taxis="$varmod $units"
mkdir -p $pltdir
   # now 2d maps
if [[ $do_2d_plt -eq 1 ]]
then
   for comp in $comp
   do
      case $comp in
         atm)typelist="h3";; 
         lnd)typelist="h0";; 
         ice)typelist="h";; 
      esac
      for ftype in $typelist
      do
         echo "---now plotting 2d $varmod"
         export inpfile=$dirdiag/$varmod/CLIM/${realm}.$ftype.$st.$varmod.clim.$startyear-${lasty}.$nmaxens.nc
         if [[ ! -f $inpfile ]]
         then
            continue
         fi
#units defined only where conversion needed
         export title1="$iniy_hind-${lasty}"
         export right="[$units]"
         export left="$varmod"
         export lead
         mkdir -p $SCRATCHDIR/tmp/scripts/
         for lead in 0 1 2 3
         do
            export pltname=$pltdir/BIAS.$varmod.$st.map_l${lead}.$startyear-${lasty}.$nmaxens.png
            rsync -auv plot_2d_maps_and_diff.ncl $SCRATCHDIR/tmp/scripts/plot_2d_maps_and_diff.$st.$varmod.ncl
            ncl $SCRATCHDIR/tmp/scripts/plot_2d_maps_and_diff.$st.$varmod.ncl
            if [[ $pltype == "x11" ]]
            then
               exit
            fi  
         done
      done
   done
fi   # end 2d maps
if [[ $do_anncyc -eq 1 ]]
then
   export inpfile=$dirdiag/${SPSSystem}.$realm.$varmod.$iniclim-$lasty.anncyc.nc
   list_reg_anncyc="Global NH SH"
   if [[ $varmod == "U010" ]]
   then
      list_reg_anncyc="Global NH SH u010"
   fi
   export bextraTNH_W=0;export bAfricaSH=0;export bAfricaNH=0;export bAmazon=0;export bextraTNH_E=0;export bglo=0;export bNH=0;export SH=0;export bland=0;export boce=0;export bu010=0
   for reg in $list_reg_anncyc
   do
      case $reg in
         Global)export lat0=-90;export lat1=90;export bglo=1;;
         NH)export lat0=0;export lat1=90;export bNH=1;;
         SH)export lat0=-90;export lat1=0;export bSH=1;;
         u010)export lat0=59.5;export lat1=60.5;export bu010=1;;
      esac
      regfile=$dirdiag/`basename $inpfile|rev|cut -d '.' -f2-|rev`.$reg.nc
      if [[ ! -f $regfile ]]
      then
         cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $inpfile $regfile
      fi
      if [[ $cmp2obs_ncl -eq 1 ]]
      then
         regfileobs=$dirdiag/`basename $obsfile|rev|cut -d '.' -f2-|rev`.$reg.nc
         if [[ ! -f $regfileobs ]]
         then
            cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $obsfile $regfileobs
         fi
      fi
   done
   export rootinpfileobs=$dirdiag/`basename $obsfile|rev|cut -d '.' -f2-|rev` 
   export inpfileanncyc=$dirdiag/`basename $inpfile|rev|cut -d '.' -f2-|rev` 
   export pltname=$pltdir/${SPSSystem}.$comp.$varmod.$startyear_anncyc-$lasty.anncyc_3.png
   rsync -auv plot_anncyc.ncl $dirdiag/scripts/plot_anncyc.$varmod.ncl
   ncl $dirdiag/scripts/plot_anncyc.$varmod.ncl
   if [[ $pltype == "x11" ]]
   then
      exit
   fi
   export lat0; export lat1; export lon0;export lon1
   export bglo=0;export bNH=0;export bSH=0;export bextraTNH_E=0;export bextraTNH_W=0;export AfricaSH=0;export AfricaNH=0;export Amazon=0
   list_reg_anncyc="extraTNH_E extraTNH_W AfricaSH AfricaNH Amazon"
   if [[ $varmod == "SNOWDP" ]]
   then
      list_reg_anncyc="extraTNH_E extraTNH_W"
   fi
   for reg in $list_reg_anncyc
   do
      case $reg in
         extraTNH_E)lat0=45;lat1=90;lon0=30;lon1=180;bextraTNH_E=1;;
         extraTNH_W)lat0=45;lat1=90;lon0=-180;lon1=-30;bextraTNH_W=1;;
         AfricaNH)lat0=0;lat1=35;lon0=-20;lon1=35;bAfricaNH=1;;
         AfricaSH)lat0=-36;lat1=0;lon0=10;lon1=35;bAfricaSH=1;;
         Amazon)lat0=-50;lat1=12;lon0=-76;lon1=-45;bAmazon=1;;
      esac
      regfile=$dirdiag/`basename $inpfile|rev|cut -d '.' -f2-|rev`.$reg.nc
      if [[ ! -f $regfile ]]
      then
         cdo fldmean -sellonlatbox,$lon0,$lon1,$lat0,$lat1 $inpfile $regfile
      fi
      if [[ $cmp2obs_ncl -eq 1 ]]
      then
         regfileobs=$dirdiag/`basename $obsfile|rev|cut -d '.' -f2-|rev`.$reg.nc
         if [[ ! -f $regfileobs ]]
         then
            cdo fldmean -sellonlatbox,$lon0,$lon1,$lat0,$lat1 $obsfile $regfileobs
         fi
      fi
   done
   export rootinpfileobs=$dirdiag/`basename $obsfile|rev|cut -d '.' -f2-|rev`
   export inpfileanncyc=$dirdiag/`basename $inpfile|rev|cut -d '.' -f2-|rev`
   export pltname=$pltdir/${SPSSystem}.$comp.$varmod.$startyear_anncyc-$lasty.anncyc_5.png
   ncl $dirdiag/scripts/plot_anncyc.$varmod.ncl
   if [[ $pltype == "x11" ]]
   then
      exit
   fi
fi   # end annual cycle
if [[ $do_znl_atm2d -eq 1 ]]
then
   if [[ $comp == "atm" ]]
   then
      for sea in JJA DJF ANN
      do
         export inpfileznl=$dirdiag/${SPSSystem}.$comp.$varmod.$startyear-${lasty}.znl.$sea.nc
         if [[ ! -f $inpfileznl ]]
         then
            inpfileznl=$dirdiag/${SPSSystem}.$comp.$varmod.$startyear-${lasty}.znlmean.$sea.nc
            if [[ ! -f $inpfileznl ]]
            then
               anncycfile=$dirdiag/${SPSSystem}.$realm.$varmod.$startyear-$lasy.anncyc.nc 
               if [[ $sea != "ANN" ]]
               then
                  cdo timmean -selseason,$sea -zonmean $anncycfile $inpfileznl
               else
                  cdo timmean -zonmean $anncycfile $inpfileznl
               fi
            fi
         fi
         if [[ $cmp2obs -eq 1 ]]
         then
            obsfileznl=$scratchdir/$varmod.obs.$sea.znlmean.nc1
            if [[ ! -f $obsfileznl  ]]
            then
               if [[ $sea != "ANN" ]]
               then
                  cdo timmean -selseason,$sea -zonmean $obsfile $obsfileznl
               else
                  cdo timmean -zonmean $obsfile $obsfileznl
               fi
            fi
         fi
         rsync -auv plot_znlmean_2dfields.ncl $dirdiag/scripts/plot_znlmean_2dfields.$varmod.ncl
         ncl $dirdiag/scripts/plot_znlmean_2dfields.$varmod.ncl
      done
   fi
fi
if [[ $do_znl_lnd -eq 1 ]]
then
   if [[ $comp == "lnd" ]]
   then
      varmod=H2OSNO
      # snow over Syberia
      for sea in JJA DJF ANN
      do
         export inpfileznl=$dirdiag/${SPSSystem}.$comp.$varmod.$startyear-${lasty}.znl.$sea.nc
         if [[ ! -f $inpfileznl ]]
         then
            listafznl=""
            for yyyy in `seq -f "%04g" $startyear $finalyear`
            do
               inpfileznlyyyy=$dirdiag/${SPSSystem}.$comp.$varmod.$startyear-${lasty}.znl.$sea.nc
               if [[ ! -f $inpfileznlyyyy ]]
               then
                  cdo selseason,$sea -zonmean -sellonlatbox,90,140,0,90 $dirdiag/${SPSSystem}.$realm.$varmod.$yyyy.nc $inpfileznlyyyy
               fi
               listafznl+=" $inpfileznlyyyy"
            done
            cdo -mergetime $listafznl $inpfileznl
         fi
# qui dovrebbe essere lanciato 
#                  ncl plot_hov_lnd.ncl
# testato solo su Zeus VA MOLTO ADATTATO!!
      done
   fi
fi
