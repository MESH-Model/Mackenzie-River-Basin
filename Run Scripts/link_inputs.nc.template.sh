#$ -S /bin/sh

# specify the forcing data directory
dir_forcing=~/project/MRB_Climate_Forcing/280_CanRCM4_Cor_WFDEI-GEM-CaPA/scenario
# specify the common inputs data directory
dir_inputs=~/MESH/03_MRB_Setup_Files

# soft link to forcing data
ln -sf $dir_forcing/MRB_pr_scenario_z1_1951-2100.Feb29.nc4  	./basin_rain.nc
ln -sf $dir_forcing/MRB_wind_scenario_z1_1951-2100.Feb29.nc4 	./basin_wind.nc
ln -sf $dir_forcing/MRB_hus_scenario_z1_1951-2100.Feb29.nc4  	./basin_humidity.nc
ln -sf $dir_forcing/MRB_rsds_scenario_z1_1951-2100.Feb29.nc4 	./basin_shortwave.nc
ln -sf $dir_forcing/MRB_rlds_scenario_z1_1951-2100.Feb29.nc4  	./basin_longwave.nc
ln -sf $dir_forcing/MRB_ta_scenario_z1_1951-2100.Feb29.nc4 		./basin_temperature.nc
ln -sf $dir_forcing/MRB_ps_scenario_z1_1951-2100.Feb29.nc4 		./basin_pres.nc

# soft link to setup files
#ln -sf $dir_inputs/08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_2005_v5.PBSM.r2c	MESH_drainage_database.r2c
#ln -sf $dir_inputs/MESH_parameters_hydrology.15GRUs.PBSM.mod25.ini			MESH_parameters_hydrology.ini
#cp -f  $dir_inputs/MESH_parameters_CLASS.15GRUs.PBSM.mod25.template.ini		MESH_parameters_CLASS.ini
#sed -i "s/_GRIDS/19598/g" 											MESH_parameters_CLASS.ini
#ln -sf $dir_inputs/MRB_MESH_parameters.6L.v3.r2c     				MESH_parameters.r2c

ln -sf $dir_inputs/MRB_278.1951-2020.20220331.tb0				   	MESH_input_streamflow.tb0
ln -sf $dir_inputs/MESH_input_reservoir.24.20230501.NoWilliston.tb0 MESH_input_reservoir.tb0
ln -sf $dir_inputs/coeff_reserv.20230501.1968.txt					coeff_reserv.txt
ln -sf $dir_inputs/MESH_input_soil_levels.25L.txt		        	MESH_input_soil_levels.txt
ln -sf $dir_inputs/outputs_balance.spin.txt							outputs_balance.txt
