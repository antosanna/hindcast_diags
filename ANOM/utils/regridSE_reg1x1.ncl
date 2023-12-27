;======================================================================
; ESMF_all_1.ncl
;
; Concepts illustrated:
;   - Interpolating from one grid to another using ESMF software
;   - Interpolating data from an NCEP grid to a 5x5 degree global grid
;   - Writing data to a NetCDF file using the easy but inefficient method
;======================================================================
; This example is identical to ESMF_regrid_1.ncl, except it does the
; regridding in separate steps.  See ESMF_wgts_1.ncl for a faster 
; example of regridding using an existing weights file.
;======================================================================
; For more information about ESMF:
;
;        http://www.earthsystemmodeling.org/
;
; This script uses built-in functions that are only available in 
; NCL V6.1.0 and later.
;======================================================================
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;
; This file still has to be loaded manually
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
    WRITE_RESULTS = True 
    INTERP_METHOD = "bilinear"

;---Input file
    srcFileName = getenv("inputSE")
    print(srcFileName)

;---Output (and input) files
    srcGridName = "src_SCRIP.nc"
    dstGridName = "dst_SCRIP.nc"
    wgtFileName = "camSE_2_1deg.nc"

;---Set to True if you want to skip any of these steps
    SKIP_SRC_SCRIP_GEN = False
    SKIP_DST_SCRIP_GEN = False
    SKIP_WGT_GEN       = False

;--- Set external variable to read
    var=getenv("varm")
;----------------------------------------------------------------------
; Step 1, part 1
;     Convert original NetCDF file to an SCRIP convention file.
;----------------------------------------------------------------------
    sfile = addfile(srcFileName,"r")
    temp  = sfile->$var$               ; ( TIME, DEPTH, LAT, LON )
    temp@_FillValue=-999.
    time  = sfile->time
    ntime=dimsizes(time)
    sst=temp

 if(isfilepresent(srcGridName)) then
      print("Found srcGrid description "+srcGridName)
  else
      print("Creating srcGrid description "+srcGridName)
      Opt               =True
      Opt@ForceOverWrite=True
      Opt@Title         ="SE Grid"  
      Opt@Debug         =False ; True
      Opt@PrintTimings  =False ; True
      unstructured_to_ESMF(srcGridName,sfile->lat,sfile->lon,Opt)
      delete(Opt)
  end if

;----------------------------------------------------------------------
; Step 1, part 2
;     Convert destination grid to a SCRIP convention file.
;----------------------------------------------------------------------

  if(isfilepresent(dstGridName)) then
      print("Found dstGrid description "+dstGridName)
  else
      print("Creating dstGrid description "+dstGridName)
      Opt                = True
      Opt@LLCorner       = (/-89.5d,.5d /)
      Opt@URCorner       = (/ 89.5d, 359.5d /)
      Opt@ForceOverwrite = True
      Opt@PrintTimings   = True
      Opt@Title          = "World grid 1x1 degree resolution"
      latlon_to_SCRIP(dstGridName,"1deg",Opt)

;---Clean up
      delete(Opt)
  end if

;----------------------------------------------------------------------
; Step 2
;     Generate the weights that take you from the NCEP grid to a
;     5x5 degree grid.
;----------------------------------------------------------------------
if(isfilepresent(wgtFileName)) then
      print("Found WeightFile "+wgtFileName)
else
      print("Creating WeightFile "+wgtFileName)
      Opt               = True
      Opt@InterpMethod  ="bilinear" ; "patch", "conserve"
      Opt@ForceOverWrite=True
      Opt@SrcESMF       =True
      Opt@Debug         =False ; True
      Opt@PrintTimings  =False ; True
      ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName,Opt)
      delete(Opt)
end if

;----------------------------------------------------------------------
; Step 3
;     Apply the weights to a given variable on the NCEP file.
;----------------------------------------------------------------------
    Opt                = True
;   Opt@Debug          = True
    Opt@PrintTimings   = True

    temp_regrid = ESMF_regrid_with_weights(sst,wgtFileName,Opt)
    temp_regrid@_FillValue=1.e+20
    temp_regrid@missing_value=1.e+20

    printVarSummary(temp_regrid)

;----------------------------------------------------------------------
; Step 4
;     Write the regridded data to a NetCDF file
;----------------------------------------------------------------------
    if(WRITE_RESULTS) then
      rgrdFileName = getenv("out")
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
      rgrd_nc->t2m       = temp_regrid
    end if
end
