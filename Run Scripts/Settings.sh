basin='MRB'
GRIDS=19598
levels=25
GRUs=15

IZ=1

if [ $IZ -eq 1 ]
then
	ZRFM=40.00
	ZRFH=40.00
else
	ZRFM=10.00
	ZRFH=2.00
fi

./link_inputs.nc.sh #$4 $basin $GRIDS

run_name=$basin'_'$3'-1860_ME-08v5.4_MRB15.mod32-30.PBSM.dp.'$end
dir_MRB=$HOME/MESH/03_MRB_Setup_Files/08_v5_15GRU
dir_inputs=$dir_MRB
run_options=$dir_MRB/MESH_input_run_options.template.WGC.nc.ini
ddb=$dir_MRB'/08_'$basin'_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2005_v5.4.PBSM.Pol0.01.LU'

ln -sf $ddb.'NoWilliston'.r2c MESH_drainage_database.r2c
ln -sf $dir_MRB/MRB_MESH_parameters.ODEP.Morg.uniform.zsnl-basin.r2c 	MESH_parameters.r2c
ln -sf $dir_MRB/MESH_parameters_hydrology.PBSM.MRB15.mod30.ini	    	MESH_parameters_hydrology.ini
cp -f  $dir_MRB/MESH_parameters_CLASS.PBSM.MRB15.mod32.template.ini 	MESH_parameters_CLASS.ini
        sed -i "s/_GRIDS/$GRIDS/g"      MESH_parameters_CLASS.ini
        sed -i "s/_ZRFM/$ZRFM/g"        MESH_parameters_CLASS.ini
        sed -i "s/_ZRFH/$ZRFH/g"        MESH_parameters_CLASS.ini
ln -sf $dir_MRB/outputs_balance.spin.txt 			outputs_balance.txt

STYR=1951
ENYR1=1952		# for yearly cycles
ENYR=1961		# for 10 year cycles
RVF=2

#ddb=$ddb.nc
