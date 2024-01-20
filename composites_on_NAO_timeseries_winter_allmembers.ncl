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
lasty=2003
year=ispan(1993,lasty,1)
anno=sprinti("%0.4i", year)
st=11
pathfile="/work/csp/as34319/diagnostics/SPS4_hindcast/"+st+"/PSL/ANOM/"
all_filem=pathfile+"cam.h3."+anno+st+".PSL.all_anom.1993-"+lasty+".13.nc"

fallm=addfiles(all_filem,"r")
ListSetType(fallm,"join")
mslptmp=fallm[:]->$varf$
;this holds for November start-date only!!!
mslpDJF=dim_avg_n_Wrap(mslptmp(:,:,1:3,:,:),2)
delete(mslptmp)
;center the matrix on 0. longitude (necessary to select NAO domain)
mslptmp = lonFlip(mslpDJF)
lat=fallm[:]->lat(0,:)
lon=fallm[:]->lon(0,:)
wgt = sqrt(cos(tofloat(lat)*deg2rad))
mslptmp=mslptmp*conform(mslptmp, wgt, 2)
NN=dimsizes(mslptmp)
print(NN)
nens=NN(1)
ny=NN(0)
nlat=NN(2)
nlon=NN(3)
; --- flip longitude coordinate
lon0 = lon
lonn = lon({lon(nlon/2):lon(nlon-1)})
lonn = (/lonn-360./)
nlonn = dimsizes(lonn)
lonp = lon({lon(0):lon(nlon/2-1)})
nlonp = dimsizes(lonp)
lon0(0:nlonn-1) = lonn
lon0(nlonn:nlon-1) = lonp
;print(lon0)

mslp_clim=dim_avg_n_Wrap(mslptmp,0)
printVarSummary(mslp_clim)
mslpMOD=new((/ny,nens,nlat,nlon/),"float")
mslpMOD!2="lat"
mslpMOD!3="lon"
mslpMOD&lat=lat
mslpMOD&lon=lon0
do y=0,ny-1
   mslpMOD(y,:,:,:)=mslptmp(y,:,:,:)-mslp_clim
end do

;---- Calculate Model standard yearly deviation 
mslpMOD_reshaped=reshape(mslpMOD,(/ny*nens,nlat,nlon/))
stdmslpMOD=dim_stddev_n_Wrap(mslpMOD_reshaped,0)
stdmslpMOD!0="lat"
stdmslpMOD!1="lon"
stdmslpMOD&lat=lat
stdmslpMOD&lon=lon0

;=====================================================
; compute the 3 NAOI for model
;=====================================================
NAO_mod=new((/nens,ny/),"float")
NAO_mod@_FillValue=-999.
printVarSummary(mslpMOD)
printVarSummary(stdmslpMOD)
do y=0,ny-1
do ie=0,nens-1
   posi = dim_avg_n(dim_avg_n(mslpMOD(y,ie,{inilatposi:endlatposi},{inilon:endlon})/stdmslpMOD({inilatposi:endlatposi},{inilon:endlon}),0),0)
   nega=dim_avg_n(dim_avg_n(mslpMOD(y,ie,{inilatnega:endlatnega},{inilon:endlon})/stdmslpMOD({inilatnega:endlatnega},{inilon:endlon}),0),0)
   NAO_mod(ie,y)  = posi-nega
end do
end do

varf="PRECT"
;varf="TREFHT"
pathfile="/work/csp/as34319/diagnostics/SPS4_hindcast/"+st+"/"+varf+"/ANOM/"
all_filem=pathfile+"cam.h3."+anno+st+"."+varf+".all_anom.1993-"+lasty+".13.nc"

fallm=addfiles(all_filem,"r")
ListSetType(fallm,"join")
vartmp=fallm[:]->$varf$
;this holds for November start-date only!!!
varmean=dim_avg_n_Wrap(vartmp(:,:,1:3,:,:),2)
delete(vartmp)
; flip var wrt longitude (necessary to select NAO domain)
varDJF = lonFlip(varmean)
mean_DJF_var=dim_avg_n_Wrap(dim_avg_n_Wrap(varDJF,0),0)
varposi=new((/nlat,nlon/),typeof(varDJF))
varnega=new((/nlat,nlon/),typeof(varDJF))

varposi=0.
varnega=0.
icn=0
icp=0
do iy=0,ny-1
   do ie=0,nens-1
      if(NAO_mod(ie,iy).gt.1.)then
;      if(NAO_mod(ie,iy).gt.0.5)then
         varposi=varDJF(iy,ie,:,:)+varposi
         icp=icp+1
      end if
      if(NAO_mod(ie,iy).lt.-1.)then
;      if(NAO_mod(ie,iy).lt.-0.5)then
         varnega=varDJF(iy,ie,:,:)+varnega
         icn=icn+1
      end if
   end do
end do

if(varf.eq."TREFHT")then
   cf=1
  cmap = read_colormap_file("hotcold_18lev")
end if
if(varf.eq."PRECT")then
   cf=86400*1000
  cmap = read_colormap_file("precip_diff_12lev")
end if
varposi=(varposi/tofloat(icp)-mean_DJF_var)*cf
varnega=(varnega/tofloat(icn)-mean_DJF_var)*cf
copy_VarMeta(varDJF(0,0,:,:),varposi)
copy_VarMeta(varDJF(0,0,:,:),varnega)

 wks = gsn_open_wks("x11","/work/csp/as34319/diagnostics/SPS4_hindcast/plots/"+st+"/indices/"+varf+"_"+nens+"member_composites_on_winter_NAO_1993-"+lasty)              ; send graphics to PNG file
  plot = new(2,graphic)                          ; create a plot array

  res                     = True
  res@gsnDraw             = False           ; don't draw
  res@gsnFrame            = False           ; don't advance frame
  res@cnInfoLabelOn       = False           ; turn off cn info label
  res@cnFillOn            = True            ; turn on color
  res@cnFillPalette       = cmap
  res@cnLineLabelsOn      = False
  res@lbLabelBarOn        = False           ; turn off individual cb's
  res@mpMinLatF            = 20
  res@mpMaxLatF            = 90
  res@mpMinLonF            = -80
  res@mpMaxLonF            = 50

; to have a common label bar, both plots should be set to the same interval
; b/c the label bar is drawn by default from the interval of the first plot.
  res@cnLevelSelectionMode="ExplicitLevels"
  res@cnLevels     = (/-2.5,-2,-1.5,-1,-.5,-0.2,0.2,.5,1,1.5,2,2.5/)



  res@gsnCenterString = "Positive Phase"
  if(varf.eq."PRECT")then
     res@gsnRightString   = "[mm/day]"
     res@gsnLeftString   = "PRECT"
  end if
  if(varf.eq."TREFHT")then
     res@gsnRightString   = "[Celsius deg]"
     res@gsnLeftString   = "T2m"
  end if
  plot(0) = gsn_csm_contour_map (wks,varposi,res)
  res@gsnCenterString = "Negative Phase"
  plot(1) = gsn_csm_contour_map (wks,varnega,res)


  resP                     = True                ; modify the panel plot
  resP@gsnPanelMainString = "Composites on NAO winter model index (Li and Wang)"

  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@lbLabelFontHeightF  = 0.01               ; make labels smaller

  gsn_panel(wks,plot,(/2,1/),resP)               ; now draw as one plot
end
