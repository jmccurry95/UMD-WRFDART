#!/bin/sh
#PBS -A UMCP0011
#PBS -q main 
#PBS -N prep1_forecast
#PBS -l select=1:ncpus=1:mpiprocs=1:mem=5GB
#PBS -l walltime=00:00:50
#PBS -j oe
#PBS -k eod
#PBS -V
##PBS -q main 
##PBS -l select=1:ncpus=1:mpiprocs=1:mem=10gb
set -ex

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

echo "==========================================="
echo "Starting 606_prep1_forecast.sh"
cd $cwd
echo `pwd`
echo "==========================================="
#VARS_A="U,V,W,PH,T,MU,QVAPOR,QCLOUD,QRAIN,QICE,QSNOW,QGRAUP,QNICE,QNRAIN,U10,V10,T2,TH2,Q2,PSFC,REFL_10CM"

#VARS_A="U,V,W,PH,T,MU,QVAPOR,QCLOUD,QRAIN,QICE,QSNOW,QGRAUP,QHAIL,QNICE,QNRAIN,QNDROP,QNSNOW,QNGRAUPEL,QNHAIL,QVGRAUPEL,QVHAIL,U10,V10,T2,TH2,Q2,PSFC,REFL_10CM"
if [[ -v VARS_A ]]; then
echo 
else
echo "missing VARS_A variable"
exit 1
fi
#insert code to check if VARS_A is set as an environmental variable - if not then exit 

#--- VARS_A ---
NUM_VARS=`echo $VARS_A | grep -o ',' | wc -l`
for INUM in $(seq 0 $NUM_VARS)
do
  TMP_NUM=`expr $INUM + 1`
  TMP_VAR=`echo $VARS_A | cut -d"," -f$TMP_NUM`
  INCREMENT_VARS_A[$INUM]="$TMP_VAR"
done

NUM_VARS=${#INCREMENT_VARS_A[@]}
NUM_VARS=`expr $NUM_VARS - 1`
CYCLE_STR=''

for INUM in $(seq 0 $NUM_VARS)
do
  if [ $INUM -ne $NUM_VARS ]; then
    CYCLE_STR=`echo ${CYCLE_STR}${INCREMENT_VARS_A[$INUM]},`
  else
    CYCLE_STR=`echo ${CYCLE_STR}${INCREMENT_VARS_A[$INUM]}`
  fi
done

ncks -A -v $CYCLE_STR ./filter_restart_d01 ./wrfinput_d01

###--- VARS_B ---
##NUM_VARS=`echo $VARS_B | grep -o ',' | wc -l`
##for INUM in $(seq 0 $NUM_VARS)
##do
##  TMP_NUM=`expr $INUM + 1`
##  TMP_VAR=`echo $VARS_B | cut -d"," -f$TMP_NUM`
##  INCREMENT_VARS_B[$INUM]="$TMP_VAR"
##done
##
##NUM_VARS=${#INCREMENT_VARS_B[@]}
##NUM_VARS=`expr $NUM_VARS - 1`
##
##for INUM in $(seq 0 $NUM_VARS)
##do
##  TMP_VAR=${INCREMENT_VARS_B[$INUM]}
##  ncks -C -v $TMP_VAR ./filter_restart_d01 ${TMP_VAR}.nc
##  ncrename -h -O -v  $TMP_VAR,${TMP_VAR}_2 ${TMP_VAR}.nc
##  ncks -A ${TMP_VAR}.nc ./wrfinput_d01
##  rm ${TMP_VAR}.nc
##done





touch ./prep1_forecast_ready



exit 

