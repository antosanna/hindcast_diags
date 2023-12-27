;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;************************************************
undef("add_map_tickmarks2")
function add_map_tickmarks2(wks,plot,res)
local res2, bres, vpx, vpy, vpw, vph, xndc, yndc, npts, n, j, nlat, \
nlon, delta, bot_lon, top_lon, lft_lat, rgt_lat, xblabels, xbvalues, \
xtlabels, xtvalues, yllabels, ylvalues, yrlabels, yrvalues, xfix, \
xlat, xlon, yfix, annoid, anno_str
begin
;---Make a copy of the original resource list.
  res2 = res

;---Retrieve edges of plot in NDC space.
  getvalues plot
     "vpXF"      :  vpx
     "vpYF"      :  vpy
     "vpWidthF"  :  vpw
     "vpHeightF" :  vph
  end getvalues

;---Turn off tickmarks associated with map. We want to add our own.
  setvalues plot
    "pmTickMarkDisplayMode" : "Never"
  end setvalues

;---Initialize resources for tickmark plot. User shouldn't change these.
  bres                          = True
  bres@vpXF                     = vpx
  bres@vpYF                     = vpy
  bres@vpWidthF                 = vpw
  bres@vpHeightF                = vph
  bres@trXMinF                  = vpx
  bres@trXMaxF                  = vpx + vpw
  bres@trYMinF                  = vpy - vph
  bres@trYMaxF                  = vpy
  bres@tmEqualizeXYSizes        = True

;---This resource the user can change in main code if desired.
  bres@gsnTickMarksPointOutward = get_res_value(res2,"gsnTickMarksPointOutward",True)

;
; NDC Points to scan on X and Y axes. These arrays will be used to
; find the closest NDC pair that gets us close to the location where
; we want a tickmark.
;
  npts = 100000   ; Increase to get closer match for tickmarks
  xndc = fspan(vpx,vpx+vpw,npts)
  yndc = fspan(vpy-vph,vpy,npts)
  n    = dimsizes(yndc)
  xfix = new(n,float)
  yfix = new(n,float)
  xlon = new(n,float)
  xlat = new(n,float)
  delta = 0.001

;---Left axis tickmarks
  if(isatt(res2,"tmYLValues")) then
    lft_lat    = get_res_value(res2,"tmYLValues",-1)
    nlat       = dimsizes(lft_lat)
    ylvalues = new(nlat,float)
    yllabels = new(nlat,string)
    xfix  = vpx + 0.0001 ; Just a smidge into the plot to make sure we don't
                         ; get missing values returned.
;
; Loop across each left latitude value that we want a tickmark for,
; and try to find the closest X,Y NDC coordinate pair along this axis.
;
    NhlNDCToData(plot,xfix,yndc,xlon,xlat)
    do j=0,dimsizes(lft_lat)-1
      NhlNDCToData(plot,xfix,yndc,xlon,xlat)
      ii = minind(fabs(xlat-lft_lat(j)))
      if(.not.any(ismissing(ii)).and.fabs(xlat(ii)-lft_lat(j)).le.delta)
        yllabels(j) = fabs(lft_lat(j)) + ""
        ylvalues(j) = yndc(ii(0))
        if(lft_lat(j).lt.0) then
          yllabels(j) = yllabels(j) + "~S~o~N~S"
        end if
        if(lft_lat(j).gt.0) then
          yllabels(j) = yllabels(j) + "~S~o~N~N"
        end if
      end if
      delete(ii)
    end do
    bres@tmYLMode   = "Explicit"
    bres@tmYLValues = ylvalues
    bres@tmYLLabels = get_res_value(res2,"tmYLLabels",yllabels)
  else
    bres@tmYLOn       = False
    bres@tmYLLabelsOn = False
  end if
  
;---Right axis tickmarks
  if(isatt(res2,"tmYRValues")) then
    rgt_lat    = get_res_value(res2,"tmYRValues",-1)
    nlat       = dimsizes(rgt_lat)
    yrvalues = new(nlat,float)
    yrlabels = new(nlat,string)

    xfix  = vpx + vpw - 0.0001 ; Just a smidge into the plot to make sure we don't
                               ; get missing values returned.
;
; Loop across each right latitude value that we want a tickmark for,
; and try to find the closest X,Y NDC coordinate pair along this axis.
;
    do j=0,dimsizes(rgt_lat)-1
      NhlNDCToData(plot,xfix,yndc,xlon,xlat)
      ii = minind(fabs(xlat-rgt_lat(j)))
      if(.not.any(ismissing(ii)).and.fabs(xlat(ii)-rgt_lat(j)).le.delta)
        yrlabels(j) = fabs(rgt_lat(j)) + ""
        yrvalues(j) = yndc(ii(0))
        if(rgt_lat(j).lt.0) then
          yrlabels(j) = yrlabels(j) + "~S~o~N~S"
        end if
        if(rgt_lat(j).gt.0) then
          yrlabels(j) = yrlabels(j) + "~S~o~N~N"
        end if
      end if
      delete(ii)
    end do
    bres@tmYROn       = True
    bres@tmYRLabelsOn = True
    bres@tmYUseLeft   = False
    bres@tmYRMode     = "Explicit"
    bres@tmYRValues   = yrvalues
    bres@tmYRLabels   = get_res_value(res2,"tmYRLabels",yrlabels)
  else
    bres@tmYUseLeft   = False
    bres@tmYROn       = False
    bres@tmYRLabelsOn = False
  end if

;---Top axis tickmarks
  if(isatt(res2,"tmXTValues")) then
    top_lon    = get_res_value(res2,"tmXTValues",-1)
    nlon       = dimsizes(top_lon)
    xtvalues = new(nlon,float)
    xtlabels = new(nlon,string)

    yfix  = vpy - 0.0001 ; Just a smidge into the plot to make sure we don't
                         ; get missing values returned.
;
; Loop across each top longitude value that we want a tickmark for,
; and try to find the closest X,Y NDC coordinate pair along this axis.
;
    do j=0,dimsizes(top_lon)-1
      NhlNDCToData(plot,xndc,yfix,xlon,xlat)
      ii = minind(fabs(xlon-top_lon(j)))
      if(.not.any(ismissing(ii)).and.fabs(xlon(ii)-top_lon(j)).le.delta)
        xtlabels(j) = fabs(top_lon(j)) + ""
        xtvalues(j) = xndc(ii(0))
        if(top_lon(j).lt.0) then
          xtlabels(j) = xtlabels(j) + "~S~o~N~W"
        end if
        if(top_lon(j).gt.0) then
          xtlabels(j) = xtlabels(j) + "~S~o~N~E"
        end if
      end if
      delete(ii)
    end do
    bres@gsnTickMarksOn = False
    bres@tmXBMajorLengthF = 0
    bres@tmYLMajorLengthF = 0
    bres@tmXBMinorLengthF = 0
    bres@tmYLMinorLengthF = 0
    bres@tmXTOn       = True
    bres@tmXTLabelsOn = True
    bres@tmXUseBottom = False
    bres@tmXTMode     = "Explicit"
    bres@tmXTValues   = xtvalues
    bres@tmXTLabels   = get_res_value(res2,"tmXTLabels",xtlabels)
  else
    bres@gsnTickMarksOn = False
    bres@tmXUseBottom = False
    bres@tmXTOn       = False
    bres@tmXTLabelsOn = False
  end if
;---Bottom axis tickmarks
  if(isatt(res2,"tmXBValues")) then
    bot_lon    = get_res_value(res2,"tmXBValues",-1)
    nlon       = dimsizes(bot_lon)
    xbvalues = new(nlon,float)
    xblabels = new(nlon,string)

    yfix  = vpy-vph + 0.0001 ; Just a smidge into the plot to make sure
                             ; we don't get missing values returned.
;
; Loop across each bottom longitude value that we want a tickmark for,
; and try to find the closest X,Y NDC coordinate pair along this axis.
;
    do j=0,dimsizes(bot_lon)-1
      NhlNDCToData(plot,xndc,yfix,xlon,xlat)
      ii = minind(fabs(xlon-bot_lon(j)))
      if(.not.any(ismissing(ii)).and.fabs(xlon(ii)-bot_lon(j)).le.delta)
        xblabels(j) = fabs(bot_lon(j)) + ""
        xbvalues(j) = xndc(ii(0))
        if(bot_lon(j).lt.0) then
          xblabels(j) = xblabels(j) + "~S~o~N~W"
        end if
        if(bot_lon(j).gt.0) then
          xblabels(j) = xblabels(j) + "~S~o~N~E"
        end if
      end if
      delete(ii)
    end do
    bres@tmXBMode   = "Explicit"
    bres@tmXBValues = xbvalues
    bres@tmXBLabels = get_res_value(res2,"tmXBLabels",xblabels)
  else
    bres@tmXBOn       = False
    bres@tmXBLabelsOn = False
  end if
;
; Now that we are done figuring out where to put tickmarks, and
; what labels to use, get any "tm" resources that might have been
; set by the user, and create a blank plot with thes new tickmarks.
;

;---Get rest of user resources that were set with "tm".
  bres = get_res_eq(res2,"tm")

  bres = True   ; Above call will set bres to True if no "tm" resources, so
                ; make sure it is True still.

  bres@gsnDraw  = False
  bres@gsnFrame = False

;
; Create blank plot with new tickmarks (don't use gsn_csm_blank_plot,
; because it wants to scale the size of your X and Y axes.)
;
  blank  = gsn_blank_plot(wks,bres)

;
; Attach new tickmarks to original plot. This will allow resizing
; if desired. The default is to attach one plot to the center of
; the other one. These two plots are already the same size.
;
  annoid = gsn_add_annotation(plot,blank,False)

;
; Be sure to return the annotation id, otherwise the
; tickmarks will disappear.
;
  anno_str = unique_string("annoid")
  plot@$anno_str$ = annoid

  return(plot)
end

;************************************************
; BEGIN MAIN
;************************************************
begin
;************************************************
; open file and read in variable
;***********************************************
  write="FALSE"
  lat1tmp=getenv("lat1")
  lat1=stringtofloat(lat1tmp)
  lat2tmp=getenv("lat2")
  lat2=stringtofloat(lat2tmp)
  lon1tmp=getenv("lon1")
  lon1=stringtofloat(lon1tmp)
  lon2tmp=getenv("lon2")
  lon2=stringtofloat(lon2tmp)
  varm=getenv("varmstr")
  varo=getenv("varo")
  leadtime=getenv("leadtime")
  model=getenv("mod")
  region=getenv("region")

  infileo=getenv("inputo")
  print("infileo "+infileo)
  in2  = addfile(infileo,"r")

  if ( varo.eq."var129" .or. varo.eq."var130" .or. varo.eq."var131" .or. varo.eq."var132" .or. varo.eq."var39") then
      tmp2 = in2->$varo$(:,:,0,:,:)
  else
      if ( varo .eq. "var34" ) then
         tmp2 = in2->$varo$
         tmp2@_FillValue=-9999.
         tmp2@missing_value=-9999.
         ;tmp2=where(tmp2.lt.-100,tmp2@_FillValue,tmp2)
      else
         tmp2 = in2->$varo$(0:23,0:5,:,:)
      end if
  end if

  infilem=getenv("inputm")
  nrun=getenv("nrun")
  in1  = addfile(infilem,"r")
  nn=dimsizes(tmp2)
  print(nn)
  if ( model .eq. "SPS3" ) then
     print(infilem)
     tmp0 = reshape(in1->$varm$,(/24,6,180,360/))
     printVarSummary(tmp0)
     tmp1 = tmp0(0:nn(0)-1,:,:,:)
  else
     if ( varm.eq."zg" .or. varm.eq."ta" .or. varm.eq."ua" .or. varm.eq."va" ) then 
         tmp1 = in1->$varm$(0:nn(0)-1,:,0,:,:)
     else if ( varm .eq. "tso" ) then
         tmp1 = in1->$varm$(0:nn(0)-1,:,:,:)
	        tmp1@_FillValue=-9999.
         tmp1@missing_value=-9999.
     else
         tmp1 = in1->$varm$(0:nn(0)-1,:,:,:)
     end if
     end if
  end if
  lat  = in1->lat
  lon  = in1->lon

  print("Ho letto i files")

;---- Flag per scrivere il NetCDF della ACC
  if ( region .eq. "global" ) then
     write="TRUE"
  end if
  
  nyears=nn(0)

  varobs=new((/nyears,nn(2),nn(3)/),double)
  varmod=new((/nyears,nn(2),nn(3)/),double)
  print("Adesso seleziono i time corrispondenti alla lead season")

  lead=toint(leadtime)
  t1=lead
  t2=lead+2

  varobs=dim_avg_n_Wrap(tmp2(:,t1:t2,:,:),1)
  varmod=dim_avg_n_Wrap(tmp1(:,t1:t2,:,:),1)
  copy_VarMeta(varobs,varmod)

  copy_VarMeta(tmp2(:,0,:,:),varobs)
  copy_VarMeta(tmp1(:,0,:,:),varmod)
  varobs3d=reshape(varobs,(/nyears,nn(2),nn(3)/))
  varmod3d=reshape(varmod,(/nyears,nn(2),nn(3)/))
  copy_VarMeta(tmp2(:,0,:,:),varobs3d)
  copy_VarMeta(tmp2(:,0,:,:),varmod3d)
  ;if ( varo .eq. "var34" ) then
  ;    varobs3d@_FillValue=-9999.
  ;    varobs3d@missing_value=-9999.
  ;    varmod3d@_FillValue=-9999.
  ;    varmod3d@missing_value=-9999.
  ;end if
  printVarSummary(varobs3d)
  printVarSummary(varmod3d)
;************************************************
; reorder to get time as right most dimension
;***********************************************
  ts1 = varmod3d(lat|:,lon|:,year|:)
  ts2 = varobs3d(lat|:,lon|:,year|:)
  print("Ho riordinato le dimensioni delle variabili")
;************************************************
; Calculate coslat
;***********************************************
rad    = 4.0*atan(1.0)/180.0
clat   = cos(lat({lat1:lat2})*rad)
;************************************************
; reorder to get time as right most dimension
;***********************************************
if ( varo .eq. "var34" ) then
	opt=0
else
	opt=1
end if
tstoacc1 = wgt_areaave_Wrap(varmod3d(:,{lat1:lat2},{lon1:lon2}),clat,1.0,opt)
tstoacc2 = wgt_areaave_Wrap(varobs3d(:,{lat1:lat2},{lon1:lon2}),clat,1.0,opt)
print("Ho riordinato le dimensioni delle variabili")
print(tstoacc1)
print(tstoacc2)
;************************************************
; calculate cross correlations
;************************************************
  maxlag = 0                                    ; set lag
; note, the max lag should not be more than N/4

  pcorr=escorc(tstoacc1,tstoacc2)
  print(pcorr)
  
  acc = esccr(ts1,ts2,maxlag)                   ; calc cross correlations
  printVarSummary(acc)
  acct2m=acc(:,:,0)
  copy_VarMeta(ts1(:,:,0),acct2m)
  printVarSummary(acct2m)
  acct2m@_FillValue=-9999
  accareamean=wgt_areaave(acct2m({lat1:lat2},{lon1:lon2}), clat, 1.0, 0)
  print(accareamean)
  print("Ho calcolato ACC")

; copy meta data and coordinate variables using contributed functions
  copy_VarMeta(ts1(:,:,0), acct2m)        
  acct2m@_FillValue=-9999
  printVarSummary(acct2m)
  print("Ho copiato il metadato")

;************************************************
; plot the correlations
;************************************************
  dirplots=getenv("dirplots")
  wks_type = "png"
  iyy=getenv("iniy")
  fyy=getenv("endy")
  st=getenv("st")
  var=getenv("var")
  nrun=getenv("nrun")
  titreg=getenv("titreg")
  plname=getenv("plname")  ;dirplots+"/"+model+"_ACC_"+region+"_"+var+"_"+st+"_l"+leadtime
  wks = gsn_open_wks(wks_type,plname)
  gsn_define_colormap(wks,"test_acc")              ; choose colormap
  plot = new(1,graphic)

; ------ PLOT SETTINGS ------
 
res2                      = True                ; make plot mods

res2@gsnDraw                 = False               ; don't draw
res2@gsnFrame                = False        ; don't advance frame
res2@cnLinesOn               = False
res2@gsnSpreadColors         = False               ; use full colormap
res2@gsnMaximize             = True
res2@mpGeophysicalLineThicknessF = 3
res2@gsnAddCyclic         = True

if ( region .eq. "global" ) then
   res2@gsnDraw             = False
   res2@gsnFrame            = False
   res2@gsnMaximize         = True
   res2@mpCenterLonF         = 0

   res2@mpGridLineColor      = "transparent"
   res2@mpGridAndLimbDrawOrder = "PreDraw"
   res2@mpFillOn             = False
   res2@mpPerimOn            = False
   res2@mpShapeMode          = "FreeAspect"
   res2@vpWidthF             = 0.5
   res2@vpHeightF            = 0.25

   res2@mpLimitMode         = "LatLon"
   res2@mpGridAndLimbOn     = True
   res2@tmXBLabelFontHeightF = 0.008
   res2@tmYLLabelFontHeightF = 0.008

   res2@pmTickMarkDisplayMode = "Always"
   res2@mpGridLatSpacingF        = 30
   res2@mpGridLonSpacingF        = 30
else if ( region .eq. "NH" ) then
   res2@mpFillOn             = False
   res2@gsnMaximize          = False
   res2@gsnPolar             = "NH"
   res2@pmLabelBarWidthF     = 0.3               ; default is shorter
   res2@pmLabelBarHeightF    = 0.05               ; default is taller
   res2@vpWidthF             = 0.35
   res2@vpHeightF            = 0.35
else if ( region .eq. "SH" ) then
   res2@mpFillOn             = False
   res2@gsnMaximize          = False
   res2@gsnPolar             = "SH"
   res2@pmLabelBarWidthF     = 0.3               ; default is shorter
   res2@pmLabelBarHeightF    = 0.05               ; default is taller
   res2@vpWidthF             = 0.35
   res2@vpHeightF            = 0.35
else if ( region .eq. "Europe" )
   res2@mpProjection = "LambertConformal"
   res2@mpDataBaseVersion = "MediumRes"
   res2@mpGridAndLimbOn        = True
   res2@mpGridAndLimbDrawOrder = "PostDraw"
   res2@mpGridLineDashPattern  = 2
   res2@mpFillOn             = False
   res2@mpLimitMode           = "Corners"
   res2@mpLeftCornerLatF      = 22.5 ;25
   res2@mpLeftCornerLonF      = -15 
   res2@mpRightCornerLatF     = 57.5
   res2@mpRightCornerLonF     = 80
  
   res2@mpLambertMeridianF   = 15
   res2@mpLambertParallel1F    = 30
   res2@mpLambertParallel2F    = 80
   
   res2@gsnPaperOrientation  = "landscape"
   res2@gsnMaximize          = True
   res2@tmXBLabelFontHeightF = 0.008
   res2@tmYLLabelFontHeightF = 0.008
   res2@pmLabelBarWidthF     = 0.3               ; default is shorter
   res2@pmLabelBarHeightF    = 0.05               ; default is taller
   res2@pmLabelBarOrthogonalPosF = .10
   res2@pmTickMarkDisplayMode = "Always"
   res2@mpShapeMode          = "FreeAspect"
   res2@vpWidthF             = 0.35
   res2@vpHeightF            = 0.25
   res2@mpGridLatSpacingF        = 15
   res2@mpGridLonSpacingF        = 15
else
   res2@mpFillOn             = False
   res2@mpCenterLonF=0.  ;getenv("lon0")
   res2@mpCenterLatF=0.  ;getenv("lat0")
   res2@mpLimitMode          = "LatLon"
   res2@gsnPaperOrientation  = "landscape"
   res2@gsnMaximize          = True
   res2@tmXBLabelFontHeightF = 0.008
   res2@tmYLLabelFontHeightF = 0.008
   res2@pmLabelBarWidthF     = 0.3               ; default is shorter
   res2@pmLabelBarHeightF    = 0.05               ; default is taller
   res2@pmLabelBarOrthogonalPosF = .40
   res2@pmTickMarkDisplayMode = "Always"
   res2@mpShapeMode          = "FreeAspect"
   res2@vpWidthF             = 0.5
   res2@vpHeightF            = 0.06
end if
end if
end if
end if
res2@cnLabelMasking           = True

if (region .eq. "Tropics") then
    res2@mpGridAndLimbOn          = False                ; turn on lat/lon lines
end if

res2@mpMinLatF                = lat1
res2@mpMaxLatF                = lat2
res2@mpMinLonF                = lon1
res2@mpMaxLonF                = lon2


res2@cnMissingValFillColor   = -1
;res2@mpLandFillColor        = -1
res2@gsnLeftString           = ""                  ; left title, remove default
res2@gsnRightString          = ""
res2@gsnCenterString         = "" 

res2@gsnCenterStringOrthogonalPosF = 0.1

; ------ END PLOT SETTINGS ------
;
;
  res2@cnLevelSelectionMode = "ExplicitLevels"                           ; set explicit contour levels
  res2@cnLevels    = (/-0.9,-0.8,-0.7,-0.6,-0.5,-0.4,-0.3,-0.2,-0.1,0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9/)   
  res2@cnFillColors = (/80,96,112,122,74,58,42,26,10,5,0,166,164,162,159,150,141,137,131,123/)
  res2@cnFillOn    = True                                                ; turn on color fill
  res2@cnLinesOn   = False                                               ; turn off the contour lines

  lag = 0

  month=getenv("mon")
  res2@tiMainString         = month+" start-date - lead season "+leadtime
  res2@tiMainOffsetYF    = 0.0001
  if ((region .eq. "NH") .or. (region .eq. "SH") ) then
     res2@tiMainFontHeightF = 0.015
  else
     res2@tiMainFontHeightF = 0.015	
  end if

  res2@gsnLeftString = "ACC= "+sprintf("%3.2f",accareamean)
  res2@gsnLeftStringFontHeightF = 0.01
  res2@gsnLeftStringOrthogonalPosF = 0.1

  if ( region .eq. "Tropics" ) then
     res2@gsnLeftStringFontHeightF = 0.009
     res2@gsnLeftStringOrthogonalPosF = 0.3
  end if
  print("Faccio il plot")
  if ((region .eq. "NH") .or. (region .eq. "SH") ) then
     res2@gsnLeftStringFontHeightF = 0.01
     plot(0) = gsn_csm_contour_map_polar(wks,acct2m(::-1,:),res2)
  else
     plot(0) = gsn_csm_contour_map(wks,acct2m(::-1,:),res2)
  end if
;************************************************
  tmres    = True

;---Set the values you want for the map tickmarks.
  tmres@tmXBLabelFontHeightF = 0.009         ; Default is a bit large
  if (region .eq. "global" ) then

;---We're putting tickmarks on all four axes.
      tmres@tmYLValues = ispan(-90,90,30)
      tmres@tmYRValues = ispan(-90,90,30)
      tmres@tmXBValues = ispan(-180,180,30)
      tmres@tmXTValues = ispan(-180,180,30)
      map = add_map_tickmarks2(wks,plot,tmres) 

   else if (region .eq. "Europe" ) then

     ;---We're putting tickmarks on all four axes.
      tmres@tmYLValues = ispan(-90,90,15)
      tmres@tmYRValues = ispan(-90,90,15)
      tmres@tmXBValues = ispan(-180,180,15)
      tmres@tmXTValues = ispan(-180,180,15)
      map = add_map_tickmarks2(wks,plot,tmres) 	

   else if ( region .eq. "Tropics" ) then

     ;---We're putting tickmarks on all four axes.
      tmres@tmYLValues = ispan(-20,20,10)
      tmres@tmYRValues = ispan(-20,20,10)
      tmres@tmXBValues = ispan(-180,180,30)
      tmres@tmXTValues = ispan(-180,180,30)
      map = add_map_tickmarks2(wks,plot,tmres)
 
   end if   
   end if   
   end if

  resP                     = True                ; modify the panel plot
  if ( region .eq. "Tropics" ) then
     resP@mpShapeMode  = "FreeAspect"
     resP@vpWidthF      = 0.8 
     resP@vpHeightF     = 0.2 
  end if
  resP@gsnFrame             = False               ; don't advance frame
  resP@txString            = model+": ACC "+titreg+" "+var+" ("+iyy+"-"+fyy+") - members "+nrun
  if ( region .eq. "Tropics" .or. region .eq. "Europe" ) then
    resP@lbLabelFontHeightF  = 0.015               ; make labels smaller
  else
    resP@lbLabelFontHeightF  = 0.007               ; make labels smaller
  end if
  gsn_panel(wks,plot,(/1,1/),resP)

;************************************************
  frame(wks)
;************************************************
; write MSSS in a file if global
;************************************************
if (write .eq. "TRUE") then
   nlat  = dimsizes(lat)  
   nlon  = dimsizes(lon)      

   diro = "./files/"                     ; Output directory
   filo = "SPS3_ACC_"+var+"_"+st+"_l"+leadtime+".nc"  ; Output file
   finalfile=diro+filo
   print(finalfile)
   system("/bin/rm -f " + diro + filo)    ; remove if exists
   fout  = addfile( finalfile, "c")  ; open output file

   setfileoption(fout,"DefineMode",True)

   ;fAtt               = True            ; assign file attributes
   ;fAtt@title         = "ACC"
   ;fAtt@creation_date = systemfunc ("date")
   ;fileattdef( fout, fAtt )            ; copy file attributes  ; MODIFY

   dimNames = (/"lat", "lon"/)
   dimSizes = (/ nlat,  nlon/)
   dimUnlim = (/False, False/)
   filedimdef(fout,dimNames,dimSizes,dimUnlim)

   ;filevardef(fout, "lat"  ,typeof(lat),getvardims(lat))  ; MODIFY
   ;filevardef(fout, "lon"  ,typeof(lon),getvardims(lon))  ; MODIFY
   ;filevardef(fout, var  ,typeof(varobs),getvardims(var))  ; MODIFY
   ;filevarattdef(fout,"lat"  ,lat)
   ;filevarattdef(fout,"lon"  ,lon)
   ;accAtt=0
   ;accAtt@units     = ""
   ;accAtt@long_name = "Anomaly Correlation Coefficient"
   ;filevarattdef( fout, "acc", accAtt )
   acc!0 = "lat"
   acc!1 = "lon"
   acc&lat = lat
   acc&lon = lon

   fout->lat    = (/lat/)
   fout->lon    = (/lon/)
   fout->acc   = (/acct2m/)
end if

if ( region .eq. "global" ) then
   geom_value="80x80+930+830"
else if ( region .eq. "NH" .or. region .eq. "SH" ) then
  geom_value=" 80x80+930+920"
else if ( region .eq. "Europe") then
  geom_value=" 80x80+930+860"
else
   geom_value="80x80+930+660"
end if
end if
end if
;system("pwd")
;print(plname+".png")
;dirlogo=getenv("dirlogo")  ;"/users_home/csp/sp2/SPS/CMCC-SPS3.5/work/ANDREA/DIAGS/ncl/"

;system( "composite -geometry "+geom_value+" "+dirlogo+"cmcc_logo_bw.jpg "+plname+".png "+plname+".png")
;system( "composite -geometry "+geom_value+" "+dirlogo+"cmcc_logo_bw.jpg "+plname+" "+plname)


end
