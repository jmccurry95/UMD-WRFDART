#!/bin/sh 
#PBS -A UMCP0011
#PBS -N forecast
#PBS -q economy 
#PBS -l walltime=04:00:00
#PBS -j oe
#PBS -k eod
#PBS -l select=1:ncpus=1
#PBS -V

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

#===========================================
# 4
# DA Cycle 
#===========================================


    YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
    DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
    MI=`echo ${CDATE}|cut -c 11-12`
    PDATE=`date -d "${YY}${MM}${DD} ${HR}:${MI} $ASSIM_INT_MINS minute ago" +%Y%m%d%H%M` # prior

    #------------------------
    # WRF Forecast
    #------------------------
    #--- Prep1 (ncks: DA_post -> WRF input) ---
    TARGET_DIR1=$WRF_FCST_DIR/prep1
    if [ -d $TARGET_DIR1 ]; then rm -rf $TARGET_DIR1; fi
    mkdir -p $TARGET_DIR1
    cd $TARGET_DIR1
    ln -fs $TEMP_FILE1                                                  ./input.nml 
   # ln -fs $CYCL_DATA_DIR/$CDATE/DA_prior/DA_prior_$(printf %04i $IMEM) ./filter_restart_d01  # < -- !!
    ln -fs $CYCL_DATA_DIR/$CDATE/DA_post/DA_post_$(printf %04i $IMEM) ./filter_restart_d01  # < -- !!
    ln -fs $TOP_BASE_DIR/scripts/606_prep1_forecast.sh                  ./606_prep1_forecast.sh
    cp -p $CYCL_DATA_DIR/$PDATE/WRF_OUT/wrfrst_d01_$(printf %04i $IMEM)_$YY-$MM-${DD}_${HR}:${MI}:00 ./wrfinput_d01
    qsub 606_prep1_forecast.sh

    # Wait 
    TARGET_DIR1=$WRF_FCST_DIR/prep1
    while [ ! -f ${TARGET_DIR1}/prep1_forecast_ready ]; do
      echo "waiting for prep1"
      sleep 5
    done

    #--- long forecast ---
    COUNTER=0
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
      if [ $COUNTER -eq 0 ]; then
        if [ -d $TARGET_DIR1 ]; then rm -rf $TARGET_DIR1; fi
        mkdir -p $TARGET_DIR1
        cd $TARGET_DIR1
        ln -fs $WRF_DIR/run/*                                             ./
        ln -fs $DA_WRFVAR_E                                               ./da_wrfvar.exe
        ln -fs $BE_DAT_CV33                                               ./be.dat
        ln -fs $WRF_FCST_DIR/prep1/wrfinput_d01  ./wrfinput_d01
        ln -fs $WRF_FCST_DIR/prep2/wrfbdy_d01    ./wrfbdy_d01
        ln -fs $WRF_FCST_DIR/prep3/namelist.input ./namelist.input
        sed -e "5 s/05/05/g" $TOP_BASE_DIR/scripts/610_forecast.sh > ./610_forecast.sh
        FORECAST_INIT=${YY}${MM}${DD}${HR}${MI}
        mkdir -p $CYCL_DATA_DIR/forecasts/WRFOUTS_FCST${FORECAST_INIT}/${YY}${MM}${DD}${HR}${MI}
        cp wrfinput_d01 wrfout_d01_$YY-$MM-${DD}_${HR}:${MI}:00_precip

        qsub 610_forecast.sh
      else
        cd $TARGET_DIR1
        rm ./run_forecast_done
        unlink wrfinput_d01
        YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
        DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
        MI=`echo ${CDATE}|cut -c 11-12`
        [ -e wrfout_d01_$YY-$MM-${DD}_${HR}:${MI}:00 ] && mv wrfout_d01_$YY-$MM-${DD}_${HR}:${MI}:00 wrfout_d01_$YY-$MM-${DD}_${HR}:${MI}:00_precip

        #mkdir -p $CYCL_DATA_DIR/forecasts/WRFOUTS_FCST${FORECAST_INIT}/${YY}${MM}${DD}${HR}${MI}
        ln -fs wrfrst_d01_$YY-$MM-${DD}_${HR}:${MI}:00 ./wrfinput_d01
        qsub 610_forecast.sh
      fi

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
 
      [ -e wrfout_d01_$YY-$MM-${DD}_${HR}:${MI}:00 ] && rm wrfout_d01_$YY-$MM-${DD}_${HR}:${MI}:00
      [ -e wrfout_d01_$YY-$MM-${DD}_${HR}:${MI}:00_precip ] && mv wrfout_d01_$YY-$MM-${DD}_${HR}:${MI}:00_precip wrfout_d01_$YY-$MM-${DD}_${HR}:${MI}:00

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

