;----------------------------------------------------------------------
; panel_15.ncl
;
; Concepts illustrated:
;   - Combining two sets of paneled plots on one page
;----------------------------------------------------------------------
; This script is similar to panel_15_old.ncl, except a function called
; "panel_two_sets" was used to make it easier to panel two sets of
; plots.
;
; This function enables you to panel two sets of contour plots on the
; same page, each with its own labelbar. The function will determine
; whether to use horizontal or vertical labelars, depending on how
; the two sets of plots are laid out in terms of rows and columns.
;----------------------------------------------------------------------
; You must download panel_two_sets.ncl for this script to run.
;----------------------------------------------------------------------

undef("createLabelBar")
function createLabelBar(wks: graphic, plt:graphic, lbres:logical)
begin
   getvalues plt@contour               ; object from which info extracted
      "cnFillColors"   : fill_colors   ; get the colors used
      "lbLabelStrings" : lbstrings     ; get the labels used
   end getvalues
   lbres@lbFillColors = fill_colors    ; associate with input lnres argument
   lbid = gsn_create_labelbar(wks,dimsizes(lbstrings)+1,lbstrings,lbres)
   return(lbid)
end

begin
;  name_from_ext=getenv("name_from_here")
;  units_from_ext=getenv("units_from_here")
  modfile=getenv("inpfile")
  comp=getenv("comp")
  cmp2obs=toint(getenv("cmp2obs_ncl"))
  lead=toint(getenv("lead"))
  st=toint(getenv("st"))
  pltname=getenv("pltname")
  pltype=getenv("pltype")
  varmod=getenv("varmod")
  varobs=getenv("varobs")
  cf=tofloat(getenv("cf"))
  mf=tofloat(getenv("mf"))
  print(mf)
  in = addfile(modfile,"r")
  print("----model file "+modfile)
  t=rm_single_dims(in->$varmod$)
  latmod=in->lat
  lonmod  = in->lon
  rad=4.0*atan(1.0)/180.0
  wgty_mod= cos(latmod*rad)
  print(" start-date is "+st)
  print("----lead is "+lead)
  tclim=dim_avg_n(t(lead:lead+2,:,:),0)
  tclim=(tclim+cf)*mf
  printMinMax(tclim,0)
  copy_VarMeta(t(0,:,:),tclim)
  tclim!0="lat"
  tclim!1="lon"
  tclim&lat=latmod
  tclim&lon=lonmod
  printVarSummary( wgty_mod)
  printVarSummary(tclim)
  if(cmp2obs.eq.1)then
     obsfile=getenv("obsfile")
     print("----observations file "+obsfile)
     in = addfile(obsfile,"r")
     lon  = in->lon
     lat  = in->lat
     tobs  = in->$varobs$
;     if(varmod.eq."EnBalSrf".or.varmod.eq."ALBEDOS" .or. varmod.eq."SHFLX" .or. varmod.eq."LHFLX" .or. varobs.eq."var167".or.varmod.eq."CLDTOT".or.varmod.eq."CLDHGH".or.varmod.eq."CLDMED".or.varmod.eq."CLDLOW".or.varmod.eq."FSDS".or.varmod.eq."FSNS".or.varmod.eq."FSNT".or.varmod.eq."FSNTOA".or.varmod.eq."TS".or.varmod.eq."FLDS")then
;        tobs  = in->$varobs$(:,::-1,:)
;        lat  = in->lat(::-1)
;     end if
;     if (varmod.eq."FLNT" .or. varmod.eq."FLNS")then
;        tobs  = -(in->$varobs$(:,::-1,:)) ; different sign convention for longwave radiation btw era5 and cam
;        lat  = in->lat(::-1)
;     end if
;     if (varobs.eq."Z" .or. varobs.eq."U".or.varobs.eq."var131".or.varobs.eq."var129")then
;        lev=toint(getenv("ncl_lev"))
;        print("level index "+lev)
;        tobs  = in->$varobs$(:,lev,:,:)
;        if (varobs.eq."var131".or.varobs.eq."var129")then
;           lat  = in->lat(::-1)
;           tobs  = in->$varobs$(:,lev,::-1,:)
;           if (varobs.eq."var129")then
;              tmp=tobs/9.8065
;              copy_VarMeta(tobs,tmp)
;              tobs=tmp
;           end if
;        end if
;        if (varobs.eq."Z")then
;           tmp=tobs*100
;           copy_VarMeta(tobs,tmp)
;           tobs=tmp
;           printMinMax(tobs,0)
;           delete(tmp)
;        end if
;     end if
     if(st+lead+2-1.le.11)then   ;take into account indicing from 0
        istart=st+lead-1
        iend=st+lead-1+2
        print("selecting months from obs "+istart+"to "+iend)
        tobsclim=dim_avg_n(tobs(st+lead-1:st-1+lead+2,:,:),0)
     else
        tobsclim=(tobs(st+lead-1:st-1+lead,:,:)+tobs(st+lead:st+lead,:,:)+tobs(st+lead+1:st+lead+1,:,:))/3.
     end if
     if(varmod.eq."TREFHT".or.varmod.eq."TS".or.varmod.eq."TREFMNAV")then
        tobsclim=(tobsclim+cf)*mf
        copy_VarMeta(tobs(0,:,:),tobsclim)
     end if
     wgty_obs=cos(lat*rad)
     printVarSummary(wgty_obs)
     printVarSummary(tobsclim)
     printMinMax(tobsclim,0)
  end if
;---Common definitions
;  FillPalette     = "gui_default"    ; set color map
  FillPalette     = read_colormap_file("amwg") 
  if(varmod.eq."CLDTOT".or.varmod.eq."CLDLOW".or.varmod.eq."CLDMED".or.varmod.eq."CLDHGH".or.varmod.eq."H2OSNO".or.varmod.eq."SNOWDP".or.varmod.eq."hi".or.varmod.eq."aice")then
      delete(FillPalette)
;      cmap = read_colormap_file("WhiteBlue")
;      FillPalette     = cmap(::-1,:)
      FillPalette     = read_colormap_file("amwg") 
  end if
  if(varmod.eq."H2OSNO".or.varmod.eq."SNOWDP")then
     tclim@_FillValue=-999.
     tclim=where(tclim.lt.0.05,tclim@_FillValue,tclim)
  end if
  if(varmod.eq."QOVER")then
     tclim@_FillValue=-999.
     tclim=where(tclim.lt.0.00005,tclim@_FillValue,tclim)
  end if
  if(varmod.eq."ICEFRAC")then
     tclim@_FillValue=-999.
     tclim=where(tclim.lt.0.1,tclim@_FillValue,tclim)
  end if
  if(comp.eq."lnd")then
     OceanFillColor      = "grey"
     MissingValFillColor = "grey"
  end if
  CenterString = getenv("title1")
  LeftString   = t@long_name
  RightString   = t@units

; if(name_from_ext.eq.1)then
;    delete(LeftString)
;    LeftString=getenv("title")
; end if
; if(units_from_ext.eq.1)then
;    units=getenv("units")
;    delete(RightString)
;    RightString=units
; end if

  wks = gsn_open_wks(pltype,pltname)
     plot = new(3,graphic)
     res                   = True             ; plot mods desired

     res@gsnDraw               = False
     res@gsnFrame              = False
     res@gsnAddCyclic          = True    ; data is regional

     res@cnFillOn              = True     ; turn on color fill
     res@cnLinesOn             = False    ; turn of contour lines
     res@cnLineLabelsOn        = False    ; turn of contour line labels
     res@cnFillPalette  = FillPalette

     res@lbLabelBarOn          = False

    ; res@tmYLLabelsOn          = False    ; turn off lat labels
    ; res@tmXBLabelsOn          = False    ; turn off lon labels

; Set up labelbar resources for the 2 vertical labelbars
; Some of these may change depending upon the nrow and ncols 
;****************************************************************************
     lbres                     = True                ; common resources for both
                                                  ; horizontal and vertical bars
     lbres@lbPerimOn           = False               ; no label bar box
     lbres@lbLabelFontHeightF  = 0.012               ; label font height
     lbres@lbLabelAlignment    = "InteriorEdges"     ; where to label
     lbres@lbMonoFillPattern   = True                ; solid fill

; Bottom Vertical Label bar (Projection)
     lbhres                    = lbres
     lbhres@lbOrientation      = "Vertical"        ; orientation
     lbhres@vpXF               = 0.78
     lbhres@vpYF               = 0.30
     lbhres@vpWidthF           = 0.05                ; size
     lbhres@vpHeightF          = 0.22

; Right Vertical Label bar (Hist)
     lbvres                    = lbres
     lbvres@lbOrientation      = "Vertical"          ; orientation
     lbvres@vpXF               = 0.78   
     lbvres@vpYF               = 0.9
     lbvres@vpWidthF           = 0.05                ; size
     lbvres@vpHeightF          = 0.5

;****************************************************************************
; Generate panel entries
;****************************************************************************
   

    ;********************************
    ; Future Projection changes
    ;********************************
     res@cnMinLevelValF       =  0.0            ; set min contour level
     res@cnMaxLevelValF       = 12.0            ; set max contour level
     res@cnLevelSpacingF      =  1.0            ; set contour spacing

     if(comp.eq."lnd")then
        res@cnMissingValFillColor =MissingValFillColor
        res@mpOceanFillColor      = OceanFillColor
     end if

     res@cnLevelSelectionMode = "ManualLevels"; manual set levels so lb consistent
     res@cnMinLevelValF       = tofloat(getenv("minplot"))             ; min level
     res@cnMaxLevelValF       = tofloat(getenv("maxplot"))            ; max level
     res@cnLevelSpacingF      = tofloat(getenv("delta"))             ; contour interval
;     if(res@cnLevelSpacingF.eq.0.)then
;        res@cnMinLevelValF=min(tclim)
;        res@cnMaxLevelValF=max(tclim)
;        res@cnLevelSpacingF=toint((max(tclim)-min(tclim))/10.)
;     end if
;     res@mpLandFillColor      = "white"       ; make land white
     if(varmod.eq."PRECC".or.varmod.eq."PRECT".or.varmod.eq."PRECL")then
        delete(res@cnLevelSelectionMode)
        res@cnLevelSelectionMode="ExplicitLevels"
        res@cnLevels     = (/.2,.5,1,2.,3.0,4.0,5.,6.,7.,8.,9.,10.,12.,14.,17./)
     end if
     if(varmod.eq."ICEFRAC")then
        delete(res@cnLevelSelectionMode)
        res@cnLevelSelectionMode="ExplicitLevels"
        delete(res@cnLevels)
        res@cnLevels     = (/.2,.3,.4,.5,.6,.7,.8,.9/)
     end if

     res@gsnCenterString = CenterString
     res@gsnLeftString   = LeftString
     res@gsnRightString   = RightString

     plot(0) = gsn_csm_contour_map(wks,tclim, res)

     res@gsnCenterString = getenv("title2")
     tobsclim!0="lat"
     tobsclim!1="lon"
     tobsclim&lat=lat
     tobsclim&lon=lon
     tobsclim&lat@units="degree_N"
     tobsclim&lon@units="degree_E"
     delete(res@gsnLeftString)
     delete(res@gsnRightString)
     plot(1) = gsn_csm_contour_map(wks,tobsclim, res)
     lbhid = createLabelBar(wks, plot, lbvres)

    ;********************************
    ; Hist (Rightmost column)
    ;********************************
     res@gsnCenterString = "Model - Observations"
     res@cnMinLevelValF       =  0.0            ; set min contour level
     res@cnMaxLevelValF       = 26.0            ; set max contour level
     res@cnLevelSpacingF      =  1.0            ; set contour spacing

     delete(res@cnFillPalette)
     cmap1 = read_colormap_file("hotcold_18lev")
     res@cnFillPalette     = cmap1
     if(varmod.eq."TREFHT".or.varmod.eq."TS".or.varmod.eq."TREFMNAV")then
        res@cnLevelSelectionMode="ExplicitLevels"
;        res@cnLevels     = (/-5.,-3.,-2.,-1.,-.25,.25,1.,2,3,5/)
        res@cnLevels     = (/-4.,-2.,-1.5,-1.,-.5,.5,1.,1.5,2,4/)
     else
        res@cnLevelSelectionMode = "ManualLevels"; manual set levels so lb consistent
        res@cnMinLevelValF       = tofloat(getenv("minplotdiff"))             ; min level
        res@cnMaxLevelValF       = tofloat(getenv("maxplotdiff"))            ; max level
        res@cnLevelSpacingF      = tofloat(getenv("deltadiff"))             ; contour interval
     end if
     if(varmod.eq."PRECT")then
        delete(res@cnFillPalette)
        cmap2 = read_colormap_file("hotcold_18lev")
;        cmap2 = read_colormap_file("nrl_sirkes")
        res@cnFillPalette     = cmap2(::-1,:)
        delete(res@cnLevels)
        res@cnLevelSelectionMode="ExplicitLevels"
        res@cnLevels     = (/-8,-6,-4,-3,-2,-1,-0.5,0.5,1,2,3,4,6,8/)
;        res@cnMinLevelValF=-5.
;        res@cnMaxLevelValF=5.
;        res@cnLevelSpacingF      = 1.
     end if
;     print(lonmod)
;     print(latmod)
;     print(lon)
;     print(lat)
     if (varmod.eq."FSNT") then
          res@gsnLeftString   = LeftString
     end if
     tclim_in_obs = linint2_Wrap (lonmod,latmod,tclim, True, lon,lat, 0)
     printMinMax(tclim_in_obs,0)
     diff=tclim_in_obs-tobsclim
     diff!0="lat"
     diff!1="lon"
     diff&lat=lat
     diff&lon=lon
     diff&lat@units="degree_N"
     diff&lon@units="degree_E"
     if(varmod.eq."ALBEDOS" .or. varmod.eq."ALBEDO")then
         print("managing NaN in ALBEDO diff")
         diff@_FillValue=-999.
         diff=where(diff.lt.-2.,diff@_FillValue,diff)
         diff=where(diff.gt.2.,diff@_FillValue,diff)
     end if
     res@gsnLeftString   = ""
     res@gsnRightString   = ""
     plot(2) = gsn_csm_contour_map(wks,diff, res)
     
    ;********************************
    ; Vertical labelbar: Extract info needed for Hist (right) labelbar
    ;********************************
     lbvid = createLabelBar(wks, plot, lbhres)


;****************************************************************************
; Draw the panel and label bars
;****************************************************************************
     resP = True
     resP@gsnPanelMainString = st+" lead "+lead
     resP@gsnMaximize = True
     resP@gsnFrame    = False
 ;resP@gsnPanelRight  = 0.98
     resP@gsnPanelBottom = 0.045 

     gsn_panel(wks,plot,(/3,1/),resP)  ; plots

     draw(lbvid)                             ; vertical label bar
     draw(lbhid)                             ; horizontal label bar
     txres               = True
     txres@txFontHeightF = 0.01
     gsn_text_ndc(wks,"max="+sprintf("%7.2f",max(tclim)),0.82,0.945,txres)
     gsn_text_ndc(wks,"min="+sprintf("%7.2f",min(tclim)),0.82,0.93,txres)
     gsn_text_ndc(wks,"mean="+sprintf("%7.2f",wgt_areaave_Wrap(tclim, wgty_mod, 1.0, 1)),0.82,0.915,txres)
     gsn_text_ndc(wks,"max="+sprintf("%7.2f",max(tobsclim)),0.82,0.3955,txres)
     gsn_text_ndc(wks,"min="+sprintf("%7.2f",min(tobsclim)),0.82,0.3805,txres)
     gsn_text_ndc(wks,"mean="+sprintf("%7.2f",wgt_areaave_Wrap(tobsclim, wgty_obs, 1.0, 1)),0.82,0.3655,txres)
     gsn_text_ndc(wks,"mean="+sprintf("%7.2f",wgt_areaave_Wrap(diff, wgty_obs, 1.0, 1)),0.82,0.03,txres)
     gsn_text_ndc(wks,"max="+sprintf("%7.2f",max(diff)),0.82,0.06,txres)
     gsn_text_ndc(wks,"min="+sprintf("%7.2f",min(diff)),0.82,0.045,txres)
     frame(wks)
end
