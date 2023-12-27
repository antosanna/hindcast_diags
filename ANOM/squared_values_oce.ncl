;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;************************************************
;************************************************
;  BEGIN MAIN
;************************************************
begin
;************************************************
; variable and file handling
;************************************************
diri = getenv("diri")
varm=getenv("varm")
flist=getenv("flist")
fili = systemfunc("cd "+diri+" ; ls "+flist)
print(fili)
nfils = dimsizes(fili)
print(nfils)
 
fi = addfile (diri+"/"+fili(0), "r")
sqrd = fi->$varm$
nn=dimsizes(sqrd)
rank=dimsizes(nn)
print("caricato il file per definire la variabile sqrd")
if ( rank .eq. 4 ) then
   varall = new((/nfils,nn(0),nn(1),nn(2),nn(3)/),typeof(sqrd))
   varall(0,:,:,:,:)=sqrd
else if ( rank .eq. 3 ) then
   varall = new((/nfils,nn(0),nn(1),nn(2)/),typeof(sqrd))
   varall(0,:,:,:)=sqrd
end if 
print("Ho caricato sqrd in varall(0)")
end if 
do nf=1,nfils-1
   fi = addfile (diri+"/"+fili(nf), "r")
   if ( rank .eq. 4 ) then
      varall(nf,:,:,:,:) = fi->$varm$
   else if ( rank .eq. 3 ) then
      varall(nf,:,:,:) = fi->$varm$
   end if
   end if
end do
print("Ho caricato l resto di varall")

odir=getenv("odir")   ;with full path
filostd=odir+"/"+getenv("filostd")   ;with full path
checkfile=getenv("checkfilestd")   

if ( isfilepresent(checkfile)) then    ; remove if exists
    system("/bin/rm " + checkfile)    ; remove if exists
end if
;#######

lat=fi->lat
lon=fi->lon
if ( rank.eq.4 ) then
plev=fi->plev
end if
leadtime=fi->leadtime
time=fi->time
reftime=fi->reftime
hcrs=fi->hcrs
realization=fi->realization

if ( rank.eq.4 ) then
   do k=0,nn(1)-1
      sqrd(:,k,:,:)=dim_avg_n(varall(:,:,k,:,:)^2,0)  ;first index is ensemble index
   end do
else if ( rank.eq.3 ) then
   sqrd=dim_avg_n(varall(:,:,k,:,:)^2,0)
end if
end if

;*******************************************************************

    if ( isfilepresent(filostd)) then    ; remove if exists
       system("/bin/rm " + filostd)    ; remove if exists
    end if
    setfileoption("nc","Format","NetCDF4Classic")
    setfileoption("nc","CompressionLevel",6)
    setfileoption("nc","preFill",False)

    fout  = addfile (filostd, "c")  ; open output file
    globalAtt             = True
    globalAtt@title       = "Ensemble sum of squared values computed by squared_values.ncl. First step to compute ensemble hindcast standard deviation"   
    fileattdef( fout, globalAtt )

;    setfileoption(fout,"DefineMode",True)


   fout->lat    = lat
   fout->lon    = lon
   fout->$varm$ = sqrd
   fout->check = sqrt(sqrd)
if ( rank.eq.4 ) then
   fout->plev=plev
end if
   fout->leadtime=leadtime
   fout->time=time
   fout->reftime=reftime
   fout->hcrs=hcrs
   fout->realization=realization
;

   system("touch " + checkfile)    
;***********************************************
end
