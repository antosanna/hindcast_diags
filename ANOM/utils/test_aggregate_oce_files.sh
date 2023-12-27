#!/bin/sh -l
#BSUB -P 0287
#BSUB -q s_medium
#BSUB -J test_aggregate_gridT_EquT
#BSUB -o logs/test_aggregate_gridT_EquT_%J.out
#BSUB -e logs/test_aggregate_gridT_EquT_%J.err

. $HOME/.bashrc
. $DIR_SPS35/descr_SPS3.5.sh
. $DIR_TEMPL/load_nco

set -evx

meshmask=$REPOSITORY/mesh_mask_from2000.nc
datadir=$FINALARCHIVE1/sps3.5_199310_001/ocn/hist
workdir=$SCRATCHDIR/ANDREA/test_oce
mkdir -p $SCRATCHDIR/ANDREA/test_oce

cd $workdir

flist=`ls -1 $datadir/sps3.5_199310_001_1d_??????01_????????_grid_T_EquT.zip.nc`
t=1
for ff in $flist ; do

	ncks -O --mk_rec_dmn time_counter $ff sps3.5_199310_001_1d_grid_T_EquT_m${t}.nc
        ncrename -O -d nav_lat,y sps3.5_199310_001_1d_grid_T_EquT_m${t}.nc
        ncks -O -F -d x,280,850 sps3.5_199310_001_1d_grid_T_EquT_m${t}.nc sps3.5_199310_001_1d_grid_T_PacEquT_m${t}.nc
	
	t=$(($t + 1))

done
ncrcat -O sps3.5_199310_001_1d_grid_T_PacEquT_m?.nc sps3.5_199310_001_1d_grid_T_PacEquT.nc

exit



