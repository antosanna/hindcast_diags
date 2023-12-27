# coding: utf-8

""" Convert C3S files into a monthly mean prost processed files

C3S template fiels, come with a time variable that is no more a date. Instead is an integer (leadtime).
This script converts the leadtime in a datetime.

EXIT CODES
0 OK
1 PASSED OPTIONS
2 VAR DICTIONARY
3 INPUT/OUTPUT FILE

"""

# loading libraries
import numpy as np
import xarray as xr
import os, sys
import urllib3
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
__status__ = "Production"

def get_script_path():
	return os.path.dirname(os.path.realpath(sys.argv[0]))

def leadtime2time(inputfile,debuglevel,stday,sthour):
	if debuglevel:
		print('TEST: Input file is ', inputfile)
	fname=inputfile 
	raw_time = xr.open_dataset(fname,engine='netcdf4')  

	if debuglevel:
		print('actual raw.coords time ',raw_time.coords['leadtime'])

	# set timeaxis leadtime equal to time
	raw_time['leadtime'].data = raw_time['time'].data

	# convert reftime to a datetime format
	startdate = pd.to_datetime(str(raw_time['reftime'].data)).strftime('%Y-%m-%d')
	if debuglevel:
		print('startdate: is ', startdate)

	# # set time units manually (only if tuh or tud are defined and passed)
	# if stday != None or sthour != None :
	# 	# difference between two consequent dates in hours
	# 	datediff = (raw['time'].data[1] -  raw['time'].data[0]  )/ np.timedelta64(1, 'h')
	# 	if debuglevel:
	# 		print('datediff',datediff)

	# 	# 6hourly
	# 	errfl = 0
	# 	 if datediff >= 6 and datediff < 24:	
	# 	 	units = "hours since "+startdate[0:7]+"-"+day+"T"+hour+":00:00Z"
	# 	 elif datediff >= 24 and datediff <= 15*24:	
	# 	 	units = "days since "+startdate[0:7]+"-"+day+"T"+hour+":00:00Z"
	# 	 elif datediff > 15*24 :	
	# 	 	units = "months since "+startdate[0:7]+"-"+day+"T"+hour+":00:00Z"
	# 	 else :
	# 	 	print( "ERROR not identified units. datediff= ",datediff,"D1 ",raw['time'].data[1],"D0 ",raw['time'].data[0] )
	# 	 	print(" user passed day and hour will be ignored. Units used for leadtime will be the same of time ") 
	# 	 	errfl = 1
	#  	#sys.exit(1)

	#raw_time.coords['time'] = times_adj
	if debuglevel:	
		print('new raw.coords time ',raw_time.coords['leadtime'])


	
	# adjust longitude (shifting)
	#raw_time.coords['lon'].data = raw_time.coords['lon'].data - 0.5

	# Convert leadtime encoding units to the time one
	raw_time.leadtime.encoding['units'] = raw_time.time.encoding['units']


	if debuglevel:	
		print(raw_time.leadtime.encoding['units'])

	#drop unused vars 
	raw_time = raw_time.drop('time')
	print("drop unused vars ")
	for var in ["leadtime_bnds" , "time_bnds" , "hcrs"] :
		if var in raw_time.keys():
			raw_time = raw_time.drop(var)
			#print(var)

	# delete realization and reftime from coordinates if they exist
	for var in ["realization" , "reftime"] :
		print("delete realization",var)
		if var in raw_time.coords.keys():
			del raw_time.coords[var]
			print(var)

	# rename dimension leadtime
	raw_time = raw_time.rename(name_dict={'leadtime': 'time'})

	#set _FillValue = None (but not for ocean tso var) equivalent to:
	# ncatted -O -a _FillValue,,d,, file.nc
	varlist = ["lat" , "lon" ]  +  raw_time.keys()
	print("set _FillValue = None")
	for var in varlist :
		if var != "tso":
			raw_time[var].encoding['_FillValue'] = None

	# delete bounds if they exist
	print("delete bounds")
	for var in ["bounds"] :
		if var in raw_time["time"].attrs.keys():
			del raw_time["time"].attrs[var]
			#print(var)

	return raw_time


def main():
	from argparse import RawTextHelpFormatter

	parser = argparse.ArgumentParser(description='This script takes a CMCC-SPS3 C3S nc file and change its leadtime variable to produce a consistent time variable. \
		\n Basically this script is equivalent to: \
		\n cdo settaxis,yy-mm-dd,hh:00,incr infile temp_yymm \
		\n cdo setreftime,yy-mm-dd,hh:00 temp_yymm outfile\
		',formatter_class=RawTextHelpFormatter)

	parser.add_argument('-i', action='store', dest='inputfile', help='C3S input file name',required = True)
	parser.add_argument('-o', action='store', dest='outputfile', help='Output file name',required = True)
	parser.add_argument('-ens', action='store', dest='ens_id', help='Ensamble identifier (eg 001)',required = True)	
	#parser.add_argument('-tud', action='store', dest='startingday', help='Specifies timeunit starting day',type=str,required = False)
	#parser.add_argument('-tuh', action='store', dest='startinghour', help='Specifies timeunit starting hour',choices=["00","06","12","18"],type=str,required = False)

	parser.add_argument('--version', action='version', version='%(prog)s 0.0.1')


	try:
		results = parser.parse_args()
		print(results)
	except:
		print("ERROR: check given options")
		exit(1)

	inputfile = results.inputfile
	outputfile = results.outputfile
	ensemble = results.ens_id

	stday=None
	sthour=None

	# load not required defined options (if they exist)
	if 'startingday' in results :
		stday = results.startingday
	# load not required  options (if they exist)
	if 'startinghour' in results :
		sthour = results.startinghour

	######## log file
	# orig_stdout = sys.stdout
	# start_date = pd.to_datetime(str(xr.open_dataset(inputfile,engine='netcdf4')['reftime'].data)).strftime('%Y-%m-%d')
	# if "PYLOG" in os.environ:
	# 	LOGDIR=PYLOG
	# else:
	# 	LOGDIR=get_script_path()

	# f = open(LOGDIR + '/' + start_date + '_' + ensemble + '.log', 'w')
	# sys.stdout = f
		
	# check if file exist
	if os.path.isfile(inputfile) and os.access(inputfile, os.R_OK):
		print("MAIN: Input File exists and is readable")
	else:
	    print("ERROR: Either the Input file is missing or not readable")
	    sys.exit(3)

	# call routine to test or to convert
	debuglevel = True
	rawm_final = leadtime2time(inputfile,debuglevel,stday,sthour)
	# write over netcdf (notes the encoding )
	rawm_final.to_netcdf(outputfile) #,  encoding={'lat': {'_FillValue': None}, 'lon': {'_FillValue': None}} )


#code to execute if called from command-line
if __name__ == "__main__":
	 main()

