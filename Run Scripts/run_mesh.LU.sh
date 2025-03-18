#!/bin/bash
# -a: Export all variables
# -e: Exit if any commands returns non-zero exit
# -x: Print command trace
set -aex

#mesh=$HOME/MESH/02_MESH_Code_EXE/mpi_sa_mesh_r1813_resume3_supersat_init_time_PBSM3_Distrib_ZF10_10mZsnow_CAN_TZAA_ZSNL_NudgeSDEP_dp_lastyear
mesh=$HOME/MESH/02_MESH_Code_EXE/r1860_ME.all/mpi_sa_mesh
source ../Settings.sh

#start=$2
#end=$3

#The following variables are required by both regular cycles and main run
sno_tol=1
tsol_tol=0.01
thic_tol=0.01
thlq_tol=0.01
lat='$lat'
lon='$lon'
level='$level'
gru='$gru'
missing='-999f'
TFREEZE=273.16
st1="level_permafrost=array($missing,0,TSOL_MAX);level_permafrost.set_miss($missing);where(TSOL_MAX<=$TFREEZE)level_permafrost=1;where(TSOL_MAX>$TFREEZE)level_permafrost=0;tile_permafrost=level_permafrost.sum($level);level_permafrost.set_miss($missing);"
LEVEL_THRESHOLD=1
st2="permafrost_1=array($missing,0,tile_permafrost);permafrost_1.set_miss($missing);where(tile_permafrost>=$LEVEL_THRESHOLD)permafrost_1=1;where(tile_permafrost<$LEVEL_THRESHOLD)permafrost_1=0;"
LEVEL_THRESHOLD=2
st3="permafrost_2=array($missing,0,tile_permafrost);permafrost_2.set_miss($missing);where(tile_permafrost>=$LEVEL_THRESHOLD)permafrost_2=1;where(tile_permafrost<$LEVEL_THRESHOLD)permafrost_2=0;"
LEVEL_THRESHOLD=3
st4="permafrost_3=array($missing,0,tile_permafrost);permafrost_3.set_miss($missing);where(tile_permafrost>=$LEVEL_THRESHOLD)permafrost_3=1;where(tile_permafrost<$LEVEL_THRESHOLD)permafrost_3=0;"

cp ./resume/MESH_initial_values.2021_001.nc .
cp ./resume/zone_storage_states.2021_001.txt .

echo $st1 > Permafrost.ncap
echo $st{2..4} >> Permafrost.ncap

ln -sf $dir_MRB/outputs_balance.run.txt outputs_balance.txt
#=====================
#Now for Main Run
#=====================
ln -sf $dir_MRB/MESH_input_reservoir.24.20230501.tb0 MESH_input_reservoir.tb0
for i in 2040 2085
do
	ddb=$dir_MRB'/08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_'$i'_v5.4.PBSM.Pol0.01.LU'
	ln -sf $ddb.r2c MESH_drainage_database.r2c 
	if [ $i == 2040 ]
	then
		STYR=2021
		ENYR=2066
	else
		STYR=2066
		ENYR=2101
	fi
	(( ENYR1 = ENYR -1 ))
	echo $STYR-$ENYR1
	cp -f $run_options 	MESH_input_run_options.ini
		sed -i "s/_IZ/$IZ/g" 		MESH_input_run_options.ini
		sed -i "s/_HF/180/g" 		MESH_input_run_options.ini
		sed -i "s/_TZ/-9/g" 		MESH_input_run_options.ini	
		sed -i "s/_TS/30/g" 		MESH_input_run_options.ini
		sed -i "s/_INT/1/g" 		MESH_input_run_options.ini
		sed -i "s/_PBSM/1/g"		MESH_input_run_options.ini
		sed -i "s/_SRF/6 yearly/g" 	MESH_input_run_options.ini
		sed -i "s/_RF/6 auto/g" 	MESH_input_run_options.ini
		sed -i "s/_SFF/tb0/g" 		MESH_input_run_options.ini
		sed -i "s/_RVF/$RVF/g"		MESH_input_run_options.ini	
		sed -i "s/_DM/0/g" 			MESH_input_run_options.ini
		sed -i "s/_OF/1/g" 			MESH_input_run_options.ini
		sed -i "s/_AC/1/g" 			MESH_input_run_options.ini
		sed -i "s/_WBF/ns daily/g" 	MESH_input_run_options.ini
		sed -i "s/STYR/$STYR/g" 	MESH_input_run_options.ini
		sed -i "s/STD/  1/g"		MESH_input_run_options.ini
		sed -i "s/ENYR/$ENYR/g" 	MESH_input_run_options.ini
		sed -i "s/END/  1/g" 		MESH_input_run_options.ini
		
	mkdir -p RESULTS #CLASS1
	srun $mesh

	DZAA=''
	TZAA=''
	ALT=''
	ALT_DOY=''
	T=''

	cd RESULTS
		for g in `seq 1 $GRUs`	#GRUs
		do
			Tmin_max=''		
			for l in `seq 1 $levels`  #levels
			do
			#first merge Tmin & Tmax in one file per level
				min_max='TSOL_MIN_Y_IG'$l'_GRU'$g'_GRD.nc '
				min_max=$min_max'TSOL_MAX_Y_IG'$l'_GRU'$g'_GRD.nc '
				cdo merge $min_max 'TSOL_MIN_MAX_Y_IG'$l'_GRU'$g'.nc'
				rm $min_max
				Tmin_max=$Tmin_max'TSOL_MIN_MAX_Y_IG'$l'_GRU'$g'.nc '
			done
			#Then merge for all levels
			ncecat -O -F -L 1 -u level $Tmin_max 'Tmin_max_GRU'$g'.nc'
			rm $Tmin_max
			DZAA=$DZAA'DZAA_TTOL_0p1_Y_GRU'$g'_GRD.nc '
			TZAA=$TZAA'TZAA_TTOL_0p1_Y_GRU'$g'_GRD.nc '
			ALT=$ALT'ALT_ENV_Y_GRU'$g'_GRD.nc '
			ALT_DOY=$ALT_DOY'ALT_DOY_Y_GRU'$g'_GRD.nc '
			T=$T'Tmin_max_GRU'$g'.nc '
		done
		echo $T	
		ncecat -O -F -L 1 -u gru $T 'Tmin_max.nc'
		echo $ALT
		ncecat -O -F -L 1 -u gru $ALT 'ALT.nc'
		echo $ALT_DOY
		ncecat -O -F -L 1 -u gru $ALT_DOY 'ALT_DOY.nc'	
		echo $DZAA
		ncecat -O -F -L 1 -u gru $DZAA 'DZAA_ttol_0.1.nc'
		echo $TZAA
		ncecat -O -F -L 1 -u gru $TZAA 'TZAA_ttol_0.1.nc'
		rm $T $ALT $ALT_DOY $DZAA $TZAA
		ncap2 -O -F -v -S ../Permafrost.ncap Tmin_max.nc permafrost.nc

		st1="permafrost_gru_fraction_1=array($missing,0,permafrost_1);permafrost_gru_fraction_1.set_miss($missing);permafrost_gru_fraction_1=GRU*permafrost_1;permafrost_grid_fraction_1=permafrost_gru_fraction_1.sum($gru);"
		st2="permafrost_gru_area_1=array($missing,0,permafrost_gru_fraction_1);permafrost_gru_area_1.set_miss($missing);permafrost_gru_area_1=permafrost_gru_fraction_1*GridArea/1e6;Permafrost_Area_GRU_1=permafrost_gru_area_1.sum($lat,$lon);"
		st3="permafrost_grid_area_1=array($missing,0,permafrost_grid_fraction_1);permafrost_grid_area_1.set_miss($missing);permafrost_grid_area_1=permafrost_grid_fraction_1*GridArea/1e6;Permafrost_Area_1=permafrost_grid_area_1.sum($lat,$lon);"
		#st4="permafrost_gru_area@_FillValue=$missing;"
		echo $st1 > Permafraction.ncap
		echo $st2 >> Permafraction.ncap
		echo $st3 >> Permafraction.ncap
		st1="permafrost_gru_fraction_2=array($missing,0,permafrost_2);permafrost_gru_fraction_2.set_miss($missing);permafrost_gru_fraction_2=GRU*permafrost_2;permafrost_grid_fraction_2=permafrost_gru_fraction_2.sum($gru);"
		st2="permafrost_gru_area_2=array($missing,0,permafrost_gru_fraction_2);permafrost_gru_area_2.set_miss($missing);permafrost_gru_area_2=permafrost_gru_fraction_2*GridArea/1e6;Permafrost_Area_GRU_2=permafrost_gru_area_2.sum($lat,$lon);"
		st3="permafrost_grid_area_2=array($missing,0,permafrost_grid_fraction_2);permafrost_grid_area_2.set_miss($missing);permafrost_grid_area_2=permafrost_grid_fraction_2*GridArea/1e6;Permafrost_Area_2=permafrost_grid_area_2.sum($lat,$lon);"
		echo $st1 >> Permafraction.ncap
		echo $st2 >> Permafraction.ncap
		echo $st3 >> Permafraction.ncap
		st1="permafrost_gru_fraction_3=array($missing,0,permafrost_3);permafrost_gru_fraction_3.set_miss($missing);permafrost_gru_fraction_3=GRU*permafrost_3;permafrost_grid_fraction_3=permafrost_gru_fraction_3.sum($gru);"
		st2="permafrost_gru_area_3=array($missing,0,permafrost_gru_fraction_3);permafrost_gru_area_3.set_miss($missing);permafrost_gru_area_3=permafrost_gru_fraction_3*GridArea/1e6;Permafrost_Area_GRU_3=permafrost_gru_area_3.sum($lat,$lon);"
		st3="permafrost_grid_area_3=array($missing,0,permafrost_grid_fraction_3);permafrost_grid_area_3.set_miss($missing);permafrost_grid_area_3=permafrost_grid_fraction_3*GridArea/1e6;Permafrost_Area_3=permafrost_grid_area_3.sum($lat,$lon);"
		echo $st1 >> Permafraction.ncap
		echo $st2 >> Permafraction.ncap
		echo $st3 >> Permafraction.ncap
		#echo $st4 >> Permafraction.ncap
		#echo $st5 >> Permafraction.ncap
		cdo -selname,GRU,GridArea $ddb.nc tmp.nc
		ncks -A tmp.nc permafrost.nc
		ncap2 -4 -O -F -v -S Permafraction.ncap permafrost.nc permafrost2.nc
		ncap2 -4 -A -F -v -S Permafraction.ncap permafrost.nc permafrost2.nc
		ncks  -A -F -4 -L 1 permafrost2.nc permafrost.nc
		rm tmp.nc permafrost2.nc
	cd ..	
	#mv CLASS1 RESULTS
	
	mv RESULTS RESULTS_$STYR-$ENYR1
done
