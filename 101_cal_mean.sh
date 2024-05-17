#!/bin/sh
#PBS -A UMCP0011
#PBS -N cal_mean
#PBS -q economy
#PBS -l walltime=00:03:00
#PBS -j oe
#PBS -k eod
#PBS -l select=1:ncpus=2:mpiprocs=36:mem=5GB
#PBS -V

set -ex


export -n LD_LIBRARY_PATH
module purge
module load ncarenv/1.2
module load intel/17.0.1
module load ncarcompilers/0.4.1
module load mpt
module load nco
module load ncl/6.6.2
module list
export LD_LIBRARY_PATH=/glade/u/apps/ch/opt/netcdf/4.8.1/intel/2022.1/lib:$LD_LIBRARY_PATH

ncea -O ./filter_out/filter_restart* ./output_mean.nc

#mv mean.nc ../output_mean.nc

touch ./cal_mean_done


exit 

