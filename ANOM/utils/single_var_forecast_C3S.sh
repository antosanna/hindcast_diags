#!/bin/sh
#BSUB -o forecast_%J.out  # Appends std output to file %J.out.
#BSUB -e forecast_%J.err  # Appends std error to file %J.err.
#BSUB -q serial_6h       # queue
#BSUB -n 1               # Number of CPUs

set -ex

export yyyyfore=2019
echo $yyyyfore
export mmfore=01
mfore=$((10#$mmfore))

export varm=PREC #TREFHT
case $varm
in
   TREFHT) varobs=t2m;;
   PREC) varobs=precip;;
esac
case $varobs
in
   t2m) dirobs=T2m;;
   PREC) dirobs=PREC;;
esac
data=/work/sp2/seasonal/NCEP
dataSPS3=/work/sp2/SPS3/CESM/monthly/
# -------------------------------
# select the season
# minis=month in which the verifyied season begins
# yyyy0=year in which lead0 season begins
# yyyy1=year in which lead1 season begins
# yyyy2=year in which lead2 season begins
# -------------------------------
yyyys=( $yyyyfore $yyyyfore $yyyyfore $yyyyfore )
ms=( $mmfore $mmfore $mmfore $mmfore )                             
ms2=`printf '%.2d' $((10#$mfore + 1))`      #mese inizio lead1
ms[2]=$ms2
if [ $ms2 -eq 13 ]
then
  ms[2]=1
  yyyys[2]=$(($yyyyfore + 1))
fi
ms3=`printf '%.2d' $((10#$mfore + 2))`      #mese inizio lead2
ms[3]=$ms3
if [ $ms3 -eq 13 ]
then
  ms[3]=1
  yyyys[2]=$(($yyyyfore + 1))
fi
# -------------------------------
# go to working dir
# -------------------------------
cd $HOME/SPS3/postproc/SeasonalForecast/FORECAST/
# -------------------------------
# go to graphic dir
# -------------------------------
# plot current conditions wrt 1993-2016
# -------------------------------
cd ncl
export anomfile="$data/${varobs}_NCEP_${yyyy2ver}${mm2ver}_ano.nc"
export obsfile="$data/${varobs}_NCEP_${yyyy2ver}${mm2ver}.nc"
export obsfile2="$data/${varobs}_NCEP_clim.${mm2ver}.1993-2016.nc"

# -------------------------------
# go to graphic dir
# -------------------------------

export fn="$dataSPS3/${varm}/C3S/anom/${varm}_SPS3_sps_${yyyyfore}${mmfore}_ens_ano.1993-2016.nc"

#ncl ${varobs}_month1_glo.ncl
#ncl ${varobs}_month1_Europe.ncl

export S=( "ppp" "ppp" "ppp" "ppp" )
case $mmfore 
 in
 01) S[1]="JFM";S[2]="FMA";S[3]="MAM";S[4]="AMJ";;
 02) S[1]="FMA";S[2]="MAM";S[3]="AMJ";S[4]="MJJ";;
 03) S[1]="MAM";S[2]="AMJ";S[3]="MJJ";S[4]="JJA";;
 04) S[1]="AMJ";S[2]="MJJ";S[3]="JJA";S[4]="JAS";;
 05) S[1]="MJJ";S[2]="JJA";S[3]="JAS";S[4]="ASO";;
 06) S[1]="JJA";S[2]="JAS";S[3]="ASO";S[4]="SON";;
 07) S[1]="JAS";S[2]="ASO";S[3]="SON";S[4]="OND";;
 08) S[1]="ASO";S[2]="SON";S[3]="OND";S[4]="NDJ";;
 09) S[1]="SON";S[2]="OND";S[3]="NDJ";S[4]="DJF";;
 10) S[1]="OND";S[2]="NDJ";S[3]="DJF";S[4]="JFM";;
 11) S[1]="NDJ";S[2]="DJF";S[3]="JFM";S[4]="FMA";;
 12) S[1]="DJF";S[2]="JFM";S[3]="FMA";S[4]="MAM";;
esac

# -------------------------------
#lead-time0
# -------------------------------
for l in 2 3
do
  export lead=$(($l - 1))
  export SS=${S[$l]}
  export problowfile="$dataSPS3/${varm}/C3S/anom/prob/${varm}_SPS3_sps_${yyyyfore}${mmfore}_l${lead}_prob_low.1993-2016.nc"
#not in use at the moment
#  export probnormfile="$dataSPS3/${varm}/C3S/anom/prob/${varm}_SPS3_sps_${yyyyfore}${mmfore}_l${lead}_prob_norm.1993-2016.nc"
  export probupfile="$dataSPS3/../pctl/${varm}_${mmfore}_l${lead}_66.nc"
  export problowfile="$dataSPS3/../pctl/${varm}_${mmfore}_l${lead}_33.nc"
  export inputm="$dataSPS3/${varm}/C3S/anom/${varm}_SPS3_sps_${yyyyfore}${mmfore}_ens_ano.1993-2016.nc"
  export inputmall="$dataSPS3/${varm}/C3S/anom/${varm}_SPS3_sps_${yyyyfore}${mmfore}_all_ano.1993-2016.nc"

  export wks_type=png
  for region in global SH NH global Europe Tropics
  do
     export region=$region
     case $region 
     in
        Europe) export minlat=20
                export maxlat=65
                export minlon=-40
                export maxlon=50
                export proj="Satellite"
                export bnd="National"
                export lon0="10"
                export lat0="40"
                export lbx=0.16
                export lby=0.06
        ;;
        SH)     export minlat=-90
                export maxlat=0
                export minlon=-180
                export maxlon=180
                export proj="Satellite"
                export bnd=""
                export lon0="0"
                export lat0="-90"
                export lbx=0.28
        ;;
        NH)     export minlat=0
                export maxlat=90
                export minlon=-180
                export maxlon=180
                export proj="Satellite"
                export bnd=""
                export lon0="0"
                export lat0="90"
                export lbx=0.28
        ;;
        Tropics)export minlat=-30
                export maxlat=30
                export minlon=-180
                export maxlon=180
                export proj="CylindricalEquidistant"
                export bnd=""
                export lon0="0"
                export lat0="0"
                export lbx=0.16
        ;;
        global) export minlat=-90
                export maxlat=90
                export minlon=-180
                export maxlon=180
                export proj="Robinson"
                export bnd=""
                export lon0="0"
                export lbx=0.16
        ;;
     esac
     ncl ${varobs}_season_lead_ensmean.ncl
     ncl ${varobs}_season_lead_problow.ncl
     ncl ${varobs}_season_lead_probup.ncl
# this is to trim the picture
     convert -trim +repage $HOME/SPS3/postproc/SeasonalForecast/FORECAST/ncl/plots/${varobs}_${region}_ens_anom_${yyyyfore}_${mmfore}_l${lead}.png $HOME/SPS3/postproc/SeasonalForecast/webpage/forecast/${varobs}_${region}_ens_anom_${yyyyfore}_${mmfore}_l$lead.png
     convert -trim +repage $HOME/SPS3/postproc/SeasonalForecast/FORECAST/ncl/plots/${varobs}_${region}_prob_up_tercile_${yyyyfore}_${mmfore}_l${lead}.png $HOME/SPS3/postproc/SeasonalForecast/webpage/forecast/${varobs}_${region}_prob_up_tercile_${yyyyfore}_${mmfore}_l$lead.png
     convert -trim +repage $HOME/SPS3/postproc/SeasonalForecast/FORECAST/ncl/plots/${varobs}_${region}_prob_low_tercile_${yyyyfore}_${mmfore}_l${lead}.png $HOME/SPS3/postproc/SeasonalForecast/webpage/forecast/${varobs}_${region}_prob_low_tercile_${yyyyfore}_${mmfore}_l$lead.png
  done
done

# -------------------------------
# ALL DONE
# -------------------------------
