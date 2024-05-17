#!/bin/sh 
# set -ex


CDATE_DEL=${1}
EDATE_DEL=${2}

# DA_NAME=EAKF
# DA_NAME=LPF
# DA_NAME=LPF-EnKF_HYB0.50

ASSIM_INT_MINS=15


while [ $CDATE_DEL -le $EDATE_DEL ]; do

  YY=`echo ${CDATE_DEL}|cut -c 1-4` ; MM=`echo ${CDATE_DEL}|cut -c 5-6`
  DD=`echo ${CDATE_DEL}|cut -c 7-8` ; HR=`echo ${CDATE_DEL}|cut -c 9-10`
  MI=`echo ${CDATE_DEL}|cut -c 11-12`

  #mkdir $DATA_DIR/$CDATE_DEL/filter_out
  #cp $WORK_DIR/$CDATE_DEL/filter/obs_seq.final $DATA_DIR/$CDATE_DEL/filter_out/
  #ncea -O $WORK_DIR/$CDATE_DEL/filter/filter_out/filter_restart_d01* $DATA_DIR/$CDATE_DEL/filter_out/output_mean.nc
  #ncea -O $DATA_DIR/$CDATE_DEL/DA_prior/DA_prior* $DATA_DIR/$CDATE_DEL/filter_out/preassim_mean.nc

   for IMEM in $(seq 1 $NUM_ENS)
   do
     FNAME=$WORK_DIR/$CDATE_DEL/assim_advance/mem$(printf %04i $IMEM)/prep1/wrfinput_d01
     if [ -f $FNAME ]; then echo $FNAME; rm $FNAME; fi
     FNAME=$WORK_DIR/$CDATE_DEL/assim_advance/mem$(printf %04i $IMEM)/prep2/wrfinput_d01
     if [ -f  $FNAME ]; then echo $FNAME; rm $FNAME; fi
     FNAME=$WORK_DIR/$CDATE_DEL/assim_advance/mem$(printf %04i $IMEM)/prep2/wrfbdy_d01
     if [ -f  $FNAME ]; then echo $FNAME; rm $FNAME; fi

     FNAME=$WORK_DIR/$CDATE_DEL/long_forecast/mem$(printf %04i $IMEM)/prep1/wrfinput_d01
     if [ -f $FNAME ]; then echo $FNAME; rm $FNAME; fi
     rm $WORK_DIR/$CDATE_DEL/assim_advance/mem$(printf %04i $IMEM)/WRF_RUN/wrfout_d01_*
     rm $WORK_DIR/$CDATE_DEL/assim_advance/mem$(printf %04i $IMEM)/WRF_RUN/wrfrst_d01_*
   done
   if [ "$CDATE_DEL" -eq "$ADATE" ] || [ ! -f "${DATA_DIR}/${CDATE_DEL}/filter_out/output_mean.nc" ]; then
     echo ${CDATE_DEL}
   else
     for IMEM in $(seq 21 $NUM_ENS)
     do
      FNAME=$DATA_DIR/$CDATE_DEL/WRF_OUT/wrfout_d01_$(printf %04i $IMEM)_*
      if [ -f  $FNAME ]; then echo $FNAME; rm $FNAME; fi
      FNAME=$DATA_DIR/$CDATE_DEL/WRF_OUT/wrfrst_d01_$(printf %04i $IMEM)_*
      if [ -f  $FNAME ]; then echo $FNAME; rm $FNAME; fi
      FNAME=$WORK_DIR/$CDATE_DEL/filter/filter_out/filter_restart_d01.$(printf %04i $IMEM)
      if [ -f  $FNAME ]; then echo $FNAME; rm $FNAME; fi
     done
   fi


   NDATE=`date -d "${YY}${MM}${DD} ${HR}:${MI} $ASSIM_INT_MINS minute" +%Y%m%d%H%M`
   CDATE_DEL=$NDATE
done

exit

