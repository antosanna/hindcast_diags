begin

;filetype=getenv("filetype")
;pathfile=getenv("datadir")

;************************************************
; variable and file handling
;************************************************

varm=getenv("varm")
flist=getenv("flist") 

fili = systemfunc("ls "+flist)
print(fili)
nfils = dimsizes(fili) 

fi = addfile (fili(0), "r")
varstd = fi->$varm$
nn=dimsizes(varstd)
rank=dimsizes(nn)

if ( rank .eq. 4 ) then
   deptht=fi->deptht(0:29)
end if  

if ( rank .eq. 4 ) then
   fall = addfiles (fili, "r")
   varall=fall[:]->$varm$(:,0:29,:,:)
else if ( rank .eq. 3 ) then
   fall = addfiles (fili, "r")
   varall=fall[:]->$varm$
end if
end if


filo=getenv("fens")   ;with full path
system("/bin/rm -f " + filo) 
fout  = addfile (filo, "c")  ; open output file

;-------- New
global = True
copy_VarAtts(fili, global)

if (isatt(fili,"title")) then
    global@TITLE = "REMAPPED: " + sfile@title
end if
global@creation_date = systemfunc("date")
    
fileattdef( fout, global )        ; copy global file attributes
filedimdef(fout,"time_counter",-1,True)   ; force an unlimited dimension

if ( rank .eq. 4 ) then
   fout->deptht = deptht
end if
fout->$varm$ = varall
;#######


end
