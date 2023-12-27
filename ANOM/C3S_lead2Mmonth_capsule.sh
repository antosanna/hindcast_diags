#!/bin/sh -l

. $HOME/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh
. $DIR_TEMPL/load_cdo

set -euvx

# Inputs
yy=$1
st=$2
nrun=$3
datamm=$4
workdir=$5
var=$6
#freq=$7
version=$7
scriptsdir=$8
mymail=$9


# CurrentDir
cdir=$scriptsdir

# Datadir
fc="${yy}${st}" 
# A.B.: 16/01/2023
#Definire in maniera univoca!!! 
#datadir="$FINALARCHC3S1/${fc}"
# temporaneamente e' definita cosi':
if [ $var = "precip" ] || [ $var = "sf" ] || [ $var = "mrlsl" ]
then
   datadir="$FINALARCHC3S1/${fc}"
elif [ $var = "snwdpt" ]
then
   datadir=$DATA_ARCHIVE1/CESM/SPS3.5/C3S/${fc}
else
   datadir="/work/csp/sps-dev/scratch/C3Sdaily_new/${fc}"
fi
# Create Dirs
mkdir -p $datamm
[ -d $workdir ] && rm -rf $workdir
mkdir -p $workdir
cd $workdir

# Variables cases
case $var
in
	t2m)     varC3S=tas    ; option="-subc,273.15"       ; hour="12:00:00" ; incr="day";;
	sst)     varC3S=tso    ; option=""                   ; hour="12:00:00" ; incr="day";;
	precip)  varC3S=lwepr  ; option="-mulc,1000"         ; hour="12:00:00" ; incr="day";;
	snprec)  varC3S=lweprsn  ; option="-mulc,1000"       ; hour="12:00:00" ; incr="day";;
	snwdpt)  varC3S=lwesnw ; option=""                   ; hour="12:00:00" ; incr="day";;
	sic)     varC3S=sic    ; option=""                   ; hour="12:00:00" ; incr="day";;
	mslp)    varC3S=psl    ; option="-divc,100"          ; hour="12:00:00" ; incr="day";;
	u10)     varC3S=uas    ; option=""                   ; hour="12:00:00" ; incr="day";;
	v10)     varC3S=vas    ; option=""                   ; hour="12:00:00" ; incr="day";;
	z200)    varC3S=zg     ; option="-sellevel,20000"    ; hour="12:00:00" ; incr="day";;
	z500)    varC3S=zg     ; option="-sellevel,50000"    ; hour="12:00:00" ; incr="day";;
	t850)    varC3S=ta     ; option="-sellevel,85000"    ; hour="12:00:00" ; incr="day";;
	u925)    varC3S=ua     ; option="-sellevel,92500"    ; hour="12:00:00" ; incr="day" ;;
	v925)    varC3S=va     ; option="-sellevel,92500"    ; hour="12:00:00" ; incr="day" ;;
	u850)    varC3S=ua     ; option="-sellevel,85000"    ; hour="12:00:00" ; incr="day" ;;
	v850)    varC3S=va     ; option="-sellevel,85000"    ; hour="12:00:00" ; incr="day" ;;
	u200)    varC3S=ua     ; option="-sellevel,20000"    ; hour="12:00:00" ; incr="day" ;;
	v200)    varC3S=va     ; option="-sellevel,20000"    ; hour="12:00:00" ; incr="day" ;;
 ssh)     varC3S=zos        ; option=""               ; hour="12:00:00" ; incr="month" ;;
 thetaot) varC3S=thetaot300 ; option=""               ; hour="12:00:00" ; incr="month" ;;
 evap)    varC3S=lwee       ; option=""               ; hour="12:00:00" ; incr="day" ;;
 mrroa)   varC3S=mrroa      ; option=""               ; hour="12:00:00" ; incr="day" ;;
 mrlsl)   varC3S=mrlsl      ; option=""               ; hour="12:00:00" ; incr="day" ;;
 prw)     varC3S=prw        ; option=""               ; hour="12:00:00" ; incr="day" ;;
 sf)      varC3S=ua         ; option=""               ; hour="12:00:00" ; incr="day" ;;
esac

#CHECK if the files was already produced
if [[ ${varC3S} = "mrroa" ]] ; then
   set +e
   nf=`ls -1 $datadir/*mrroab_*.nc | head -n $nrun | wc -l`
   nfu=0
   nfv=0
   set -e
elif [[ $var = "sf" ]] ; then
   set +e
   nf=0
   nfu=`ls -1 $datadir/*_ua_*.nc | head -n $nrun | wc -l`
   nfv=`ls -1 $datadir/*_va_*.nc | head -n $nrun | wc -l`
   set -e
else
   set +e
   nf=`ls -1 $datadir/*${varC3S}_*.nc | head -n $nrun | wc -l`
   nfu=0
   nfv=0
   set -e
fi
if [[ $nf -eq $nrun ]]
then
   if [[ ${varC3S} = "mrroa" ]] ; then
      flist=`ls -1 $datadir/*mrroab_*.nc | head -n $nrun`
   else
      flist=`ls -1 $datadir/*${varC3S}_*.nc | head -n $nrun`
   fi
elif [[ $nfu -eq $nrun ]] && [[ $nfv -eq $nrun ]] ; then
   flist=`ls -1 $datadir/*${varC3S}_*.nc | head -n $nrun`
else 
   echo "The files have not been produced yet!"
   exit
fi
for ff in $flist ; do
  
  pp=`basename $ff | cut -d '_' -f9 | cut -d '.' -f1 | cut -c2-3`
  ppp=`printf "%03d" $(( 10#${pp} ))`
	 sps="sps_${yy}${st}_${ppp}"
  finaloutput=${var}_SPS3.5_${sps}.nc
	 outputfile="${var}_${sps}.output.1.nc"  	#python_fst_output
	 intoutput="${var}_${sps}.output.2.nc"		#cdo intermediate output

#	if [ ! -f $datamm/$finaloutput ] ; then
		# GET Data
		#rsync -auv $datadir/*${varC3S}_*r${pp}i00p00.nc .
  
		#tfile=`ls -1 cmcc_CMCC-CM2-v${version}_*_S${yy}${st}0100_*_${varC3S}_r${pp}i00p00.nc`
		cd $datadir
  if [[ $varC3S = "mrroa" ]] ; then
		   tfile=`ls -1 cmcc_CMCC-CM2-v*_*_S${yy}${st}0100_*_mrroab_r${pp}i00p00.nc`
  else
		   tfile=`ls -1 cmcc_CMCC-CM2-v*_*_S${yy}${st}0100_*_${varC3S}_r${pp}i00p00.nc`
  fi
		cd -
		ppp=`printf "%03d" $(( 10#${pp} ))` 
		sps="sps_${yy}${st}_${ppp}"

		# declaring and final outputfile
		finalinputfile=${tfile}
		finaloutput=${var}_SPS3.5_${sps}.nc
  if [[ $varC3S = "mrroa" ]] ; then
     cdo add $datadir/cmcc_CMCC-CM2-v*_*_S${yy}${st}0100_*_mrroas_r${pp}i00p00.nc $datadir/cmcc_CMCC-CM2-v*_*_S${yy}${st}0100_*_mrroab_r${pp}i00p00.nc ${finalinputfile}
		   ncks -O -6 ${finalinputfile} ${finalinputfile}_tmp.nc
  elif [[ $var = "sf" ]] ; then
     echo "Il post processing della Stream Function sta per iniziare..."
  else
		   ncks -O -6 $datadir/${finalinputfile} ${finalinputfile}_tmp.nc
  fi
  if [[ $var != "sf" ]] ; then
		   cdo settaxis,$yy-$st-01,$hour,$incr ${finalinputfile}_tmp.nc ${finalinputfile}_tmp2.nc
		   cdo setreftime,$yy-$st-01,$hour ${finalinputfile}_tmp2.nc ${finalinputfile}_tmp3.nc
  fi
		#Decide to do mean or sum if precipitation
		case $varC3S
		 in
		 lweprsn)      stat="-monmean" ;;
		 *)            stat="-monmean" ;;
		esac
# 20220505 NEW for soil moisture
  if [[ $var = "mrlsl" ]] ; then
     export filein=${finalinputfile}_tmp3.nc
     export fileout=${outputfile}
     ncl $cdir/compute_swi.ncl
     #neglect moredays
     cdo -seltimestep,1/6 ${outputfile} ${outputfile}_tmp
     mv ${outputfile}_tmp ${outputfile}
     if [[ $? -ne 0 ]] ; then
        body="Something wrong with soil moisture. Exiting $cdir/compute_swi.ncl"
        title="SPS3.5 verification ERROR"
        ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
        exit 1
     fi
# 20230324 NEW for stream function
  elif [[ $var = "sf" ]]
  then
     ${cdir}/make_stream_function.sh $yy $st $ppp $cdir
     if [[ $? -ne 0 ]] ; then
        body="Something wrong with stream function. Exiting ${cdir}/make_stream_function.sh"
        title="SPS3.5 verification ERROR"
        ${DIR_SPS35}/sendmail.sh -m $machine -e $mymail -M "$body" -t "$title"
        exit 1
     fi 
  else
     #Make the monthly mean and neglect moredays
		   cdo -seltimestep,1/6 $stat $option ${finalinputfile}_tmp3.nc ${outputfile}
  fi

  # Here modify the units if needed 
  case $var
   in
   mslp)   ncatted -O -a units,psl,m,c,"hPa" ${outputfile} ;;
   precip) ncatted -O -a units,lwepr,m,c,"mm" ${outputfile} ;;
   t2m)    ncatted -O -a units,tas,m,c,"degC" ${outputfile} ;;
   snprec) ncatted -O -a units,lweprsn,m,c,"mm" ${outputfile} ;;
   prw)    ncatted -O -a units,$var,m,c,"mm" ${outputfile} ;;
  esac

  
  if [[ $var != "sf" ]] ; then
		   # set output of python in months
	   	cdo settunits,months ${outputfile} ${intoutput} 
	   	# set calendar to C3S standard
		   cdo setcalendar,365_day ${intoutput} ${finaloutput} 
		   # clean intermediate files
		   rm ${finalinputfile}_tmp*.nc
	   	rm ${outputfile} && rm ${intoutput} 
	
		   mv ${var}_SPS3.5_${sps}.nc $datamm
  fi
#	else
#		continue	
#	fi
	
done  #end loop on plist

touch $scriptsdir/logs/capsule_${yy}${st}_${var}_DONE
