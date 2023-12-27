#!/bin/sh -l
#BSUB -M 8500   #if you get BUS error increase this number
#BSUB -P 0516
#BSUB -J launch_ensmean_percentiles
#BSUB -e logs/launch_ensmean_percentiles%J.err
#BSUB -o logs/launch_ensmean_percentiles%J.out
#BSUB -q s_medium

. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh
. $DIR_UTIL/descr_ensemble.sh 1993
. $DIR_UTIL/load_cdo
set -euxv
# SECTION TO BE MODIFIED BY USER
st=07
debug=1
nmaxproc=6
sec1=1  #compute ensemble mean
sec2=0  # compute percentiles
export clim3d="ERA5"
sec4=0  #flag for section4 (=nemo postproc) (1=yes; 0=no)
do_atm=1
do_lnd=0
do_ice=0  #not implemented yet
export do_timeseries=1
do_znl_lnd=0  #not implemented yet
do_znl_atm2d=0  #not implemented yet
export do_2d_plt=1
export do_anncyc=1

# model to diagnose
#
export startyear=$iniy_hind
export startyear_anncyc=$iniy_hind #starting year to compute 2d map climatology
# select if you compare to model or obs 
export cmp2obs=1
# END SECTION TO BE MODIFIED BY USER

here=$PWD
export varobs
i=1
do_compute=1
dirdiag=/work/$DIVISION/$USER/diagnostics/SPS4_hindcasts
mkdir -p $dirdiag

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
echo 'Experiment : ' $SPSSystem
echo 'Processing year(s) period : ' $startyear ' - ' $endy_hind
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
mkdir -p $pltdir/atm $pltdir/lnd $pltdir/ice $pltdir/ocn $pltdir/namelists

export pltype="png"
if [[ $debug -eq 1 ]]
then
   pltype="x11"
fi
export units
export title
allvars_atm="PRECT" # TREFMXAV T850 PRECC ICEFRAC Z500 PSL TREFHT TS PRECT";
allvars_lnd="SNOWDP TLAI H2OSNO";
allvars_ice="aice hs hi";
allvars_oce="tos sos";
    
############################################
#  First section: postprocessing
############################################
nmaxens=15
echo 'NOW MAX ENSEMBLE SET TO '$nmaxens
if [[ $sec1 -eq 1 ]]
then
   model=CMCC-CM
   export inpdirroot=/work/csp/$USER/$model/archive/
   var2plot=" "
   export comp
   for comp in $comps
   do
      case $comp in
         atm)typelist="h3";; # h2 h3";; 
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
exit
############################################
#  end of second section
############################################
#
if [[ $sec3 -eq 1 ]]
then
     echo "in section 2 "$sec2 $comps
for comp in $comps
do
      case $comp in
         atm)typelist="h1" ;; # h2 h3";; 
         lnd)typelist="h0";; 
         ice)typelist="h";; 
      esac
      for ftype in $typelist
      do
         echo "-----going to postproc $comp"
         case $comp in
            atm) realm=cam 
                 case $ftype in
                    h1) allvars="TREFHT";; #PS TREFHT TS";;
                    h2) allvars="Z500 T850 U010 U250";;
                    h3) allvars="PRECT";;
                 esac
                 ;;
            lnd) allvars=$allvars_lnd; realm=clm2;;
            ice) allvars=$allvars_ice;realm=cice;;
         esac
         for varmod in $allvars
         do
            bsub -P 0566 -q s_medium -M 85000 -J diagnostics_single_var_${varmod} -e logs/diagnostics_single_var_${varmod}_%J.err -o logs/diagnostics_single_var_${varmod}_%J.out $here/diagnostics_single_var.sh $dirdiag $machine $st $cmp2obs $cmp2mod $pltype $varmod $comp $do_timeseries $do_2d_plt $do_atm $do_lnd $do_ice
            while `true`
            do
               ijob=`bjobs -w|grep diagnostics_single_var_|wc -l`
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
fi   # end of section2

############################################
#  End of second section
############################################

sleep 45
while `true`
do
   ijob=`bjobs -w|grep diagnostics_single_var|wc -l`
   if [[ $ijob -eq 0 ]]
   then
      break
   fi
   sleep 40
done


############################################
#  check that all diagnostic processes are completed
############################################
while `true`
do
   njob=`bjobs -w|grep diagnostics_sing_var_nemo|wc -l`
   if [[ $njob -gt 0 ]]
   then
      sleep 20
   else
      break
   fi
done

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

#if [[ -d $tmpdir1/scripts ]]
#then
#   rm -rf $tmpdir1/scripts
#fi

