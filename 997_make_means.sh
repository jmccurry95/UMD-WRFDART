#!/bin/sh 
#set -ex

NUM_ENS=40
EXP=EXP2
MESO_CONFIG=${1}

if [ "$EXP" == "EXP1"  ]; then 
  export SDATE=202004130500
  export ADATE=202004130600
  export EDATE=202004132300
elif [ "$EXP" == "EXP2"  ]; then 
  export SDATE=202008121200
  export ADATE=202008121200
  export EDATE=202008130200
elif [ "$EXP" == "EXP3"  ]; then 
  export SDATE=202009031000
  export ADATE=202009031100
  export EDATE=202009040100
elif [ "$EXP" == "EXP4"  ]; then 
  export SDATE=202107171100
  export ADATE=202107171200
  export EDATE=202107180100
elif [ "$EXP" == "EXP5"  ]; then
  export SDATE=202206081500
  export ADATE=202206081500
  export EDATE=202206090500
elif [ "$EXP" == "EXP6"  ]; then
  export SDATE=202207021400
  export ADATE=202207021500
  export EDATE=202207030500
elif [ "$EXP" == "EXP7"  ]; then
  export SDATE=202207161100
  export ADATE=202207161200
  export EDATE=202207170200
fi

#DA_NAME=EAKF
#DA_NAME=LPF
#DA_NAME=LPF-EnKF_HYB0.50

ASSIM_INT_MINS=15
BASE_DIR=/glade/scratch/jmccurry/WRF-DART/WORK/TEST_20230514/$EXP/CYCLE/config_$MESO_CONFIG/
DATA_DIR=/glade/scratch/jmccurry/WRF-DART/DATA/DATA/TEST_20230514/$EXP/CYCLE/config_$MESO_CONFIG/

CDATE=$SDATE
while [ $CDATE -le $EDATE ]; do

  YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
  DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
  MI=`echo ${CDATE}|cut -c 11-12`

  mkdir $DATA_DIR/$CDATE/filter_out
  cp $BASE_DIR/$CDATE/filter/obs_seq.final $DATA_DIR/$CDATE/filter_out/
  ncea -O $BASE_DIR/$CDATE/filter/filter_out/filter_restart_d01* $DATA_DIR/$CDATE/filter_out/output_mean.nc
  ncea -O $DATA_DIR/$CDATE/DA_prior/DA_prior* $DATA_DIR/$CDATE/filter_out/preassim_mean.nc
  
#   for IMEM in $(seq 1 $NUM_ENS)
#   do
#     FNAME=$BASE_DIR/$CDATE/assim_advance/mem$(printf %04i $IMEM)/prep1/wrfinput_d01
#     if [ -f $FNAME ]; then echo $FNAME; rm $FNAME; fi
#     FNAME=$BASE_DIR/$CDATE/assim_advance/mem$(printf %04i $IMEM)/prep2/wrfinput_d01
#     if [ -f  $FNAME ]; then echo $FNAME; rm $FNAME; fi
#     FNAME=$BASE_DIR/$CDATE/assim_advance/mem$(printf %04i $IMEM)/prep2/wrfbdy_d01
#     if [ -f  $FNAME ]; then echo $FNAME; rm $FNAME; fi

#     FNAME=$BASE_DIR/$CDATE/long_forecast/mem$(printf %04i $IMEM)/prep1/wrfinput_d01
#     if [ -f $FNAME ]; then echo $FNAME; rm $FNAME; fi
#   done
  

#   if [ $((10#$HR % 3)) -eq 0 ] && [ $MI == "00" ]; then
#     echo ${CDATE}
#   else
#     for IMEM in $(seq 21 $NUM_ENS)
#     do
#      FNAME=$DATA_DIR/$CDATE/WRF_OUT/wrfout_d01_$(printf %04i $IMEM)_*
#      if [ -f  $FNAME ]; then echo $FNAME; rm $FNAME; fi
#      FNAME=$DATA_DIR/$CDATE/WRF_OUT/wrfrst_d01_$(printf %04i $IMEM)_*
#      if [ -f  $FNAME ]; then echo $FNAME; rm $FNAME; fi
#     done
#   fi


  NDATE=`date -d "${YY}${MM}${DD} ${HR}:${MI} $ASSIM_INT_MINS minute" +%Y%m%d%H%M`
  CDATE=$NDATE
done

exit

