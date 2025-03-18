#!/bin/bash

for i in {8..10} 
do
	for k in {1..5}
	do
		j=$i'r'$k
		mkdir $j
		cd $j
			cp ../mesh.template.slurm ./mesh.slurm
			sed -i "s/scn/$j/g" 	mesh.slurm

			j='r'$i'i2p1r'$k
			cp ../run_mesh.template.sh ./run_mesh.sh
			sed -i "s/scn/$j/g" 	run_mesh.sh

			cp ../link_inputs.nc.template.sh ./link_inputs.nc.sh
			sed -i "s/scenario/$j/g" 	link_inputs.nc.sh
			./link_inputs.nc.sh
# Uncomment to submit jobs automatically
			#sbatch mesh.slurm 1 40 $j 1951
		cd ..
	done
done
