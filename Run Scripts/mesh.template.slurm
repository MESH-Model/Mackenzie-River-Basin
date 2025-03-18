#!/bin/sh

#SBATCH --nodes=1
#SBATCH --tasks-per-node=32
#SBATCH --time=168:00:00
#SBATCH --job-name=scn_MRB-CanRCM4-WGC
#SBATCH --mem-per-cpu=4G
#SBATCH --account=hpc_c_giws_elshamy
#SBATCH --mail-user=mohamed.elshamy@usask.ca
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#------------------------------------------------------ # Debugging section for PBS
echo "Node  $PBS_NODEFILE :"
echo "---------------------"
cat $PBS_NODEFILE
echo "---------------------"
echo "Shell is $SHELL"
NUM_PROCS=`/bin/awk 'END {print NR}' $PBS_NODEFILE`
echo "Running on $NUM_PROS processors."
echo "which mpirun = `which mpirun`"
#-------------------------------------------------------

module reset
module restore 2018
module list

echo `hostname`
echo "Current working directory is `pwd`"
echo "Starting run at: `date`"

#####
../run_mesh.sh $1 $2 $3 $4

echo "Program finished with exit code $? at: `date`"
exit 0
