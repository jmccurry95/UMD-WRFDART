#!/bin/sh
#PBS -A UMCP0011
#PBS -N forecast
#PBS -q main 
#PBS -l walltime=00:05:00
#PBS -j oe
#PBS -k eod
#PBS -l select=1:ncpus=72:mpiprocs=72
#PBS -l job_priority=economy
#PBS -V

set -ex

source /etc/profile.d/z00_modules.sh
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

echo "==========================================="
echo "Starting 610_forecast.sh"
cd $cwd
echo `pwd`
echo "==========================================="

touch ./run_forecast_str

if [ -f rsl.out.integration ]; then rm rsl.out.integration; fi

mpiexec -n 72 -ppn 72 ./wrf.exe >> rsl.out.integration

touch ./run_forecast_done

exit 

