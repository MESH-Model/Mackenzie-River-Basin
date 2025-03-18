#!/bin/bash
# -a: Export all variables
# -e: Exit if any commands returns non-zero exit
# -x: Print command trace
set -aex

#mesh=$HOME/MESH/02_MESH_Code_EXE/r1813_ME_NoThermalProperties/mpi_sa_mesh
mesh=$HOME/MESH/02_MESH_Code_EXE/r1860_ME/mpi_sa_mesh_dp_longSimFix4_No10mZsnow
#mesh=$HOME/MESH/02_MESH_Code_EXE/r1860_ME.all/mpi_sa_mesh.No10mZsnow.PartOutput
#mesh=$HOME/MESH/02_MESH_Code_EXE/ZEFT/r1813_ME/mpi_sa_mesh_weight
source ../Settings.sh

start=$1
end=$2
STYR1=$4

cp ~/project/01_MRB/286/$3/CC/resume/MESH_initial_values.$4'_001.nc' .
cp ~/project/01_MRB/286/$3/CC/resume/zone_storage_states.$4'_001.txt' . 
# Run the first spin-cycle only if the starting cycle = 1
# otherwise, it is a continuation run from the given start year STYR1 passed as $4
if [ $start -eq 1 ]
then
# =====================
# First Spinning Cycle
# =====================
	j=1
	echo Cycle$j
	cp -f $run_options 	MESH_input_run_options.ini
		sed -i "s/_IZ/$IZ/g" 		MESH_input_run_options.ini
		sed -i "s/_HF/180/g" 		MESH_input_run_options.ini
		sed -i "s/_TZ/-9/g" 		MESH_input_run_options.ini	
		sed -i "s/_TS/30/g" 		MESH_input_run_options.ini
		sed -i "s/_INT/1/g" 		MESH_input_run_options.ini
		sed -i "s/_PBSM/1/g"		MESH_input_run_options.ini
		sed -i "s/_SRF/6/g" 		MESH_input_run_options.ini
		sed -i "s/_RF/0/g" 			MESH_input_run_options.ini
		sed -i "s/_SFF/tb0/g" 		MESH_input_run_options.ini
		sed -i "s/_RVF/$RVF/g"		MESH_input_run_options.ini	
		sed -i "s/_DM/1/g" 			MESH_input_run_options.ini
		sed -i "s/_OF/1/g" 			MESH_input_run_options.ini
		sed -i "s/_AC/0/g" 			MESH_input_run_options.ini
		sed -i "s/_WBF/daily/g" 	MESH_input_run_options.ini
		sed -i "s/STYR/$STYR/g" 	MESH_input_run_options.ini
		sed -i "s/STD/244/g"		MESH_input_run_options.ini
		sed -i "s/ENYR/$ENYR1/g" 	MESH_input_run_options.ini
		sed -i "s/END/  1/g" 		MESH_input_run_options.ini
		
	rm -f MESH_initial_values.*	
	rm -f zone*
	rm -f auto*
	mkdir -p RESULTS #CLASS1
	# For the very first spin-up cycle, use a pre-defined temperature field - TBOT is what matter but also THIC and THLQ are provided to speed up spinning
	ln -sf $dir_inputs/MESH_initial_values.20220922.r2c MESH_initial_values.r2c
	mpirun $mesh

	cp MESH_initial_values.nc RESULTS/MESH_initial_values_Cycle$j.nc
	#cp zone* RESULTS
	mv RESULTS RESULTS_Cycle$j
	
	DZAA=''
	TZAA=''
	ALT=''
	ALT_DOY=''
	T=''

	# merge Tmax and Tmin files across levels then GRUs
	# merge ALT, DZAA, ALT_DOY across GRUs

	for g in `seq 1 $GRUs`	#GRUs
	do
		Tmin_max=''		
		for l in `seq 1 $levels`  #levels
		do
		#first merge Tmin & Tmax in one file per level
			min_max='RESULTS_Cycle'$j'/TSOL_MIN_Y_IG'$l'_GRU'$g'_GRD.nc '
			min_max=$min_max'RESULTS_Cycle'$j'/TSOL_MAX_Y_IG'$l'_GRU'$g'_GRD.nc '
			cdo merge $min_max 'RESULTS_Cycle'$j'/TSOL_MIN_MAX_Y_IG'$l'_GRU'$g'.nc'
			rm $min_max
			Tmin_max=$Tmin_max'RESULTS_Cycle'$j'/TSOL_MIN_MAX_Y_IG'$l'_GRU'$g'.nc '
		done
		#Then merge for all levels
		ncecat -O -F -u level $Tmin_max 'RESULTS_Cycle'$j'/Tmin_max_GRU'$g'.nc'
		rm $Tmin_max
		DZAA=$DZAA'RESULTS_Cycle'$j'/DZAA_TTOL_0p1_Y_GRU'$g'_GRD.nc '
		TZAA=$TZAA'RESULTS_Cycle'$j'/TZAA_TTOL_0p1_Y_GRU'$g'_GRD.nc '
		ALT=$ALT'RESULTS_Cycle'$j'/ALT_ENV_Y_GRU'$g'_GRD.nc '
        ALT_DOY=$ALT_DOY'RESULTS_Cycle'$j'/ALT_DOY_Y_GRU'$g'_GRD.nc '
		T=$T'RESULTS_Cycle'$j'/Tmin_max_GRU'$g'.nc '
	done
	echo $T	
    ncecat -O -F -4 -L 1 -u gru $T 'RESULTS_Cycle'$j'/Tmin_max.nc'
	echo $ALT
	ncecat -O -F -4 -L 1 -u gru $ALT 'RESULTS_Cycle'$j'/ALT.nc'
	echo $ALT_DOY
	ncecat -O -F -4 -L 1 -u gru $ALT_DOY 'RESULTS_Cycle'$j'/ALT_DOY.nc'	
	echo $DZAA
	ncecat -O -F -4 -L 1 -u gru $DZAA 'RESULTS_Cycle'$j'/DZAA_ttol_0.1.nc'
	echo $TZAA
	ncecat -O -F -4 -L 1 -u gru $TZAA 'RESULTS_Cycle'$j'/TZAA_ttol_0.1.nc'
	rm $T $ALT $ALT_DOY $DZAA $TZAA
	start=2
	#sleep 5
	#exit
fi

# =====================
# Now for regular spinning cycles
# =====================

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
echo $st1 > Permafrost.ncap
echo $st{2..4} >> Permafrost.ncap

rm -f MESH_initial_values.r2c
if [ $start -le $end ]
then
	cdo selname,Rank,GRU $ddb.nc GRU_tmp.nc
	cdo ifthen -selname,Rank GRU_tmp.nc GRU_tmp.nc GRU.nc
	cdo div GRU.nc GRU.nc GRU_tmp.nc
	ncap2 -A -F -v -s "gru_count=array(-1,0,$gru);gru_count=GRU.sum($lat,$lon);gru_count.set_miss(-1);" GRU_tmp.nc
	cdo delname,Rank,GRU GRU_tmp.nc GRU_count.nc
	rm GRU.nc GRU_tmp.nc

	st1="tbar_tol=array($tsol_tol,0,$level);tbar_tol.set_miss(-1);"
	st2="tile_sno_converged=array(-1,0,tile_sno);tile_sno_converged.set_miss(-1);where(abs(tile_sno)<=$sno_tol)tile_sno_converged=1;where(abs(tile_sno)>$sno_tol)tile_sno_converged=0;sno_converged=tile_sno_converged.sum($lat,$lon);"
	st3="tile_tbar_converged=array(-1,0,tile_tbar);tile_tbar_converged.set_miss(-1);where(abs(tile_tbar)<=tbar_tol)tile_tbar_converged=1;where(abs(tile_tbar)>tbar_tol)tile_tbar_converged=0;tbar_converged=tile_tbar_converged.sum($lat,$lon);"
	st4="tile_thlq_converged=array(-1,0,tile_thlq);tile_thlq_converged.set_miss(-1);where(abs(tile_thlq)<=$thlq_tol)tile_thlq_converged=1;where(abs(tile_thlq)>$thlq_tol)tile_thlq_converged=0;thlq_converged=tile_thlq_converged.sum($lat,$lon);"
	st5="tile_thic_converged=array(-1,0,tile_thic);tile_thic_converged.set_miss(-1);where(abs(tile_thic)<=$thic_tol)tile_thic_converged=1;where(abs(tile_thic)>$thic_tol)tile_thic_converged=0;thic_converged=tile_thic_converged.sum($lat,$lon);"
	st6="sno_converged_percent=100*sno_converged/gru_count;tbar_converged_percent=100*tbar_converged/gru_count;thlq_converged_percent=100*thlq_converged/gru_count;thic_converged_percent=100*thic_converged/gru_count;"
	st7="tbar_converged_min=100*tbar_converged.min($level)/gru_count;thlq_converged_min=100*thlq_converged.min($level)/gru_count;thic_converged_min=100*thic_converged.min($level)/gru_count;"
	st8="tbar_converged_mean=100*tbar_converged.avg($level)/gru_count;thlq_converged_mean=100*thlq_converged.avg($level)/gru_count;thic_converged_mean=100*thic_converged.avg($level)/gru_count;"
	echo $st1 > convergence.ncap
	echo $st{2..8} >> convergence.ncap

	st1="tbar_tol=array($tsol_tol,0,$level);tbar_tol.set_miss(-1);"
	st2="tile_Tmax_converged=array(-1,0,TSOL_MAX);tile_Tmax_converged.set_miss(-1);where(abs(TSOL_MAX)<=tbar_tol)tile_Tmax_converged=1;where(abs(TSOL_MAX)>tbar_tol)tile_Tmax_converged=0;Tmax_converged=tile_Tmax_converged.sum($lat,$lon);tile_Tmax_converged.set_miss(-1);"
	st3="tile_Tmin_converged=array(-1,0,TSOL_MIN);tile_Tmin_converged.set_miss(-1);where(abs(TSOL_MIN)<=tbar_tol)tile_Tmin_converged=1;where(abs(TSOL_MIN)>tbar_tol)tile_Tmin_converged=0;Tmin_converged=tile_Tmin_converged.sum($lat,$lon);tile_Tmin_converged.set_miss(-1);"
	st4="Tmax_converged_percent=100*Tmax_converged/gru_count;Tmin_converged_percent=100*Tmin_converged/gru_count;"
	st5="Tmax_converged_min=100*Tmax_converged.min($level)/gru_count;Tmax_converged_mean=100*Tmax_converged.avg($level)/gru_count;"
	st6="Tmin_converged_min=100*Tmin_converged.min($level)/gru_count;Tmin_converged_mean=100*Tmin_converged.avg($level)/gru_count;"
	echo $st1 > envelopes.ncap
	echo $st{2..6} >> envelopes.ncap

	cp -f $run_options 	MESH_input_run_options.ini
		sed -i "s/_IZ/$IZ/g" 		MESH_input_run_options.ini
		sed -i "s/_HF/180/g" 		MESH_input_run_options.ini
		sed -i "s/_TZ/-9/g" 		MESH_input_run_options.ini	
		sed -i "s/_TS/30/g" 		MESH_input_run_options.ini
		sed -i "s/_INT/1/g" 		MESH_input_run_options.ini
		sed -i "s/_PBSM/1/g"		MESH_input_run_options.ini
		sed -i "s/_SRF/6/g" 		MESH_input_run_options.ini
		sed -i "s/_RF/6/g" 			MESH_input_run_options.ini
		sed -i "s/_SFF/tb0/g" 		MESH_input_run_options.ini
		sed -i "s/_RVF/$RVF/g"		MESH_input_run_options.ini	
		sed -i "s/_DM/0/g" 			MESH_input_run_options.ini
		sed -i "s/_OF/1/g" 			MESH_input_run_options.ini
		sed -i "s/_AC/0/g" 			MESH_input_run_options.ini	
		sed -i "s/_WBF/daily/g" 	MESH_input_run_options.ini
		sed -i "s/STYR/$STYR/g" 	MESH_input_run_options.ini
		sed -i "s/STD/  1/g"		MESH_input_run_options.ini
		sed -i "s/ENYR/$ENYR/g" 	MESH_input_run_options.ini
		sed -i "s/END/  1/g" 		MESH_input_run_options.ini
		
	ln -sf $dir_MRB/outputs_balance.spin.txt outputs_balance.txt

	for j in `seq $start $end`
	do
		echo Spin-Cycle $j
		mkdir -p RESULTS
		srun $mesh

		cp MESH_initial_values.nc RESULTS/MESH_initial_values_Cycle$j.nc
		cp zone_storage_states.txt RESULTS/zone_storage_states_Cycle$j.txt
		#cp zone* RESULTS
		#cp int* RESULTS
		mv RESULTS RESULTS_Cycle$j
		(( i = j - 1 ))
		echo $i	
        echo 'convergence'
        ncdiff -O -F -4 -L 1 RESULTS_Cycle$j/MESH_initial_values_Cycle$j.nc RESULTS_Cycle$i/MESH_initial_values_Cycle$i.nc RESULTS_Cycle$j/diff_$j.nc
        ncwa   -O -F -4 -L 1 -y mabs -a lat,lon RESULTS_Cycle$j/diff_$j.nc RESULTS_Cycle$j/mabs_diff_$j.nc
        cdo     copy GRU_count.nc RESULTS_Cycle$j/converged_$j.nc
        ncap2  -A -F -v -S convergence.ncap RESULTS_Cycle$j/diff_$j.nc RESULTS_Cycle$j/converged_$j.nc
        # reinserting missing values that get lost because of a bug in ncap2
        ncap2  -A -F -s "tile_sno_converged.set_miss(-1);tile_tbar_converged.set_miss(-1);tile_thlq_converged.set_miss(-1);tile_thic_converged.set_miss(-1);" RESULTS_Cycle$j/converged_$j.nc
		
		DZAA=''
		TZAA=''
		ALT=''
		ALT_DOY=''
		T=''

		for g in `seq 1 $GRUs`	#GRUs
		do
			Tmin_max=''		
			for l in `seq 1 $levels`  #levels
			do
			#first merge Tmin & Tmax in one file per level
				min_max='RESULTS_Cycle'$j'/TSOL_MIN_Y_IG'$l'_GRU'$g'_GRD.nc '
				min_max=$min_max'RESULTS_Cycle'$j'/TSOL_MAX_Y_IG'$l'_GRU'$g'_GRD.nc '
				cdo merge $min_max 'RESULTS_Cycle'$j'/TSOL_MIN_MAX_Y_IG'$l'_GRU'$g'.nc'
				rm $min_max
				Tmin_max=$Tmin_max'RESULTS_Cycle'$j'/TSOL_MIN_MAX_Y_IG'$l'_GRU'$g'.nc '
			done
			#Then merge for all levels
			ncecat -O -F -L 1 -u level $Tmin_max 'RESULTS_Cycle'$j'/Tmin_max_GRU'$g'.nc'
			rm $Tmin_max
			DZAA=$DZAA'RESULTS_Cycle'$j'/DZAA_TTOL_0p1_Y_GRU'$g'_GRD.nc '
			TZAA=$TZAA'RESULTS_Cycle'$j'/TZAA_TTOL_0p1_Y_GRU'$g'_GRD.nc '
			ALT=$ALT'RESULTS_Cycle'$j'/ALT_ENV_Y_GRU'$g'_GRD.nc '
			ALT_DOY=$ALT_DOY'RESULTS_Cycle'$j'/ALT_DOY_Y_GRU'$g'_GRD.nc '
			T=$T'RESULTS_Cycle'$j'/Tmin_max_GRU'$g'.nc '
		done
		echo $T	
		ncecat -O -F -L 1 -u gru $T 'RESULTS_Cycle'$j'/Tmin_max.nc'
		echo $ALT
		ncecat -O -F -L 1 -u gru $ALT 'RESULTS_Cycle'$j'/ALT.nc'
		echo $ALT_DOY
		ncecat -O -F -L 1 -u gru $ALT_DOY 'RESULTS_Cycle'$j'/ALT_DOY.nc'	
		echo $DZAA
		ncecat -O -F -L 1 -u gru $DZAA 'RESULTS_Cycle'$j'/DZAA_ttol_0.1.nc'
		echo $TZAA
		ncecat -O -F -L 1 -u gru $TZAA 'RESULTS_Cycle'$j'/TZAA_ttol_0.1.nc'
		rm $T $ALT $ALT_DOY $DZAA $TZAA
		ncap2 -O -F -v -S Permafrost.ncap RESULTS_Cycle$j/Tmin_max.nc RESULTS_Cycle$j/permafrost_$j.nc
		if [ $i -gt 1 ]
		then
			echo 'envelope convergence'
			ncdiff -O -F -4 -L 1 RESULTS_Cycle$j/Tmin_max.nc RESULTS_Cycle$i/Tmin_max.nc RESULTS_Cycle$j/envelopes_diff_$j.nc
			ncks -A -F -4 -L 1 GRU_count.nc RESULTS_Cycle$j/envelopes_diff_$j.nc
			ncap2 -O -F -v -S envelopes.ncap RESULTS_Cycle$j/envelopes_diff_$j.nc RESULTS_Cycle$j/envelopes_converged_$j.nc
		fi
		#sleep 5
	done
	mkdir -p $run_name
	mv RESULTS_Cycle* $run_name
	cp MESH_parameters_CLASS.ini $run_name
	cp MESH_parameters_hydrology.ini $run_name
	cp MESH_input_soil_levels.txt $run_name
	cp MESH_input_run_options.ini $run_name
	#cp run_mesh.sh $run_name
else
	# exit
	j=$end
fi

if [ $j -ge $end ]
then
  if [ $STYR1 -eq $STYR ]
  then
#=====================
#Now for Main Run till 1967/31/12
#=====================

	ln -sf $dir_MRB/outputs_balance.run.txt outputs_balance.txt
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
		sed -i "s/_WBF/daily/g" 	MESH_input_run_options.ini
		sed -i "s/STYR/$STYR/g" 	MESH_input_run_options.ini
		sed -i "s/STD/  1/g"		MESH_input_run_options.ini
		sed -i "s/ENYR/1968/g" 		MESH_input_run_options.ini
		sed -i "s/END/  1/g" 		MESH_input_run_options.ini
		
	echo $STYR-1967
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
	mv RESULTS RESULTS_$STYR-1967
	STYR1=1968
  fi
  if [ $STYR1 -gt $STYR ]
  then
#=====================
#Now for Main Run from 1968/1/1
#=====================	
	ln -sf $ddb.r2c MESH_drainage_database.r2c
	ln -sf $dir_MRB/MESH_input_reservoir.24.20230501.tb0 MESH_input_reservoir.tb0
	ln -sf $dir_MRB/outputs_balance.run.v1.txt outputs_balance.txt
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
		sed -i "s/_DM/0/g" 		    MESH_input_run_options.ini
		sed -i "s/_OF/1/g" 		    MESH_input_run_options.ini
		sed -i "s/_AC/1/g" 	        MESH_input_run_options.ini
		sed -i "s/_WBF/daily/g" 	MESH_input_run_options.ini
		sed -i "s/STYR/$STYR1/g" 	MESH_input_run_options.ini
		sed -i "s/STD/  1/g"		MESH_input_run_options.ini
		sed -i "s/ENYR/2101/g" 		MESH_input_run_options.ini
		sed -i "s/END/  1/g" 		MESH_input_run_options.ini
		
	echo $STYR1-2040
	mkdir -p RESULTS #CLASS1
	mpirun $mesh

	# DZAA=''
	# TZAA=''
	# ALT=''
	# ALT_DOY=''
	THETA=''
	LATF=''
	
	cd RESULTS
		for g in `seq 1 $GRUs`	#GRUs
		do
			TH=''
            LF=''
			for l in `seq 1 $levels`  #levels
			do
			#first merge THIC & THLQ in one file per level
				T='THICSOL_M_IG'$l'_GRU'$g'_GRD.nc '
				T=$T'THLQSOL_M_IG'$l'_GRU'$g'_GRD.nc '
				cdo merge $T 'TH_M_IG'$l'_GRU'$g'.nc'
				#rm $T
				TH=$TH'TH_M_IG'$l'_GRU'$g'.nc '
				LF=$LF'LATFLW_M_IG'$l'_GRU'$g'_GRD.nc '
			done
			#Then merge for all levels
			ncecat -O -F -L 1 -u level $TH 'TH_M_GRU'$g'.nc'
			ncecat -O -F -L 1 -u level $LF 'LF_M_GRU'$g'.nc'
			#rm $TH $LF
			THETA=$THETA'TH_M_GRU'$g'.nc '
			LATF=$LATF'LF_M_GRU'$g'.nc '
		done
		echo $THETA	
		ncecat -O -F -L 1 -u gru $THETA 'THETA_M.nc'
		echo $LATF
		ncecat -O -F -L 1 -u gru $LATF 'LATFLW_M.nc'
		# ncecat -O -F -L 1 -u level LATFLW_D_IG*.nc 'LATFLW_D.nc'
		# # ncecat -O -F -L 1 -u gru $TZAA 'TZAA_ttol_0.1.nc'
		# rm $THETA $LATF LATFLW_D_IG*.nc
		# # ncap2 -O -F -v -S ../Permafrost.ncap Tmin_max.nc permafrost.nc

		# # st1="permafrost_gru_fraction_1=array($missing,0,permafrost_1);permafrost_gru_fraction_1.set_miss($missing);permafrost_gru_fraction_1=GRU*permafrost_1;permafrost_grid_fraction_1=permafrost_gru_fraction_1.sum($gru);"
		# # st2="permafrost_gru_area_1=array($missing,0,permafrost_gru_fraction_1);permafrost_gru_area_1.set_miss($missing);permafrost_gru_area_1=permafrost_gru_fraction_1*GridArea/1e6;Permafrost_Area_GRU_1=permafrost_gru_area_1.sum($lat,$lon);"
		# # st3="permafrost_grid_area_1=array($missing,0,permafrost_grid_fraction_1);permafrost_grid_area_1.set_miss($missing);permafrost_grid_area_1=permafrost_grid_fraction_1*GridArea/1e6;Permafrost_Area_1=permafrost_grid_area_1.sum($lat,$lon);"
		# # #st4="permafrost_gru_area@_FillValue=$missing;"
		# # echo $st1 > Permafraction.ncap
		# # echo $st2 >> Permafraction.ncap
		# # echo $st3 >> Permafraction.ncap
		# # st1="permafrost_gru_fraction_2=array($missing,0,permafrost_2);permafrost_gru_fraction_2.set_miss($missing);permafrost_gru_fraction_2=GRU*permafrost_2;permafrost_grid_fraction_2=permafrost_gru_fraction_2.sum($gru);"
		# # st2="permafrost_gru_area_2=array($missing,0,permafrost_gru_fraction_2);permafrost_gru_area_2.set_miss($missing);permafrost_gru_area_2=permafrost_gru_fraction_2*GridArea/1e6;Permafrost_Area_GRU_2=permafrost_gru_area_2.sum($lat,$lon);"
		# # st3="permafrost_grid_area_2=array($missing,0,permafrost_grid_fraction_2);permafrost_grid_area_2.set_miss($missing);permafrost_grid_area_2=permafrost_grid_fraction_2*GridArea/1e6;Permafrost_Area_2=permafrost_grid_area_2.sum($lat,$lon);"
		# # echo $st1 >> Permafraction.ncap
		# # echo $st2 >> Permafraction.ncap
		# # echo $st3 >> Permafraction.ncap
		# # st1="permafrost_gru_fraction_3=array($missing,0,permafrost_3);permafrost_gru_fraction_3.set_miss($missing);permafrost_gru_fraction_3=GRU*permafrost_3;permafrost_grid_fraction_3=permafrost_gru_fraction_3.sum($gru);"
		# # st2="permafrost_gru_area_3=array($missing,0,permafrost_gru_fraction_3);permafrost_gru_area_3.set_miss($missing);permafrost_gru_area_3=permafrost_gru_fraction_3*GridArea/1e6;Permafrost_Area_GRU_3=permafrost_gru_area_3.sum($lat,$lon);"
		# # st3="permafrost_grid_area_3=array($missing,0,permafrost_grid_fraction_3);permafrost_grid_area_3.set_miss($missing);permafrost_grid_area_3=permafrost_grid_fraction_3*GridArea/1e6;Permafrost_Area_3=permafrost_grid_area_3.sum($lat,$lon);"
		# # echo $st1 >> Permafraction.ncap
		# # echo $st2 >> Permafraction.ncap
		# # echo $st3 >> Permafraction.ncap
		# # #echo $st4 >> Permafraction.ncap
		# # #echo $st5 >> Permafraction.ncap
		# # cdo -selname,GRU,GridArea $ddb.nc tmp.nc
		# # ncks -A tmp.nc permafrost.nc
		# # ncap2 -4 -O -F -v -S Permafraction.ncap permafrost.nc permafrost2.nc
		# # ncap2 -4 -A -F -v -S Permafraction.ncap permafrost.nc permafrost2.nc
		# # ncks  -A -F -4 -L 1 permafrost2.nc permafrost.nc
		# # rm tmp.nc permafrost2.nc
	cd ..	
	# #mv CLASS1 RESULTS
	mv RESULTS RESULTS_$STYR1-$ENYR3
	fi
	#mv RESULTS_$STYR-2100 $run_name
fi
