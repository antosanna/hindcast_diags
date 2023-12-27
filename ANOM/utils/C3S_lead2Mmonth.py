# coding: utf-8

""" Convert C3S files into a monthly mean prost processed files

C3S template fiels, come with a time variable that is no more a date. Instead is an integer (leadtime).
This script converts the leadtime in a datetime and than apply a montly mean.
The passed vars are converted in a desired format (see vars dictionary below).

EXIT CODES
0 OK
1 PASSED OPTIONS
2 VAR DICTIONARY
3 INPUT/OUTPUT FILE

"""

# loading libraries
import numpy as np
import xarray as xr
import os
#import Nio 
#import urllib3
from dateutil import rrule
from datetime import datetime, timedelta
import pandas as pd
import cftime
import sys, getopt
import argparse

__author__ = "Antonio Cantelli"
__copyright__ = "Copyright 2019, CMCC"
__license__ = "GPL"
__version__ = "0.0.1"
__maintainer__ = "Antonio Cantelli"
__email__ = "antonio.cantelli@cmcc.it"
__status__ = "Production"


# variable definition dictionary 'input var name':['desired name','units',number_tosum/multiply,math_function_to_make_conversion]. NB 1,np.multiply equal to no conversion
vars = {
'tas':['TREFHT','C',-273.15,np.add],  # if you want in K as a standard set ['TREFHT','K',0,np.add]
'tso':['TS','C',-273.15,np.add],  # if you want in K as a standard set ['TREFHT','K',0,np.add]
'lwepr':['PREC','m/day',1,np.multiply],
'psl':['PSL','mb',0.01,np.multiply],
'zg':['Z500','m',1,np.multiply],
'ta':['T850','C',-273.15,np.add]
}

def conversion(inputfile,varname,debuglevel,plev):
	if debuglevel:
		print('TEST: Input file is ', inputfile)
		print('TEST: Varname is ',varname,vars[varname])
	fname=inputfile #"cmcc_CMCC-CM2-v20160423_forecast_S2019020100_atmos_6hr_surface_tas_r50i00p00.nc"
	# openfile
	#rawt = xr.open_dataset(fpath+fnamet,engine='netcdf4')  #[var].loc[dict(lev_p=lev)].isel(time=0)
	raw = xr.open_dataset(fname,engine='netcdf4')  #[var].loc[dict(lev_p=lev)].isel(time=0)
	# set timeaxis leadtime equal to time
	raw['leadtime'].data = raw['time'].data

	# select only the level variables
	if 'plev' in raw.dims.keys():
		print(plev)
		raw = raw.loc[dict(plev=plev)]

	# make mean
	#rawm = raw.groupby('time.month').mean('leadtime') #this isnt working since groups all months togheter despite of years and sorting by number of month
	rawm = raw.resample(leadtime='1m').mean()
	# set variable attributes for new file
	rawm[varname].attrs = raw[varname].attrs
	# set global attributes
	rawm.attrs = raw.attrs

	# rename month axis with time
	new_varname = vars[varname][0]
	#rawm_time= rawm.rename(name_dict={'month':'time',varname:new_varname} ) #, inplace=False)
	rawm_time= rawm.rename(name_dict={'leadtime':'time',varname:new_varname} ) #, inplace=False)

	# make data and unit conversion
	apply_funct = vars[varname][3]
	coeff = vars[varname][2]
	rawm_time[new_varname].data = apply_funct( rawm_time[new_varname].data, coeff)
	rawm_time[new_varname].attrs['units'] = vars[varname][1]

	# convert reftime to a datetime format
	startdate = pd.to_datetime(str(rawm_time['reftime'].data)).strftime('%Y-%m-%d')
	# get days of year respect to the given stardate
	dfy = xr.cftime_range(startdate, periods=6, freq='MS', calendar = 'proleptic_gregorian').to_datetimeindex().dayofyear
	# Convert dfy in numpy array
	dfy = np.asarray(dfy)
	# since dfy restart the number of dayOfYear after any change of Year we have to increment it with 365
	for idx, val in enumerate(dfy):
		if idx >0:
			if dfy[idx] < dfy[idx-1]:
				dfy[idx] = val + 365	
	# set time units
	units = "days since "+startdate[0:4]+"-01-01 00:00"
	times_month = cftime.num2date(list(np.array(dfy) - 1), units=units, calendar='proleptic_gregorian')


	# assign the adjusted coords
	rawm_time.coords['time'] = times_month
	#rawm_time.coords['reftime'] = cftime.num2date(dfy[0]-1, units=units, calendar='proleptic_gregorian')
	rawm_time = rawm_time.drop('reftime')
	rawm_time = rawm_time.drop('lat_bnds')
	rawm_time = rawm_time.drop('lon_bnds')
	# adjust longitude (shifting)
	rawm_time.coords['lon'].data = rawm_time.coords['lon'].data -0.5
	#adjust type float64 to float32
	rawm_time[new_varname] = rawm_time[new_varname].astype(np.float32) 
	#if PREC remove notused field
	if new_varname == 'PREC' :
		rawm_time = rawm_time.drop('leadtime_bnds')

	return rawm_time

def test(testfile,inputfile,varname,plev):
	# check if file exist
	if os.path.isfile(testfile) and os.access(testfile, os.R_OK):
		print("TEST: testfile File exists and is readable")
	else:
	    print("TEST: Either the testfile file is missing or not readable")
	    sys.exit(3)	
	vars['tas'] = ['TREFHT','K',1,np.multiply]
	convertedfile = conversion(inputfile,varname,True,plev)
	inputmat = convertedfile['TREFHT'].data
	testmat  = xr.open_dataset(testfile,engine='netcdf4')['TREFHT'].data
	if inputmat.shape == testmat.shape:
		shapesareequal = True 
	else:
		print("TEST: Warning matrix shapes are not equal")
		print("TEST: ",inputmat.shape,testmat.shape)
	mean_squared_error = np.square(np.subtract(inputmat, testmat)).mean()
	return mean_squared_error

def main():
	parser = argparse.ArgumentParser(description='Convert C3S files into a monthly mean prost processed files. Any file contain only one field.')

	parser.add_argument('-i', action='store', dest='inputfile', help='C3S input file name',required = True)
	parser.add_argument('-o', action='store', dest='outputfile', help='Output file name',required = True)

	parser.add_argument('-t', action='store_true', default=False,dest='maketest',help='Perform a test')
	parser.add_argument('-plev', action='store', default=50000,dest='plev',help='Level of pressure [92500., 85000., 50000., 20000., 10000.]',
		choices=[92500., 85000., 50000., 20000., 10000.],type=float,required = False)	
	parser.add_argument('--version', action='version', version='%(prog)s 0.0.1')

	subparsers = parser.add_subparsers(help='Input nc file vars dictionary. 2 way (i) common - pass standard varname (ii) usdef - you define all ')
	var = subparsers.add_parser('common', help=' -v option is required only when option custom var (-cv*) is not used')
	var.add_argument('-v', action='store', dest='varname', help='Name of variable to process')

	customvar = subparsers.add_parser("usdef", help="Custom var allow to add a custom defined variable to convert any given file. ex -cvn NAMEIN -cvo NAMEOUT -cvu K -cvc 1 -cvm multiply ")
	customvar.add_argument('-cvn', action='store', dest='varname', help='Name of input variable to process',type=str,required = True)	
	customvar.add_argument('-cvo', action='store', dest='varnameout', help='Name of output variable to process',type=str,required = True)		
	customvar.add_argument('-cvu', action='store', dest='unit', help='Attribute used in netcdf (string)',type=str,required = True)	
	customvar.add_argument('-cvc', action='store', dest='coeff', help='Coefficient to be used for data conversion',type=float,required = True)			
	customvar.add_argument('-cvm', action='store', dest='function', help='Math operation to be applied over coefficient (add or multiply only)',choices=["add","multiply"],type=str,required = True)	

	# get arguments
	try:
		results = parser.parse_args()
		print(results)
	except:
		#print("ERROR: check your passed options")
		exit(1)

	inputfile = results.inputfile
	outputfile = results.outputfile
	testflag = results.maketest
	varname = results.varname
	plev = results.plev
	if 'unit' in results :
		if results.function == "add":
			func = np.add
		elif results.function == "multiply":
			func = np.multiply

		vars[varname] = [results.varnameout,results.unit,results.coeff,func]
		print("UDEF: Added new defined variable to dictionary")
		print("UDEF: ",varname,vars[varname] )

	# some checks
	try:
		vars[varname]
	except KeyError:
		print("Passed <var_name> is not a key in the hardcoded dictionary <vars>, try again (-v option) ")
		sys.exit(2)
	# defines input and test files for testcase 	
	if testflag :
		inputfile = "cmcc_CMCC-CM2-v20160423_forecast_S2019020100_atmos_6hr_surface_tas_r50i00p00.nc"
		testfile = "TREFHT_SPS3_sps_201902_050.nc"		
	# check if file exist
	if os.path.isfile(inputfile) and os.access(inputfile, os.R_OK):
		print("MAIN: Input File exists and is readable")
	else:
	    print("ERROR: Either the Input file is missing or not readable")
	    sys.exit(3)

	# call routine to test or to convert
	if testflag:
		mean_squared_error = test(testfile,inputfile,varname,plev)
		print("TEST: mean_squared_error ",mean_squared_error)
		if mean_squared_error > 3.1e-10 :
			print("TEST: Error too big. Test failed")
		else:
			print("TEST: Test passed. OK")
		sys.exit(0)
	else:
		# make conversion
		rawm_final = conversion(inputfile,varname,False,plev)
		# write over netcdf
		rawm_final.to_netcdf(outputfile)
		sys.exit(0)

#code to execute if called from command-line
if __name__ == "__main__":
	 main()

