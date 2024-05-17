#!/bin/sh 

set -ex

IMEM=${1}

#===========================================
# Setting 0
# modules
#===========================================
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

# ===========================================
# 4
# DA Cycle 
# ===========================================


    YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
    DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
    MI=`echo ${CDATE}|cut -c 11-12`
    INIT_DATE=$(date +%s -d "${YY}-${MM}-${DD} ${HR}:${MI}:00")
    FORECAST_INIT=${YY}${MM}${DD}${HR}${MI}
    wrfrst_arr=($(ls $WRF_FCST_DIR/WRF_RUN/wrfrst* | sort -n))
    if [ ${#wrfrst_arr[@]} -eq 0 ]; then
      echo "nothing here to continue"
      exit
    else
      echo "restarting forecasts"
      wrfout_b=`basename ${wrfrst_arr[-1]}`

      YY=`echo $wrfout_b | cut -c 12-15`
      MM=`echo $wrfout_b | cut -c 17-18`
      DD=`echo $wrfout_b | cut -c 20-21`
      HR=`echo $wrfout_b | cut -c 23-24`
      MI=`echo $wrfout_b | cut -c 26-27`
    fi
    RESTART_DATE=$(date +%s -d "${YY}-${MM}-${DD} ${HR}:${MI}:00")
    COUNTER=$(( ($RESTART_DATE - $INIT_DATE) / 900 ))
    export CDATE=${YY}${MM}${DD}${HR}${MI}
    CUT_CDATE=`echo ${CDATE}|cut -c 1-10`
    echo "starting from counter: " $COUNTER

    #--- long forecast ---
    EXIT_FLAG=NO
    while [ $COUNTER -lt 12 ]; do # 3 hour fcst
        
      #--- exit ---
      if [ ! -f $ICBC_DATA_DIR/$CUT_CDATE/wrfbdy_d01 ]; then
        echo "EXIT:: " $CUT_CDATE
        exit
      else
        echo "FCST:: " $CUT_CDATE
      fi

      #--- Prep2 (bdy) ---
      TARGET_DIR1=$WRF_FCST_DIR/prep2
      if [ -d $TARGET_DIR1 ]; then rm -rf $TARGET_DIR1; fi
      mkdir -p $TARGET_DIR1
      cd $TARGET_DIR1
      ln -fs $ICBC_DATA_DIR/$CUT_CDATE/wrfbdy_d01 ./wrfbdy_d01
  
      #--- Prep3 (namelists) ---
      TARGET_DIR1=$WRF_FCST_DIR/prep3
      if [ -d $TARGET_DIR1 ]; then rm -rf $TARGET_DIR1; fi
      mkdir -p $TARGET_DIR1
      cd $TARGET_DIR1
      ln -fs $TOP_BASE_DIR/scripts/608_prep3_forecast.sh ./
      sh 608_prep3_forecast.sh 15
  
      #--- Run WRF ---
      TARGET_DIR1=$WRF_FCST_DIR/WRF_RUN

      cd $TARGET_DIR1
      touch ./run_forecast_done
      rm  ./run_forecast_done
      if [ -f wrfinput_d01 ];then
      unlink wrfinput_d01
      else
      echo 
      fi
      YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
      DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
      MI=`echo ${CDATE}|cut -c 11-12`
      #mkdir -p $CYCL_DATA_DIR/forecasts/WRFOUTS_FCST${FORECAST_INIT}/${YY}${MM}${DD}${HR}${MI}
      ln -fs wrfrst_d01_$YY-$MM-${DD}_${HR}:${MI}:00 ./wrfinput_d01
      # mv wrfout_d01_$YY-$MM-${DD}_${HR}:${MI}:00 $CYCL_DATA_DIR/forecasts/WRFOUTS_FCST${FORECAST_INIT}/${YY}${MM}${DD}${HR}${MI}/wrfout_d01_forecast_${YY}${MM}${DD}${HR}${MI}_${IMEM}
      qsub 610_forecast.sh

      #--- wait ---
      COUNTER_FCST=0
      while [ ! -f ${TARGET_DIR1}/run_forecast_done ]; do
        echo "waiting for forecast"
        sleep 5
        COUNTER_FCST=`expr $COUNTER_FCST + 1`
        if [ $COUNTER_FCST -eq 999 ]; then 
          EXIT_FLAG=YES 
          exit
        fi
      done
      if [ $EXIT_FLAG = YES ]; then
        exit
      fi

      # time
      YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
      DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
      MI=`echo ${CDATE}|cut -c 11-12`
      NDATE=`date -d "${YY}${MM}${DD} ${HR}:${MI} 15 minute" +%Y%m%d%H%M`
      export CDATE=$NDATE
      CUT_CDATE=`echo ${CDATE}|cut -c 1-10`
      COUNTER=`expr $COUNTER + 1`
    done
    $TOP_BASE_DIR/scripts/long_fcst/612_forecast_transfer.sh $WRF_FCST_DIR/WRF_RUN $CYCL_DATA_DIR/forecasts/WRFOUTS_FCST${FORECAST_INIT} ${IMEM}

exit

