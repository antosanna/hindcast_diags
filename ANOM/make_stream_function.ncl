begin

PLOT=False
FILEW=True

yyyy=getenv("yyyy")
st=getenv("st")
ens=getenv("ens")
filein_u=getenv("filein_u")
filein_v=getenv("filein_v")
fileout=getenv("fileout")

finu=addfile(filein_u,"r")
finv=addfile(filein_v,"r")
u=rm_single_dims(finu->ua(:,{20000:20000},:,:))
v=rm_single_dims(finv->va(:,{20000:20000},:,:))
dimvar=dimsizes(u)
ntime=dimvar(0)
nlat=dimvar(1)
nlon=dimvar(2)


uvmsg = 1e+36

sf    = new ( (/ntime,nlat,nlon /), float, uvmsg )  ; stream function
vp    = new ( (/ntime,nlat,nlon /), float, uvmsg )  ; velocity potential

uv2sfvpf (u,v,sf,vp) 
copy_VarMeta(u,sf)
printVarSummary(sf)
scale = 1e6                                      ; arbitrary: used for nicer plot values
psi = sf/scale
copy_VarMeta(sf,psi)
delete(sf)
; -- make monthly means
sftmp = calculate_monthly_values(psi, "avg", 0, False)
sf=sftmp(0:5,:,:)

if ( PLOT ) then
; ---- plot parameters
nt = 0                                           ; time index (1st time)

wks  = gsn_open_wks("png","wind")               ; send graphics to PNG file

  res                      = True

  res@cnFillOn             = True                 ; color on
  res@cnLinesOn            = False                ; turn off contour lines

  res@gsnScalarContour     = True                 ; vectors over contours
 ;res@cnFillPalette        = "BlAqGrYeOrReVi200"
  res@cnFillPalette        = "amwg256"

  res@vcRefMagnitudeF      = 3.                   ; make vectors larger
  res@vcRefLengthF         = 0.050                ; ref vector length
  res@vcGlyphStyle         = "CurlyVector"        ; turn on curly vectors
  res@vcMinDistanceF       = 0.012                ; thin the vectors
  res@vcRefAnnoOrthogonalPosF  = -0.13            ; Move ref anno into plot

  res@mpFillOn             = False              ; turn off map fill

  res@tiMainString         = "Streamfunction via Spherical Harmonics"     ; title
  res@gsnCenterString      = "Psi scaled by 1e6"  ; center string
  res@gsnLeftString        = "Rotational Wind"    ; left string

  res@vcMinDistanceF       = 0.017
  res@vcRefAnnoOrthogonalPosF = -1.0              ; move ref vector up
  res@vcRefMagnitudeF      = 10.0                 ; define vector ref mag
  res@vcRefLengthF         = 0.050                ; define length of vec ref

  res@cnMinLevelValF       = -120.0               ; set min contour level
  res@cnMaxLevelValF       =  120.0               ; set max contour level
  res@cnLevelSpacingF      =   10.0               ; set contour spacing
  plot=gsn_csm_contour_map(wks,psi(nt,:,:),res)
; --------------------
end if  ;end of 
; ---- writing file
if ( FILEW ) then

   system("rm -f " + fileout)
   out_nc = addfile(fileout,"c")

   sf@units = "m/s"
   sf@long_name = "Stream function"
   sf@standard_name = "stream_function"

   out_nc->sf = sf
   
end if
; --- end of writing file
end
