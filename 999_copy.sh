#!/bin/sh 
set -ex

MEM=64
EXP=EXP2

KK_DIR=/glade/work/kkurosaw/WRF-DART/DATA/DATA/TEST_20230219/$EXP/
if [ ! -d $KK_DIR ]; then mkdir -p $KK_DIR ; fi

OBS_INT_MM=15 # minute
if [ "$EXP" == "EXP1"  ]; then
  SDATE=201905281200
  EDATE=201905290445
  DDATE=20190528
  SDATE2=2019052812
  EDATE2=2019052905
elif [ "$EXP" == "EXP2"  ]; then
  SDATE=201907032300
  EDATE=201907040230
  DDATE=20190703
  SDATE2=2019070323
  EDATE2=2019070403
elif [ "$EXP" == "EXP3"  ]; then
  SDATE=201907170800
  EDATE=201907180000
  DDATE=20190717
  SDATE2=2019052812
  EDATE2=2019052905
elif [ "$EXP" == "EXP4"  ]; then
  SDATE=202008121100
  EDATE=202008130200
  DDATE=20200812
  SDATE2=2020081210
  EDATE2=2020081303
fi

OBS_INT_HR=1 # hour

DA_PRI_FLAG=NO #YES #NO
DA_OBS_FLAG=YES #NO #YES
DA_ICBC_FLAG=YES

#-----------------------------------------------------------
# initial
#-----------------------------------------------------------
if [ $DA_PRI_FLAG = YES ]; then
  ORG_D_HEAD=/glade/scratch/jmccurry/WOF/ensemble_init/$DDATE/rundir_3km/advance_temp
 # ORG_D_HEAD=/glade/scratch/jmccurry/WOF/realtime/20190528.64_mem_3km_pf_15MIN_R2/advance_temp
 # ORG_D_HEAD=/glade/scratch/jmccurry/WOF/realtime/20190703.64_mem_3km_enkf_15MIN_CSEC_THOMPSON/advance_temp
  TRG_D_HEAD=$KK_DIR/EAKF/CYCLE/$SDATE/DA_prior/
  if [ ! -d $TRG_D_HEAD ]; then mkdir -p $TRG_D_HEAD ; fi
  
  for imem in $(seq 1 $MEM)
  do
    
    ORG_F_NAME=${ORG_D_HEAD}${imem}/wrfinput_d01
    TRG_F_NAME=${TRG_D_HEAD}/DA_prior_$(printf %04i $imem)
    cp -p $ORG_F_NAME $TRG_F_NAME
    
  done
  exit
fi

#-----------------------------------------------------------
# OBS
#-----------------------------------------------------------
if [ $DA_OBS_FLAG = YES ]; then
  ORG_D_HEAD=/glade/scratch/jmccurry/WOF/realtime/OBSGEN/OBS_SEQ_CONV/
  
  CDATE=$SDATE
  while [[ $CDATE -le $EDATE ]]; do

    TRG_D_HEAD=$KK_DIR/OBS/$CDATE/
    if [ ! -d $TRG_D_HEAD ]; then mkdir -p $TRG_D_HEAD ; fi

    ORG_F_NAME=${ORG_D_HEAD}/obs_seq.combined_full_cropped.${CDATE}
    if [ -f $ORG_F_NAME ]; then 
      TRG_F_NAME=${TRG_D_HEAD}/obs_seq.out
      cp -p $ORG_F_NAME $TRG_F_NAME
    fi

    YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
    DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
    MI=`echo ${CDATE}|cut -c 11-12`
    NDATE=`date -d "${YY}${MM}${DD} ${HR}:${MI} $OBS_INT_MM minute" +%Y%m%d%H%M`
    CDATE=$NDATE
  done
  exit
fi

#-----------------------------------------------------------
# ICBC
#-----------------------------------------------------------
if [ $DA_ICBC_FLAG = YES ]; then
  ORG_D_HEAD=/glade/scratch/jmccurry/WOF/ensemble_init/$DDATE/output/
  ADVANCE_TIME=/glade/u/home/jmccurry/DART/models/wrf/work/advance_time

  CDATE=$SDATE2
  while [[ $CDATE -le $EDATE2 ]]; do

    TRG_D_HEAD=$KK_DIR/ICBC/$CDATE/
    if [ ! -d $TRG_D_HEAD ]; then mkdir -p $TRG_D_HEAD ; fi

    YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
    DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
    FDATE=`date -d "${YY}${MM}${DD} ${HR} $OBS_INT_HR hour" +%Y%m%d%H`
    G_CDATE=`echo $CDATE 0 -g | $ADVANCE_TIME`
    G_FDATE=`echo $FDATE 0 -g | $ADVANCE_TIME`
    G_CDATES=( $G_CDATE )
    G_FDATES=( $G_FDATE )

    ORG_F_NAME1=${ORG_D_HEAD}/${CDATE}/wrfinput_d01_${G_CDATES[0]}_${G_CDATES[1]}_mean
#    ORG_F_NAME2=${ORG_D_HEAD}/${CDATE}/wrfinput_d01_${G_FDATES[0]}_${G_FDATES[1]}_mean
    ORG_F_NAME3=${ORG_D_HEAD}/${CDATE}/wrfbdy_d01_${G_FDATES[0]}_${G_FDATES[1]}_mean

    TRG_F_NAME1=${TRG_D_HEAD}/wrfinput_d01 # for DA
#    TRG_F_NAME2=${TRG_D_HEAD}/wrfinput_d01 # for fg
    TRG_F_NAME3=${TRG_D_HEAD}/wrfbdy_d01

    cp -p $ORG_F_NAME1 $TRG_F_NAME1
#    cp -p $ORG_F_NAME2 $TRG_F_NAME2
    cp -p $ORG_F_NAME3 $TRG_F_NAME3

    YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
    DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
    NDATE=`date -d "${YY}${MM}${DD} ${HR} $OBS_INT_HR hour" +%Y%m%d%H`
    CDATE=$NDATE
  done

fi
exit

