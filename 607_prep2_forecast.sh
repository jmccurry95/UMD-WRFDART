#!/bin/sh
#PBS -A UMCP0011
#PBS -N prep2_forecast
#PBS -q main 
#PBS -l walltime=00:05:00
#PBS -j oe
#PBS -k eod
#PBS -l select=1:ncpus=1:mpiprocs=36:mem=5GB
#PBS -V
##PBS -q casper@casper-pbs
##PBS -l select=1:ncpus=1:mpiprocs=1:mem=10gb
set -ex
echo "==========================================="
echo "Starting 607_prep2_forecast.sh"
cd $cwd
echo `pwd`
echo "==========================================="

ENS_MEM=`cat text_ens_mem`

#------------------------------------------------------
# radar additive noise option
#------------------------------------------------------
TIME_BTP_HALF=`expr $TIME_BTP / 2` #(second)
TIME1=`expr $TIME_BTP_HALF - 1`
TIME2=$TIME_BTP_HALF

YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
MI=`echo ${CDATE}|cut -c 11-12`
DATE1=`date -d "${YY}${MM}${DD} ${HR}:${MI}:00 $TIME1 second ago" +%Y%m%d%H%M%S`
DATE2=`date -d "${YY}${MM}${DD} ${HR}:${MI}:00 $TIME2 second" +%Y%m%d%H%M%S`

GDATE1=`echo $DATE1 0 -g | ${ADVANCE_TIME}`
GDATE2=`echo $DATE2 0 -g | ${ADVANCE_TIME}`
GDATE3=`echo $CDATE 0 -g | ${ADVANCE_TIME}`

GDATE1_ARRAY=($GDATE1)
GDATE1_1=${GDATE1_ARRAY[0]}
GDATE1_2=${GDATE1_ARRAY[1]}
GDATE2_ARRAY=($GDATE2)
GDATE2_1=${GDATE2_ARRAY[0]}
GDATE2_2=${GDATE2_ARRAY[1]}
GDATE3_ARRAY=($GDATE3)
GDATE3_1=${GDATE3_ARRAY[0]}
GDATE3_2=${GDATE3_ARRAY[1]}

if [ $ADD_NOISE_FLAG = YES ]; then
  if [ ! -f $C_CYCL_WORK_DIR/filter_skip_flag ]; then
    ./grid_refl_obs ./obs_seq.final $MINI_REF $GDATE1_1 $GDATE1_2 $GDATE2_1 $GDATE2_2 ./wrfinput_d01
    ./add_pert_where_high_refl ./refl_obs.txt ./wrfinput_d01 $HORI_LEN $VERT_LEN $NOISE_UU $NOISE_VV $NOISE_WW $NOISE_TT $NOISE_TD $NOISE_QV $GDATE3_1 $GDATE3_2 $ENS_MEM
  fi
fi

#------------------------------------------------------
# Add noise  
#------------------------------------------------------
HR=`echo ${CDATE}|cut -c 9-10`
CMD3="ncl 'MEM_NUM=${ENS_MEM}' 'CYCLE=${DD}${HR}' ./add_bank_perts.ncl"
if [ -f ./nclrun3.out ]; then rm ./nclrun3.out ; fi
cat > ./nclrun3.out << EOF
$CMD3
EOF
chmod +x ./nclrun3.out
#-- 1 --
./nclrun3.out >& add_perts.out
if [ -z add_perts.err ]; then
  echo "Perts added to member ${ENS_MEM}"
fi
#-- 2 --
mv wrfvar_output wrfinput_next
ln -fs wrfinput_d01 wrfinput_this
ln -fs wrfbdy_d01 wrfbdy_this
./pert_wrf_bc > out.pert_wrf_bc
rm wrfinput_next wrfinput_this wrfbdy_this

#------------------------------------------------------
# U_2, V_2, W_2, PH_2, MU_2 for WRF run 
#------------------------------------------------------
if [ $CDATE != $SDATE ]; then
  NUM_VARS=`echo $VARS_B | grep -o ',' | wc -l`
  for INUM in $(seq 0 $NUM_VARS)
  do
    TMP_NUM=`expr $INUM + 1`
    TMP_VAR=`echo $VARS_B | cut -d"," -f$TMP_NUM`
    INCREMENT_VARS_B[$INUM]="$TMP_VAR"
  done
  
  NUM_VARS=${#INCREMENT_VARS_B[@]}
  NUM_VARS=`expr $NUM_VARS - 1`
  
  for INUM in $(seq 0 $NUM_VARS)
   do
    TMP_VAR=${INCREMENT_VARS_B[$INUM]}
    ncks -O  -v ${TMP_VAR}_2 wrfinput_d01 ${TMP_VAR}_2.nc 
    ncks -O  -v ${TMP_VAR}   wrfinput_d01 ${TMP_VAR}.nc
    ncrename -v ${TMP_VAR},${TMP_VAR}_2   ${TMP_VAR}.nc 
    ncks -A     ${TMP_VAR}.nc   ${TMP_VAR}_2.nc
    ncks -A     ${TMP_VAR}_2.nc wrfinput_d01 
    rm ${TMP_VAR}.nc ${TMP_VAR}_2.nc
  done

fi





touch ./prep2_forecast_ready

exit 

