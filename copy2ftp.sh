#!/bin/sh -l
. ~/.bashrc
. $DIR_UTIL/descr_CPS.sh

set -euvx
cd /work/csp/as34319/diagnostics/SPS4_hindcast/plots
sftp sps@sps4.cmcc.scc << EOF
cd html
put -r 05
put -r 07
put -r 08
put -r 10
put -r 11
exit
EOF

cd /work/csp/cp1/CPS/CMCC-CPS1/src/util
sftp sps@sps4.cmcc.scc << EOF
cd html/HSTATUS
put *.htm
exit
EOF
