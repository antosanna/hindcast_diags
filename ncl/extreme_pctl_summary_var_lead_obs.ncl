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
  var=getenv("varf")
  infilem=getenv("inputm")
  in1  = addfile(infilem,"r")
  if ( var .eq. "var129" .or. var.eq."var130" ) then
  	tmp2 = in1->$var$(:,:,0,:,:)
  else
  	tmp2 = in1->$var$
  end if
  tmp=tofloat(tmp2)
  copy_VarMeta(tmp2,tmp)
  printVarSummary(tmp)

  mm=dimsizes(tmp)
  N=mm(0)
  nt=mm(1)
  ny=mm(2)
  nx=mm(3)
  Nyrs=N
        
  if (mm(2).ne.ny) then
    print(" ")
    print("dimensions mismatch")
    print("nymod = " +mm(2))
    exit
  else if (mm(3).ne.nx) then
    print(" ")
    print("dimensions mismatch")
    print("nxmod = " +mm(3))
    exit
  end if
  end if

; reshape to 3D to compute the terciles
  anom3=tmp
;
  series_ord=anom3
  N=Nyrs
  ip=dim_pqsort_n(series_ord,2,0); sort the data
  print("MODEL array sorted in ascending order")
;
  low10=new((/nt,ny,nx/),typeof(tmp))
  up90=new((/nt,ny,nx/),typeof(tmp))

  do tk=0,nt-1
     p=1./10.
     low10(tk,:,:)=quantile(N,p,series_ord(:,tk,:,:))
     p=9./10.
     up90(tk,:,:)=quantile(N,p,series_ord(:,tk,:,:))
  end do
  print("MODEL quantiles computed")
  delete(series_ord)
  copy_VarMeta(tmp(0,:,:,:),low10)
  copy_VarMeta(tmp(0,:,:,:),up90)

;----------------------------------
; Now write terciles
;----------------------------------

outputfile=getenv("outfile10")
system("/bin/rm -f "+outputfile)   ; remove any pre-existing file
ncdf     = addfile(outputfile ,"c")
low10!0="time"
low10!1="lat"
low10!2="lon"
ncdf->low10=low10

outputfile=getenv("outfile90")
system("/bin/rm -f "+outputfile)   ; remove any pre-existing file
ncdf     = addfile(outputfile ,"c")
up90!0="time"
up90!1="lat"
up90!2="lon"
ncdf->up90=up90

end
