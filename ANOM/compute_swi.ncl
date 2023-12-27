begin

st=getenv("st")
diag=2   ; 1 for entire depth
         ; 2 to consider layer between two depths 

PLOTS=False
FILEW=True

dirplots="/work/csp/sp2/scratch/ANDREA/soilm/plots"
;dir=getenv("dir")  ;"/work/csp/sp2/SPS3.5/CESM/monthly/mrlsl/C3S"
filem=getenv("filein")  
outFileName = getenv("fileout")

inputf=filem
fi=addfile(inputf,"r")

mrlsl=fi->mrlsl
depth=tofloat(fi->depth)
time=fi->time
lat=fi->lat
nlev=dimsizes(depth)

rad    = 4.0*atan(1.0)/180.0
clat   = cos(lat({28:50})*rad)

soilmdz=mrlsl
soilmdz_cycle=mrlsl(:,:,0,0)
deltaz=depth
do k=0,nlev-1
   kk=k-1
   if ( k .eq. 0 ) then
      deltaz(k)=depth(k)
   else
      deltaz(k)=depth(k)-depth(kk)
   end if
   soilmdz(:,k,:,:)=(mrlsl(:,k,:,:)/deltaz(k))/1000
;----
; This is only for test
   soilmdz_cycle(:,k)=wgt_areaave_Wrap(soilmdz(:,k,{28:50},{-10:45}),clat,1.0,0)
   
end do

ddep_tmp=conform(mrlsl(depth|:,time|:,lat|:,lon|:),deltaz,0)

copy_VarMeta(mrlsl(depth|:,time|:,lat|:,lon|:),ddep_tmp)
ddep=ddep_tmp(time|:,depth|:,lat|:,lon|:)

;-----
; Compute the total soil moisture
;-----
soilm_tot_dz=dim_sum_n_Wrap(soilmdz*ddep,1)/dim_sum_n_Wrap(ddep,1)
copy_VarMeta(soilmdz(:,0,:,:),soilm_tot_dz)

;-----
; Compute the total first 3 levels soil moisture
;-----
soilm_tot3_dz=dim_sum_n_Wrap(soilmdz(:,0:2,:,:)*ddep(:,0:2,:,:),1)/dim_sum_n_Wrap(ddep(:,0:2,:,:),1)
copy_VarMeta(soilmdz(:,0,:,:),soilm_tot3_dz)

;----
; This is only for test
soilm_tot_dz_cycle=wgt_areaave_Wrap(soilm_tot_dz(:,{28:50},{-10:45}),clat,1.0,0)
 
;-----
; Compute the total soil moisture monhtly mean
;-----

soilm_tot_dz_mm=calculate_monthly_values(soilm_tot_dz, "avg", 0, False)
copy_VarMeta(soilm_tot_dz(0:6,:,:),soilm_tot_dz_mm)
soilm_tot3_dz_mm=calculate_monthly_values(soilm_tot3_dz, "avg", 0, False)
copy_VarMeta(soilm_tot3_dz(0:6,:,:),soilm_tot3_dz_mm)



if ( PLOTS ) then
; ------------------------------------------------
; Make the plots
; ------------------------------------------------

  wks = gsn_open_wks("png",dirplots+"/soilm_deltaz_"+st)             ; send graphics to PNG file

  plot = new(11,graphic)
  plot2 = new(11,graphic)

  res                      = True     ; plot mods desired

  res@gsnMaximize          = True     ; maximize plot
  res@gsnDraw              = False            ; don't draw
  res@gsnFrame             = False            ; don't advance frame

  res@cnFillOn             = True     ; turn on color fill
  res@cnLinesOn            = False    ; turn of contour lines
  res@lbLabelBarOn         = False


  res@tiMainString         = ""
  res@gsnRightString       = "[m3/m3]"
  res@cnFillPalette        = "MPL_BrBG" ; set color map

  res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  res@cnMinLevelValF  = 0.			; set the minimum contour level
  res@cnMaxLevelValF  = 1.			; set the maximum contour level
  res@cnLevelSpacingF = 0.05			; set the interval between contours
  
  do i=0,9
     ip1=i+1
     if ( i.eq.0 ) then
        z2="0"
     else
        z2="z"+i
     end if
     res@gsnLeftString         = "depth: "+depth(i)+" (m)"
     plot(i) = gsn_csm_contour_map(wks,soilmdz(0,i,:,:),res)
  end do

  res@gsnLeftString         = "total column"
  plot(10) = gsn_csm_contour_map(wks,soilm_tot_dz(0,:,:),res)
;************************************************
; create panel
;************************************************
  resP                    = True                 ; modify the panel plot
  resP@gsnFrame           = False                ; don't advance panel plot
  resP@gsnPanelLabelBar   = True                 ; add common colorbar
  resP@gsnPanelBottom     = 0.05
  resP@gsnPanelMainString = "Soil moisture 2000"+st  ;+" clim (1993-2016)"     ; set main title
  resP@gsnPanelRowSpec = True
  gsn_panel(wks,plot,(/3,3,3,2/),resP)               ; now draw as one plot

  frame(wks)
;************************************************
; now plot the seasonal cycle
;************************************************
  res2                      = True     ; plot mods desired

  res2@gsnMaximize          = True     ; maximize plot
  res2@gsnDraw              = False            ; don't draw
  res2@gsnFrame             = False            ; don't advance frame

  res2@cnFillOn             = False     ; turn on color fill
  res2@cnLinesOn            = True    ; turn of contour lines


  res2@tiMainString         = ""
  res2@gsnRightString       = "[m3/m3]"
 
  do i=0,9
     ip1=i+1
     if ( i.eq.0 ) then
        z2="0"
     else
        z2="z"+i
     end if
     if ( diag .eq. 1 ) then
        res2@gsnLeftString         = "depth: "+depth(i)+" (m)"
        plot2(i) = gsn_csm_xy(wks,time,soilmz_cycle(:,i),res2)
     else
        ;res2@gsnLeftString         = "delta z(z"+ip1+"-"+z2+"): "+deltaz(i)+" (m)"
        res2@gsnLeftString         = "depth: "+depth(i)+" (m)"
        plot2(i) = gsn_csm_xy(wks,time,soilmdz_cycle(:,i),res2)
     end if
  end do

  res2@gsnLeftString         = "total column"
  plot2(10) = gsn_csm_xy(wks,time,soilm_tot_dz_cycle,res2)
;************************************************
; create panel
;************************************************
  resP2                    = True                 ; modify the panel plot
  resP2@gsnFrame           = False                ; don't advance panel plot
  resP2@gsnPanelLabelBar   = True                 ; add common colorbar
  resP2@gsnPanelBottom     = 0.05
  resP2@gsnPanelMainString = "Soil moisture 2000"+st ;+" clim (1993-2016) Seasonal cycle"     ; set main title
  resP2@gsnPanelRowSpec = True
  gsn_panel(wks,plot2,(/3,3,3,2/),resP2)               ; now draw as one plot

  frame(wks)
end if ; PLOTS
;--------
; Writing netcdf file
;--------
if ( FILEW ) then
   
   system("rm -f " + outFileName)
   out_nc = addfile(outFileName,"c")
   
   soilm_tot_dz_mm@units = "m3/m3"
   soilm_tot_dz_mm@long_name = "Total Column soil moisture"
   soilm_tot_dz_mm@standard_name = "total_moisture_content_of_soil" 
   delete(soilm_tot_dz_mm@depth)
;
; Write variables to file. Coordinate arrays will be written 
; automatically
;
      out_nc->mrlsl       = soilm_tot3_dz_mm

end if


end
