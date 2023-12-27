begin

yyyy=getenv("yy")
st=getenv("st")
ppp=getenv("ppp")

ntime=0
month=toint(st)
year=toint(yyyy)
do nm=0,5

   if ( month .gt. 12 ) then
      month=1
      year=year+1
   end if
   year@calendar = "noleap"
   ndays=days_in_month(year,month)
   ntime=ntime+ndays	
   month=month+1

end do

filetype=getenv("filetype")
pathfile=getenv("datadir")

;************************************************
; variable and file handling
;************************************************

   diri = getenv("datadir")
   varm=getenv("var")
   flist="sps3.5_"+yyyy+st+"_"+ppp+"/ocn/hist/*"+yyyy+st+"_"+ppp+"_*"+filetype+".zip.nc"   ;getenv("flist")

   fili = systemfunc("cd "+diri+" ; ls "+flist)
   print(fili)
   nfils = dimsizes(fili) 

   fi = addfile (diri+"/"+fili(0), "r")
   varstd = fi->$varm$
   nn=dimsizes(varstd)
   rank=dimsizes(nn)
   delete(nn)

if ( rank .eq. 4 ) then
   deptht=fi->deptht(0:29)
end if  

if ( rank .eq. 4 ) then
   fall = addfiles (diri+"/"+fili, "r")
   varall=fall[:]->$varm$(:,0:29,:,:)
else if ( rank .eq. 3 ) then
   fall = addfiles (diri+"/"+fili, "r")
   varall=fall[:]->$varm$
end if
end if
nnv=dimsizes(varall)
if (rank .eq. 4) then
   nlev=nnv(1)
end if
nt=nnv(0)
delete(nnv)

; -----------------------------------------------------
; ----- Now interpolate from ORCA original grid to 1x1 
; -----------------------------------------------------

meshmaskfile = getenv("meshmaskfile")
meshmask = addfile(meshmaskfile,"r")
if (rank .eq. 3 ) then
   tmpnemo=meshmask->tmaskutil
   lsmnemo=where(tmpnemo.eq.0.,-999.,0.)
   lsmnemo@_FillValue=-999.
   delete(tmpnemo)
end if


;---Output (and input) files
srcGridName = getenv("srcGridName")
dstGridName = getenv("dstGridName")
wgtFile     = getenv("wgtFile")

if ( filetype .eq. "grid_T_EquT" ) then
   nav_lat = meshmask->nav_lat(348:655,:)
   nav_lon = meshmask->nav_lon(348:655,:)
else
   nav_lat = meshmask->nav_lat
   nav_lon = meshmask->nav_lon
end if

if (rank .eq. 4) then
   if ( filetype .eq. "grid_T_EquT" ) then
      tmask = tofloat(meshmask->tmask(0,0:29,348:655,:))
   else  
      tmask = tofloat(meshmask->tmask(0,0:29,:,:))
      umask = tofloat(meshmask->umask(0,0:29,:,:))
      vmask = tofloat(meshmask->vmask(0,0:29,:,:))
   end if
   lsmnemo=where(tmask.eq.0.,-999.,0.)
   ;lsmnemo@_FillValue=-999.
end if

outdir=getenv("datamm")
system("/bin/rm -f "+outdir+"/interp_ORCA2_1X1.ncl_"+ppp+"_ok")
print("this is the output dir "+outdir)
first=0
;-----------------------------------------------------------------
; Set the poisson_grid_fill variables
; Global grid: Fill in over land
;-----------------------------------------------------------------
nscan = 1500             ; usually *much* fewer
eps   = 0.001            ; variable depended
gtype = True             ; Cyclic in longitude [global]
guess = 1                ; use zonal means
relc  = 0.6              ; standard relaxation coef
opt   = 0
;---------------------------------------------
xtmp   = tofloat(varall)
print(xtmp(0,0,190,560))


if ( rank .eq. 3 ) then
   tos=xtmp(0,:,:)
else
   tos=xtmp(0,:,:,:)
end if
xtmp@_FillValue=-999.

wallClock = systemfunc("date")                         ; determine start time for each year
print(wallClock)
print("Faccio il Poisson")

do it=0,nt-1
  if ( rank.eq.3 ) then
     xtmp(it,:,:,:)=where(lsmnemo.eq.xtmp@_FillValue,xtmp@_FillValue,xtmp(it,:,:))
     tmp2d=xtmp(it,:,:)
     poisson_grid_fill( tmp2d, gtype, guess, nscan, eps, relc, opt)
     xtmp(it,:,:)=tmp2d
     delete(tmp2d)
  else
     do nl=0,nlev-1
        xtmp(it,nl,:,:)=where(lsmnemo(nl,:,:).eq.xtmp@_FillValue,xtmp@_FillValue,xtmp(it,nl,:,:))
        tmp2d=xtmp(it,nl,:,:)
        poisson_grid_fill( tmp2d, gtype, guess, nscan, eps, relc, opt)
        xtmp(it,nl,:,:)=tmp2d
        delete(tmp2d)
     end do
  end if
end do

print("Fatto il Poisson")
wallClock = systemfunc("date")                         ; determine start time for each year
print(wallClock)

print("Faccio interp")
SKIP_ORCA_SCRIP_GEN  = False
SKIP_WORLD_SCRIP_GEN = False
SKIP_WGT_GEN         = False
;---if you want to print out the intermediate files set first=0
if (first.eq.0) then
   SKIP_ORCA_SCRIP_GEN  = False
   SKIP_WORLD_SCRIP_GEN = False
   SKIP_WGT_GEN         = False
end if
;----------------------------------------------------------------------
; Convert ORCA to SCRIP file.
;----------------------------------------------------------------------
if(.not.SKIP_ORCA_SCRIP_GEN) then
;---Convert to an SCRIP Convention file.
  Opt                = True
  Opt@ForceOverwrite = True
  Opt@PrintTimings   = True
  Opt@Mask2D         = where(.not.ismissing(tos(0,:,:)),1,0)

  printVarSummary(nav_lat)
  printVarSummary(nav_lon)
  curvilinear_to_SCRIP(srcGridName,nav_lat,nav_lon,Opt)

   ;---Clean up
  delete(Opt)
end if
;----------------------------------------------------------------------
; Convert 2 degree world grid to SCRIP file
;----------------------------------------------------------------------
if(.not.SKIP_WORLD_SCRIP_GEN)
   Opt                = True
   if ( filetype .eq. "grid_T_EquT" ) then
       Opt@LLCorner       = (/-35.5,-179.5 /)
       Opt@URCorner       = (/ 35.5, 179.5 /)
   else
       Opt@LLCorner       = (/-89.5,-179.5 /)
       Opt@URCorner       = (/ 89.5, 179.5 /)
   end if
   Opt@ForceOverwrite = True
   Opt@PrintTimings   = True
   Opt@Title          = "World grid 1x1 degree resolution"

   latlon_to_SCRIP(dstGridName,"1deg",Opt)

   ;---Clean up
   delete(Opt)
end if
;----------------------------------------------------------------------
; Generate interpolation weights for ORCA Grid to World Grid
;----------------------------------------------------------------------
if(.not.SKIP_WGT_GEN) then
    Opt                      = True
    Opt@SrcESMF              = False
    Opt@DstESMF              = False
    Opt@ForceOverwrite       = True
    Opt@PrintTimings         = True

    ESMF_regrid_gen_weights(srcGridName, dstGridName, wgtFile, Opt)

   ;---Clean up
    delete(Opt)
end if

;----------------------------------------------------------------------
; Interpolate data from ORCA to World 1-degree grid.
;----------------------------------------------------------------------

Opt              = True
Opt@Debug        = True
Opt@PrintTimings = True

lsm1x1 = ESMF_regrid_with_weights(lsmnemo,wgtFile,Opt)
if (rank .eq. 3) then
   tmp = ESMF_regrid_with_weights(xtmp(0,:,:),wgtFile,Opt)
   nn=dimsizes(tmp)
   varout=new((/nt,nn(0),nn(1)/),"float",-999.)
   delete(tmp)
   nlat=nn(0)
   nlon=nn(1)
else
   tmp = ESMF_regrid_with_weights(xtmp(0,:,:,:),wgtFile,Opt)
   nn=dimsizes(tmp)
   varout=new((/nt,nn(0),nn(1),nn(2)/),"float",-999.)
   delete(tmp)
   nlat=nn(1)
   nlon=nn(2)
end if
varout@_FillValue = -999.


do it=0,nt-1

  Opt              = True
  Opt@Debug        = True
  Opt@PrintTimings = True

  if ( rank .eq. 3 ) then
     tmp2d=xtmp(it,:,:)
     tmp = ESMF_regrid_with_weights(tmp2d,wgtFile,Opt)
     varout(it,:,:)=where(lsm1x1.eq.0.,varout@_FillValue,tmp)
  else
     do nl=0,nlev-1
         tmp2d=xtmp(it,nl,:,:)
         tmp = ESMF_regrid_with_weights(tmp2d,wgtFile,Opt)
         varout(it,nl,:,:)=where(lsm1x1(nl,:,:).eq.0.,varout@_FillValue,tmp)
     end do
  end if

  delete(tmp)
  delete(tmp2d)

 ;---Clean up
  delete(Opt)

end do

; ----- End of interpolation section

print("Finito interp")
wallClock = systemfunc("date")                         ; determine start time for each year
print(wallClock)
;----------------------------------------------------------------------
;  Write to a new file
;----------------------------------------------------------------------
filo=getenv("filo")   ;with full path
system("/bin/rm -f " + filo) 
fout  = addfile (filo, "c")  ; open output file
setfileoption("nc","Format","NetCDF4Classic")
setfileoption("nc","CompressionLevel",6)

;-------- New
global = True
copy_VarAtts(fili, global)

if (isatt(fili,"title")) then
    global@TITLE = "REMAPPED: " + sfile@title
end if
global@creation_date = systemfunc("date")
    
fileattdef( fout, global )        ; copy global file attributes
filedimdef(fout,"time_counter",-1,True)   ; force an unlimited dimension
filedimdef(fout,"nav_lat",nlat,False)   ; force an unlimited dimension
filedimdef(fout,"nav_lon",nlon,False)   ; force an unlimited dimension

if ( rank .eq. 4 ) then
   fout->deptht = deptht
   varout!0 = "time_counter"
   varout!1 = "deptht"
   varout!2 = "nav_lat"
   varout!3 = "nav_lon"
else
   varout!0 = "time_counter"
   varout!1 = "nav_lat"
   varout!2 = "nav_lon" 
end if

fout->$varm$ = (/varout/)
;#######


end
