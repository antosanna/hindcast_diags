begin

;------ Select IOD-W and IOD-E regions
inilatposi=34
endlatposi=36
inilatnega=64
endlatnega=66
inilon=-80
endlon=30

;=======================================================
; constants
;=======================================================
  deg2rad=4.*atan(1.)/180.

;------ Load model files
varf="PSL"
year=ispan(1993,2003,1)
anno=sprinti("%0.4i", year)
pathfile="/work/csp/as34319/diagnostics/SPS4_hindcast/11/PSL/ANOM/"
all_filem=pathfile+"cam.h3."+anno+"11.PSL.ens_anom.1993-2003.13.nc"

fallm=addfiles(all_filem,"r")
ListSetType(fallm,"join")
mslptmp=fallm[:]->$varf$
mslpDJF=dim_avg_n_Wrap(mslptmp(:,1:3,:,:),1)
delete(mslptmp)
printVarSummary(mslpDJF)
mslptmp = lonFlip(mslpDJF)
lat=fallm[:]->lat(0,:)
lon=fallm[:]->lon(0,:)
wgt = sqrt(cos(tofloat(lat)*deg2rad))
mslptmp=mslptmp*conform(mslptmp, wgt, 1)
NN=dimsizes(mslptmp)
ny=NN(0)
nlat=NN(1)
nlon=NN(2)
; --- flip longitude coordinate
lon0 = lon
lonn = lon({lon(nlon/2):lon(nlon-1)})
lonn = (/lonn-360./)
nlonn = dimsizes(lonn)
lonp = lon({lon(0):lon(nlon/2-1)})
nlonp = dimsizes(lonp)
lon0(0:nlonn-1) = lonn
lon0(nlonn:nlon-1) = lonp

mslp_clim=dim_avg_n_Wrap(mslptmp,0)
mslpMOD=mslptmp
do y=0,ny-1
   mslpMOD(y,:,:)=mslptmp(y,:,:)-mslp_clim
end do

;---- Calculate Model standard yearly deviation 
stdmslpMOD=dim_stddev_n_Wrap(mslpMOD,0)

;=====================================================
; compute the 3 NAOI for model
;=====================================================
NAO_mod=new((/ny/),"float")
NAO_mod@_FillValue=-999.
printVarSummary(mslpMOD)
printVarSummary(stdmslpMOD)
do y=0,ny-1
   posi=dim_avg_n(dim_avg_n(mslpMOD(y,{inilatposi:endlatposi},{inilon:endlon})/stdmslpMOD({inilatposi:endlatposi},{inilon:endlon}),0),0)
   nega=dim_avg_n(dim_avg_n(mslpMOD(y,{inilatnega:endlatnega},{inilon:endlon})/stdmslpMOD({inilatnega:endlatnega},{inilon:endlon}),0),0)
   NAO_mod(y)  = posi-nega
end do

printVarSummary(NAO_mod)


;time=new((/ny*nt/),"float",-999)
;do t=0,(ny*nt)-1
;   time(t)=t
;end do

; ------ plot seetings
colors = (/"red","black"/)

wks = gsn_open_wks("x11","test_SPS4")

res = True

res@gsnDraw               = True             ; don't draw yet
res@gsnFrame              = True
res@gsnMaximize           = True 
res@trYMinF                  = -4.
res@trYMaxF                  = 4.
res@tiMainFontHeightF        = 0.023
res@tiMainString             = ""
res@tmXTBorderOn             = True
res@tmYRBorderOn             = True
res@tmYUseLeft               = True
res@vpXF                     = 0.15
res@vpYF                     = 0.9

res@vpWidthF                 = 0.8
res@vpHeightF                = 0.4
res@tiYAxisString            =  ""
res@tiXAxisString            =   ""
res@gsnLeftString = ""
res@gsnRightString = ""
res@gsnCenterString = "NAO (Li and Wang, 2003)"
res@tmXBLabelDeltaF          = 1
res@tmXBLabelFontHeightF     = 0.015
res@tmXBLabelAngleF          = 90
res@tmXBLabelJust            = "CenterCenter"
;res@trXMinF    = 1993
;res@trXMaxF    = 2003
res@tmXBMode   = "Explicit"
res@tmXBValues = "f"     ; choose first 13 timesteps

res@xyLineColor     = "Black"
res@xyLineThicknessF= 2

plot = gsn_csm_y (wks,NAO_mod,res)
res@xyLineColor     = "Red"
res@xyLineThicknessF= 2


getvalues plot2                      ; Get plot size for use in
  "vpHeightF" : vph                 ; determining size of
  "vpWidthF"  : vpw                 ; labelbar.
end getvalues

;***********************************************
; legend resources
;***********************************************
gres = True
gres@YPosPercent = 95.    ; expressed as %, 0->100, sets position of top border of legend
                            ;  when gres@Position is set to its default setting of "Top" (Default = 95.)
gres@XPosPercent = 5      ; expressed as %, 0->100, sets position of left border of legend(Default = 5.)

lineres = True
lineres@lgLineColors = (/"Red","Black"/) ; line colors
lineres@lgLineThicknesses = 2.5                        ; line thicknesses
lineres@LineLengthPercent = 7.

textres = True
textres@lgLabels = (/"ERA5","CMCC-CM3"/)  ; legend labels (required)

plot2 = simple_legend(wks,plot,gres,lineres,textres)

draw(plot2)
frame(wks)

end
