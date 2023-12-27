;*************************************************
; NCEP_quantile.ncl
;
;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;**********************************************
; define function to compute quantiles
;**********************************************
function quantile(N:integer,p:float,series_ord[*][*][*]:float)
;---------- N=series dimension
;---------- p=desired quantile order
;---------- Q=output
begin
  if ( N*p .lt.0.5) then
    print("input data not ok")
    exit
  else if ( N*p .gt. N-0.5) then
    print("input data not ok")
    exit
  else
     if ( (abs(N*p-floor(N*p)+.5)).gt.1 ) then
       FL=floattoint(floor(N*p))+1
     else
       FL=floattoint(floor(N*p))
     end if
  end if
  end if

  nn=dimsizes(series_ord)
  ny=nn(1)
  nx=nn(2)
  Q=new((/nn(1),nn(2)/),typeof(series_ord))

  Q(:,:)=abs(N*p-FL+0.5)*series_ord(FL,:,:)+abs(N*p-FL-0.5)*series_ord(FL-1,:,:)

  return(Q)
end
;****************MAIN*********************
begin

;************************************************
; open file and read in variable
;***********************************************
;
  lead=toint(getenv("lead"))
  var=getenv("varf")
  infilem=getenv("inputm")
  in1  = addfile(infilem,"r")
  if (var .eq. "zg") .or. (var .eq. "ta") .or. (var .eq. "ua") .or. (var .eq. "va") then
  	tmp2 = in1->$var$(:,:,:,0,:,:)
  else
  	tmp2 = in1->$var$
  end if
  if (var .eq. "tso" ) then
  	tmp=tofloat(dim_avg_n_Wrap(tmp2(:,:,0+lead:2+lead,::-1,:),2))
  else
  	tmp=tofloat(dim_avg_n_Wrap(tmp2(:,:,0+lead:2+lead,:,:),2))
  end if

  mm=dimsizes(tmp)
  N=mm(0)
  nrun=mm(1)
  nx=mm(2)
  ny=mm(3)
  Nyrs=N
        
  if (mm(3).ne.ny) then
    print("dimensions mismatch")
    print("nymod = " +mm(3))
    exit
  else if (mm(2).ne.nx) then
    print("dimensions mismatch")
    print("nxmod = " +mm(2))
    exit
  end if
  end if

; reshape to 3D to compute the terciles
  anom3=reshape(tmp,(/nrun*Nyrs,nx,ny/))
;
  series_ord=anom3
  N=nrun*Nyrs
  ip=dim_pqsort_n(series_ord,2,0); sort the data
  print("MODEL array sorted in ascending order")
;
  p=1./3.
  low33=quantile(N,p,series_ord)
  copy_VarMeta(tmp2(0,0,0,:,:),low33)
  p=2./3.
  up66=quantile(N,p,series_ord)
  copy_VarMeta(tmp2(0,0,0,:,:),up66)
  p=1./5.
  low20=quantile(N,p,series_ord)
  copy_VarMeta(tmp2(0,0,0,:,:),low20)
  p=4./5.
  up80=quantile(N,p,series_ord)
  copy_VarMeta(tmp2(0,0,0,:,:),up80)
  print("MODEL quantiles computed")
  delete(series_ord)
  up80ncl=up80
  up66ncl=up66
  low33ncl=low33
  low20ncl=low20

;----------------------------------
; Now write terciles
;----------------------------------
outputfile=getenv("outfile20")
system("/bin/rm -f "+outputfile)   ; remove any pre-existing file
ncdf     = addfile(outputfile ,"c")
low20!0="lat"
low20!1="lon"
ncdf->low20=low20

outputfile=getenv("outfile33")
system("/bin/rm -f "+outputfile)   ; remove any pre-existing file
ncdf     = addfile(outputfile ,"c")
low33!0="lat"
low33!1="lon"
ncdf->low33=low33

outputfile=getenv("outfile66")
system("/bin/rm -f "+outputfile)   ; remove any pre-existing file
ncdf     = addfile(outputfile ,"c")
up66!0="lat"
up66!1="lon"
ncdf->up66=up66

outputfile=getenv("outfile80")
system("/bin/rm -f "+outputfile)   ; remove any pre-existing file
ncdf     = addfile(outputfile ,"c")
up80!0="lat"
up80!1="lon"
ncdf->up80=up80

end
