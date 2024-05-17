#!/bin/sh
#PBS -A UMCP0011
#PBS -N obs_diag
#PBS -q main 
#PBS -l walltime=00:10:00
#PBS -j oe
#PBS -k eod
#PBS -l select=1:ncpus=2:mpiprocs=36:mem=5GB
#PBS -V

set -ex

# (1) obs_diag
ASSIM_INT_SECONDS=`expr $ASSIM_INT_MINS \* 60`
TIME_AIS_HALF=`expr $ASSIM_INT_SECONDS / 2` #(second)
TIME1=`expr $TIME_AIS_HALF - 1`
TIME2=$TIME_AIS_HALF

YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
MI=`echo ${CDATE}|cut -c 11-12`
DATE1=`date -d "${YY}${MM}${DD} ${HR}:${MI}:00 $TIME1 second ago" +%Y%m%d%H%M%S`
DATE2=`date -d "${YY}${MM}${DD} ${HR}:${MI}:00 $TIME2 second" +%Y%m%d%H%M%S`

# CDATE
S_YY0=`echo $CDATE | cut -b1-4`
S_MO0=`echo $CDATE | cut -b5-6`
S_DD0=`echo $CDATE | cut -b7-8`
S_HH0=`echo $CDATE | cut -b9-10`
S_MI0=`echo $CDATE | cut -b11-12`
S_SS0=00
# DATE1
S_YY1=`echo $DATE1 | cut -b1-4`
S_MO1=`echo $DATE1 | cut -b5-6`
S_DD1=`echo $DATE1 | cut -b7-8`
S_HH1=`echo $DATE1 | cut -b9-10`
S_MI1=`echo $DATE1 | cut -b11-12`
S_SS1=`echo $DATE1 | cut -b13-14`
# DATE2
S_YY2=`echo $DATE2 | cut -b1-4`
S_MO2=`echo $DATE2 | cut -b5-6`
S_DD2=`echo $DATE2 | cut -b7-8`
S_HH2=`echo $DATE2 | cut -b9-10`
S_MI2=`echo $DATE2 | cut -b11-12`
S_SS2=`echo $DATE2 | cut -b13-14`

cat > script.sed << EOF
  /first_bin_center/c\
  first_bin_center          = ${S_YY0},${S_MO0},${S_DD0},${S_HH0},${S_MI0},$S_SS0
  /last_bin_center/c\
  last_bin_center           = ${S_YY0},${S_MO0},${S_DD0},${S_HH0},${S_MI0},$S_SS0
  /bin_separation/c\
  bin_separation            = 0, 0, 0, 0, ${ASSIM_INT_MINS}, 0 ,
  /bin_width/c\
  bin_width                 = 0, 0, 0, 0, ${ASSIM_INT_MINS}, 0 ,
  /first_bin_start/c\
  first_bin_start           =  ${S_YY1},${S_MO1},${S_DD1},${S_HH1},${S_MI1},$S_SS1,
  /first_bin_end/c\
  first_bin_end             =  ${S_YY2},${S_MO2},${S_DD2},${S_HH2},${S_MI2},$S_SS2,
  /last_bin_end/c\
  last_bin_end              =  ${S_YY2},${S_MO2},${S_DD2},${S_HH2},${S_MI2},$S_SS2,
  /bin_interval_seconds/c\
  bin_interval_seconds      =  ${ASSIM_INT_SECONDS}
  
EOF
sed -f script.sed $TEMP_FILE1 > ./input.nml
./obs_diag

# (2) diff
ncdiff -O output_mean.nc input_mean.nc diff_mean.nc

# (3) RMSD, obs_seq_to_netcdf
./obs_seq_to_netcdf

#module load matlab/R2022a
#matlab -nodesktop -nosplash -r 'obs_diag_test; exit'

touch ./obs_diag_done


exit 

