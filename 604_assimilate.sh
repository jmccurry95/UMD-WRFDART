#!/bin/sh
#PBS -A UMCP0011
#PBS -N assimilate
#PBS -q main 
#PBS -l walltime=WALLTIME000
#PBS -j oe
#PBS -k eod
#PBS -l select=NNODES000:ncpus=NCPUSPERNODE000:mpiprocs=NCPUSPERNODE000
#PBS -l job_priority=economy
#PBS -V

set -ex

source /etc/profile.d/z00_modules.sh
echo "==========================================="
echo "Starting 604_assimilate.sh"
echo `pwd`
echo "==========================================="

export -n LD_LIBRARY_PATH
module purge
module load ncarenv/23.09
module load craype/2.7.23
module load intel/2023.2.1
module load ncarcompilers/1.0.0
module load cray-mpich/8.1.27
module load hdf5/1.12.2
module load netcdf/4.9.2
module load nco/5.1.9
module load ncview/2.1.9
module list
#export LD_LIBRARY_PATH=/glade/u/apps/ch/opt/netcdf/4.8.1/intel/2022.1/lib:$LD_LIBRARY_PATH

#export MPI_SHEPHERD=TRUE
export TMPDIR=/dev/shm
mpiexec -n NCPUSTOTAL000 -ppn NCPUSPERNODE000  ./filter

touch ./filter_done

exit 

