#!/bin/sh
cd ncl
   export mmfore=$1
   export SS=$2
export plottype="png"
   ncl tercile_t2m_glo.ncl
