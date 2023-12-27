
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
    ;---Specify remap method  
    INTERP_METHOD = "bilinear"     ; "bilinear" , "patch", "conserve"

;---Specify source SE grid resolution
    EOBS_res    = "0.25deg"

;---Specify name of destination grid
    C3S_res     = "1deg"

;---Data file containing source grid (sample)
    EOBS_dir    = "/work/csp/sp2/VALIDATION/daily/E-OBS/tmax/"
    EOBS_file   = "tmax_1993-2017_"+EOBS_res+".nc"
    srcGridName = EOBS_dir+"EOBS_to_SCRIP.nc"

;---Data file containing destination grid
    C3S_dir     = EOBS_dir
    C3S_file    = "tmax_1993-2017_"+C3S_res+".nc"
    dfile       = addfile(C3S_dir+C3S_file,"r")
    dstGridName = C3S_dir+"dst_SCRIP.nc" ;C3S_dir+C3S_file

;---Specify name of weight file to be generated; name of destination grid; dst directory
    WgtFileDir  = EOBS_dir
    wgtFileName = WgtFileDir+"EOBS_"+EOBS_res+"_to_"+C3S_res+"."+INTERP_METHOD+".nc"
   
;---Sample plot options
    pltDir   = "./"
    pltType  = "x11"
    pltName  = "EOBS_"+str_upper(EOBS_res)+"_to_"+dstGridName
   
;---Get any variable to regrid
    var_name = "tx"                    ; TSOI(time, levgrnd, lndgrid)
;---Set to True if you want to skip any of these steps
    SKIP_SRC_SCRIP_GEN = False
    SKIP_DST_SCRIP_GEN = False
    SKIP_WGT_GEN       = False

;----------------------------------------------------------------------
; Step 1, part 1
;     Convert original NetCDF file to an SCRIP convention file.
;----------------------------------------------------------------------
    sfile    = addfile(EOBS_dir + EOBS_file,"r")
    temp     = sfile->$var_name$                 ; ( TIME, DEPTH, LAT, LON )

    if(.not.SKIP_SRC_SCRIP_GEN) then
;--- Convert to a SCRIP Convention file.
      Opt                = True
      Opt@ForceOverwrite = True
      Opt@PrintTimings   = True
      Opt@Title          = "C3S Grid"
      Opt@Mask2D         = where(ismissing(temp(0,:,:)),0,1)

      rectilinear_to_SCRIP(srcGridName,temp&latitude,temp&longitude,Opt)

;---Clean up
      delete(Opt)
   end if

;----------------------------------------------------------------------
; Step 1, part 2
;     Convert destination grid to a SCRIP convention file.
;----------------------------------------------------------------------
    if(.not.SKIP_DST_SCRIP_GEN) then
      Opt                = True
      Opt@LLCorner       = (/  25.d, -40.d/)
      Opt@URCorner       = (/  75.d,  70.d/)
      Opt@ForceOverwrite = True
      Opt@PrintTimings   = True

      latlon_to_SCRIP(dstGridName,"1x1",Opt)

;---Clean up
      delete(Opt)
    end if

;----------------------------------------------------------------------
; Step 2
;     Generate the weights that take you from the EOBS grid to a
;     1x1 degree grid.
;----------------------------------------------------------------------
    if(.not.SKIP_WGT_GEN) then
     
      Opt                  = True
      Opt@WgtFileName      = "EOBS_2_1deg.nc"   ; default is "weights_file.nc"
      Opt@InterpMethod     = INTERP_METHOD      ; patch takes longer
      Opt@ForceOverwrite   = True
      Opt@PrintTimings     = True
      Opt@Debug            = True

      ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName,Opt)

;---Clean up
      delete(Opt)
    end if

;----------------------------------------------------------------------
; Step 3
;     Apply the weights to a given variable on the NCEP file.
;----------------------------------------------------------------------
    Opt                = True
;   Opt@Debug          = True
    Opt@PrintTimings   = True

    temp_regrid = ESMF_regrid_with_weights(temp,wgtFileName,Opt)

    printVarSummary(temp_regrid)
;----------------------------------------------------------------------
; Step 4
;     Write the regridded data to a NetCDF file
;----------------------------------------------------------------------
      rgrdFileName = C3S_dir+C3S_file
      system("rm -f " + rgrdFileName)
      rgrd_nc = addfile(rgrdFileName,"c")

;---Create variable to hold global file attributes
      global = True
      copy_VarAtts(sfile, global)

      if (isatt(sfile,"title")) then
        global@TITLE = "REMAPPED: " + sfile@title
      end if
      global@remap         = "NCL: ESMF_regrid_with_weights (NCL version '" + \
                             get_ncl_version() + "')"
      global@remap_method  = INTERP_METHOD
      global@creation_date = systemfunc("date")

      fileattdef( rgrd_nc, global )        ; copy global file attributes
      filedimdef(rgrd_nc,"time",-1,True)   ; force an unlimited dimension
;
; Write variables to file. Coordinate arrays will be written
; automatically
;
      rgrd_nc->tx       = temp_regrid

;----------------------------------------------------------------------
; Plotting section
;
; This section creates filled contour plots of both the original
; data and the regridded data, and panels them.
;----------------------------------------------------------------------
    dims_in = dimsizes(temp)
    rank_in = dimsizes(dims_in)
    ntim    = dims_in(0)
    if (rank_in.ge.3) then
        klev = dims_in(1)
        nt  = 0
        kl  = klev/2
        ;LEV = temp&lev(kl)
    end if

    wks = gsn_open_wks("x11","ESMF_wgts")        ; send graphics to PNG file

;---Resources to share between both plots
    res                      = True              ; Plot mods desired.

    res@gsnMaximize          = True              ; Maximize plot

    res@cnFillOn             = True              ; color plot desired
    res@cnLinesOn            = False             ; turn off contour lines
    res@cnLineLabelsOn       = False             ; turn off contour labels
    res@cnFillMode           = "RasterFill"      ; turn raster on      

    res@gsnLeftString        = var_name    ; long_name is too long!
    res@gsnLeftString        = temp@long_name
    res@gsnCenterString      = ""
 
    res@gsnAddCyclic         = False

    dims = tostring(dimsizes(temp_regrid))
    rank = dimsizes(dims)
    res@tiMainString  = "Data regridded to C3S grid (" + \
                        str_join(dims(rank-2:)," x ") + \
                        ") using 'bilinear method"

    plot_regrid = gsn_csm_contour_map(wks,temp_regrid(nt,:,:),res)
end
