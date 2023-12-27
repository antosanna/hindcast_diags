;*************************************************
; NCEP_quantile.ncl
;
;************************************************
load "/users/home/opt/ncl/ncl_ncarg-6.4.0/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "/users/home/opt/ncl/ncl_ncarg-6.4.0/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/users/home/opt/ncl/ncl_ncarg-6.4.0/lib/ncarg/nclscripts/csm/contributed.ncl"
;**********************************************
; define function to compute quantiles
;**********************************************
function quantile(N:integer,p:float,series_ord[*]:float)
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

  Q=new((/1/),typeof(series_ord))

  Q(:)=abs(N*p-FL+0.5)*series_ord(FL)+abs(N*p-FL-0.5)*series_ord(FL-1)

  return(Q)
end
;****************MAIN*********************
begin

;************************************************
; open file and read in variable
;***********************************************
;
  lead=toint(getenv("lead"))
  var=getenv("var")
  infilem=getenv("inputm")
  in1  = addfile(infilem,"r")
  tmp2 = in1->$var$
  tmp=tofloat(tmp2(:,:,lead,0,0))

  mm=dimsizes(tmp)
  N=mm(0)
  nrun=mm(1)
  Nyrs=N
        
; reshape to 3D to compute the terciles
  anom3=reshape(tmp,(/nrun*Nyrs/))
;
  series_ord=anom3
  N=nrun*Nyrs
  ip=dim_pqsort_n(series_ord,2,0); sort the data
  print("MODEL array sorted in ascending order")
print(ip)
;
  p=0.05
  low5=quantile(N,p,series_ord)
  p=1./4.
  low25=quantile(N,p,series_ord)
  p=1./3.
  low33=quantile(N,p,series_ord)
  p=1./2.
  pctl50=quantile(N,p,series_ord)
  p=2./3.
  up66=quantile(N,p,series_ord)
  p=3./4.
  up75=quantile(N,p,series_ord)
  p=0.95
  up95=quantile(N,p,series_ord)


  print("MODEL quantiles computed")
  delete(series_ord)

;----------------------------------
; Now write terciles
;----------------------------------

outputfile=getenv("outfile")
system("/bin/rm -f "+outputfile)   ; remove any pre-existing file
ncdf     = addfile(outputfile ,"c")
low5!0="time"
ncdf->low5=low5
low25!0="time"
ncdf->low25=low25
low33!0="time"
ncdf->low33=low33
pctl50!0="time"
ncdf->pctl50=pctl50 
up66!0="time"
ncdf->up66=up66
up75!0="time"
ncdf->up75=up75
up95!0="time"
ncdf->up95=up95

end
