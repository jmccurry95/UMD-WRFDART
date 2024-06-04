#!/bin/sh 
#-------------------------------------------
# Main driver for WRF-DART system used in filtering experiments 
# Contributions from Joshua McCurry and Kenta Kurasawa
# Uses namelist file - 000S_driver_settings.sh
#-------------------------------------------

set -ex

#===========================================
# Setting 0
# modules
#===========================================
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
module load ncl
module list
#export LD_LIBRARY_PATH=/glade/u/apps/ch/opt/netcdf/4.8.1/intel/2022.1/lib:$LD_LIBRARY_PATH


#===========================================
#load functions for driver script
#load settings from settings file 
#save settings in logfile
#===========================================
source ./000S_driver_settings.sh

cp ./000S_driver_settings.sh ${DATA_DIR}/experiment_settings
creation_time=$(date +"%T")
echo "last run started at : $creation_time" >> ${DATA_DIR}/experiment_settings

#===========================================
#contingent settings (based on those specified in settings file)
#===========================================

#date parsing variables
CUT_SDATE=`echo ${SDATE}|cut -c 1-8`


#obs parsing variables
if [ $EXP_MODE = real ];then
 export OBSTYPE='combined_full_cropped'
 export OBSR_DATA_DIR=${TOP_DIR}/OBS_REAL
elif [ $EXP_MODE = osse ];then
 export OBSR_DATA_DIR=${TOP_DIR}/OBS_3km 
 if [ $MESO_CONFIG -eq 0 ]; then #default network
  export OBSTYPE='cropped_osse' #obs naming convention default
 else
  export OBSTYPE="cropped_osse_config_$MESO_CONFIG" #obs naming convention CONFIGS
 fi

fi

#filter setup variables
if   [ $DA_FILTER -eq 1  ]; then # EAKF
  FILTER_KIND=1;
  DA_KIND=EAKF
  FILTER_WALLTIME=00:15:00
  PF_ENKF_HYBRID=".false."
  MIN_RES=1.0
elif [ $DA_FILTER -ge 11 ]; then # PF
  FILTER_KIND=9;
  FILTER_WALLTIME=00:30:00
  PF_MAXITER=3
  case $DA_FILTER in
    "11") # LPF
    PF_ENKF_HYBRID=".false."
    MIN_RES=0.0
    DA_KIND=LPF
    ;;
    "12") # LPF-EnKF(50-50)
    PF_ENKF_HYBRID=".true."
    MIN_RES=0.5
    DA_KIND=LPF-EnKF_HYB`printf "%3.2f" $MIN_RES`
    ;;
    "13") # LPF-ADAPTIVE-HYBRID
    PF_ENKF_HYBRID=".true."
    MIN_RES=0.0
    DA_KIND=LPF-EnKF_ADPT_HYB_Feb2023 # <-- 
    ADAPT_HYBRID=".true."
    PF_MAXITER=9
    FILTER_WALLTIME=00:59:00 # 60 or 40
    ;;
  esac
fi

#===========================================
# Setting 2
# Paths to data and WRF & DART components 
#===========================================

#export TOP_WORK_DIR=$TOP_DIR/WORK/
#export TOP_DATA_DIR=$TOP_DIR/DATA/
#export TOP_BASE_DIR=$TOP_DIR/BASE/  # templates dir

#export WORK_DIR=$TOP_WORK_DIR/$EXP_NAME_BASE/
#export DATA_DIR=$TOP_DATA_DIR/DATA/$EXP_NAME_BASE/
#export DART_DIR=$TOP_DATA_DIR/DART/

#export WRF_DIR=$TOP_DATA_DIR/WRF/
#export WPS_DIR=$TOP_DATA_DIR/WPS/
#export WRFDA_DIR=$TOP_DATA_DIR/WRFDA/

#export ICBC_DATA_DIR=$TOP_DIR/ICBC/${CUT_SDATE}/output${BIAS} 
#export CYCL_DATA_DIR=$DATA_DIR #made
#export CYCL_WORK_DIR=$WORK_DIR #made

#--- DA ---
#DART_FILTER=$MDEL_DIR/filter
DART_FILTER=$MDEL_DIR/filter # <---- !! 
#DART_FILTER=/glade/u/home/jmccurry/WORK/WRF_DART_Feb2023/DART_kk/models/wrf/work/filter_test # <---- !! 
OBS_DIAGNOS=$MDEL_DIR/obs_diag
OBS_SEQ_NCF=$MDEL_DIR/obs_seq_to_netcdf

#--- Add noise ---
GRID_REF_OB=$MDEL_DIR/grid_refl_obs
ADD_PER_WHR=$MDEL_DIR/add_pert_where_high_refl

#--- WRF ---
PERT_WRF_BC=$MDEL_DIR/pert_wrf_bc
DA_WRFVAR_E=$WRFDA_DIR/var/build/da_wrfvar.exe
BE_DAT_CV33=$WRFDA_DIR/var/run/be.dat.cv3

#-- LBC perts --
if [ $LBC_PERT_AMPLITUDE = xfifth ];then
ADD_BNK_PER=$TOP_BASE_DIR/template/pert_settings/add_bank_perts.xfifth.ncl #MODIFY FOR EXPS 31, 41, etc. that use different pert amplitudes
elif [ $LBC_PERT_AMPLITUDE = default ];then
ADD_BNK_PER=$TOP_BASE_DIR/template/pert_settings/add_bank_perts.x5.ncl #MODIFY FOR EXPS 31, 41, etc. that use different pert amplitudes
fi


#--- advance time ---
export ADVANCE_TIME=${MDEL_DIR}/advance_time

#===========================================
# Setting 3
# Parameters & Flags 
#===========================================
# 606.sh
if [ $PHYS_SETTINGS = THOMP ];then
export VARS_A="U,V,W,PH,T,MU,QVAPOR,QCLOUD,QRAIN,QICE,QSNOW,QGRAUP,QNICE,QNRAIN,U10,V10,T2,TH2,Q2,PSFC,REFL_10CM"
elif [ $PHYS_SETTINGS = NSSL ];then
export VARS_A="U,V,W,PH,T,MU,QVAPOR,QCLOUD,QRAIN,QICE,QSNOW,QGRAUP,QHAIL,QNICE,QNRAIN,QNDROP,QNSNOW,QNGRAUPEL,QNHAIL,QVGRAUPEL,QVHAIL,U10,V10,T2,TH2,Q2,PSFC,REFL_10CM"
fi

export VARS_B="U,V,W,PH,MU"


# set flags
FILTER_FLAG=YES
OBS_DIAG_FLAG=NO
FORECAST_FLAG=YES
PREP1_FORECAST_FLAG=YES  # DA_post -> wrfinput
PREP2_FORECAST_FLAG=YES # Add noise 
PREP3_FORECAST_FLAG=YES # Create namelists
WRF_RUN_FLAG=YES

#===========================================
# 4
# DA Cycle 
#===========================================

  # Main loop
  #export CDATE=$SDATE
  #export CDATE=202008122045
  #export =201907032115 #201907031930 #201907171430 # 201907032015 #20190717080900 #201907171645
  while [[ $CDATE -le $EDATE ]]; do
  
    echo "==========================================="
    echo "Starting $CDATE (000_driver.sh)"
    echo `pwd`
    echo "==========================================="
  
    #------------------------
    # Set & Check Files
    #------------------------
    export C_CYCL_WORK_DIR=$CYCL_WORK_DIR/$CDATE
    export C_CYCL_DATA_DIR=$CYCL_DATA_DIR/$CDATE
    if [ ! -d $C_CYCL_WORK_DIR ]; then mkdir -p $C_CYCL_WORK_DIR ; fi
    if [ ! -d $C_CYCL_DATA_DIR ]; then mkdir -p $C_CYCL_DATA_DIR ; fi
    if [ -f $C_CYCL_WORK_DIR/filter_skip_flag ]; then rm $C_CYCL_WORK_DIR/filter_skip_flag; fi
    cd $C_CYCL_WORK_DIR
    echo `date` > ./cycle_started_${CDATE}
    cp $TEMP_FILE1 ./input.nml 

    YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
    DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
    MI=`echo ${CDATE}|cut -c 11-12`
    export FDATE=`date -d "${YY}${MM}${DD} ${HR}:${MI} $ASSIM_INT_MINS minute" +%Y%m%d%H%M`
    export CUT_CDATE=`echo ${CDATE}|cut -c 1-10`
    CUT_CDATE2=`echo ${CDATE}|cut -c 1-8`
    export CUT_FDATE=`echo ${FDATE}|cut -c 1-10`
    FDATE2=`date -d "${YY}${MM}${DD} ${HR}:${MI} 60 minute" +%Y%m%d%H%M` # prep2
    CUT_FDATE2=`echo ${FDATE2}|cut -c 1-10`                              # prep2
    PDATE=`date -d "${YY}${MM}${DD} ${HR}:${MI} $ASSIM_INT_MINS minute ago" +%Y%m%d%H%M` # prior

    # Check #NOTE .. NEED TO CHANGE FILE NAMES IN ENSEMBLE INIT DIR OUTPUT + RUNDIR
    F_IC_FNAME=$ICBC_DATA_DIR/$CUT_FDATE2/wrfinput_d01
    C_BC_FNAME=$ICBC_DATA_DIR/$CUT_CDATE/wrfbdy_d01
    C_OB_FNAME=$OBSR_DATA_DIR/$CUT_CDATE2/obs_seq.${OBSTYPE}.$CDATE
    if [ ! -f $F_IC_FNAME ]; then echo "$F_IC_FNAME is missing! Stopping the system"; exit; fi
    if [ ! -f $C_BC_FNAME ]; then echo "$C_BC_FNAME is missing! Stopping the system"; exit; fi
    if [ ! -f $C_OB_FNAME ]; then 
      echo "$C_OB_FNAME is missing! Skipping the DA process !!"
      touch $C_CYCL_WORK_DIR/filter_skip_flag
    fi
    for IMEM in $(seq 1 $NUM_ENS)
    do
      INIT_ENS=$C_CYCL_DATA_DIR/DA_prior/DA_prior_$(printf %04i $IMEM)
      if [ ! -f $INIT_ENS ]; then echo "$INIT_ENS is missing! Stopping the system"; exit; fi
    done

    #------------------------
    # Data Assimilation
    #------------------------
    if [ $FILTER_FLAG = YES ]; then
      if [ $CDATE -lt $ADATE ]; then 
      touch $C_CYCL_WORK_DIR/filter_skip_flag
      export ADD_NOISE_FLAG=NO
      else
      export ADD_NOISE_FLAG=$ADD_NOISE_FLAG_MAIN 
      fi

      # prep for 604_assimilate
      TARGET_DIR1=$C_CYCL_WORK_DIR/filter
      if [ -d $TARGET_DIR1 ]; then rm -rf $TARGET_DIR1; fi
      mkdir -p $TARGET_DIR1
      cd $TARGET_DIR1
      TARGET_DIR2=$TARGET_DIR1/filter_out/
      mkdir -p $TARGET_DIR2
      ln -fs $DART_FILTER                             ./filter
      ln -fs $C_OB_FNAME                              ./obs_seq.out
      ln -fs $C_CYCL_DATA_DIR/DA_prior/DA_prior_0001  ./wrfinput_d01
      ln -fs $OERROR_STORE_DIR/radar_all_reflectivity.dat ./radar_all_reflectivity.dat
      ln -fs $OERROR_STORE_DIR/radar_reflectivity.dat ./radar_reflectivity.dat
      ln -fs $OERROR_STORE_DIR/gaussian_test.dat ./gaussian_test.dat


      sed -e "s/filter_kind      .*/filter_kind         = ${FILTER_KIND},/g" \
          -e "s/pf_enkf_hybrid   .*/pf_enkf_hybrid      = ${PF_ENKF_HYBRID},/g" \
          -e "s/min_residual     .*/min_residual        = ${MIN_RES},/g" \
	  -e "s/ens_size         .*/ens_size            = ${NUM_ENS},/g" \
          $TEMP_FILE1 > input.nml.edit
      mv input.nml.edit input.nml
      if [ $DA_FILTER -ge 11 ]; then # PF
        sed -e "s/pf_maxiter  .*/pf_maxiter = ${PF_MAXITER},/g" input.nml > input.nml.edit
        mv input.nml.edit input.nml
        if [ $DA_FILTER -eq 13 ]; then
          sed -e "s/adaptive_minres_flag  .*/adaptive_minres_flag = ${ADAPT_HYBRID},/g" input.nml > input.nml.edit
          mv input.nml.edit input.nml
#          mkdir -p $TARGET_DIR1/ipf_out
        fi
      fi

      if [ $NONPARAMETRIC_OERROR = 'YES' ]; then
         sed -e "s/using_oerror_lookup .*/using_oerror_lookup = .true.,/g" input.nml > input.nml.edit
         mv input.nml.edit input.nml
      elif [ $NONPARAMETRIC_OERROR = 'NO' ]; then
         sed -e "s/using_oerror_lookup .*/using_oerror_lookup = .false.,/g" input.nml > input.nml.edit
         mv input.nml.edit input.nml

      fi

      sed -e "s/WALLTIME000/${FILTER_WALLTIME}/g" \
          -e "s/NCPUSPERNODE000/${FILTER_CORES_PER_NODE}/g" \
          -e "s/NNODES000/${FILTER_NODES}/g" \
	  -e "s/NCPUSTOTAL000/$(( ${FILTER_NODES}*${FILTER_CORES_PER_NODE} ))/g" \
          $TOP_BASE_DIR/scripts/604_assimilate.sh > 604_assimilate.sh

      IPUT_FILE_NAME="./input_list_d01.txt"
      OPUT_FILE_NAME="./output_list_d01.txt"
      for IMEM in $(seq 1 $NUM_ENS)
      do
        I_DIR=$C_CYCL_DATA_DIR/DA_prior/
        O_DIR=$TARGET_DIR2
        I_FILE_NAME=$I_DIR/DA_prior_$(printf %04i $IMEM)
        O_FILE_NAME=$O_DIR/filter_restart_d01.$(printf %04i $IMEM)
        echo $I_FILE_NAME  >> $IPUT_FILE_NAME
        echo $O_FILE_NAME  >> $OPUT_FILE_NAME
        if [ -f $C_CYCL_WORK_DIR/filter_skip_flag ]; then # skip DA
          ln -fs $I_FILE_NAME $O_FILE_NAME
        fi
      done
    
      # qsub 604_assimilate
      if [ ! -f $C_CYCL_WORK_DIR/filter_skip_flag ]; then
        qsub 604_assimilate.sh 
        # Wait
        while [ ! -f ${TARGET_DIR1}/filter_done ]; do
          echo "waiting for filter"
          sleep 60
        done
        echo "filter is done, cleaning up"  
        mkdir -p $DATA_DIR/$CDATE/filter_out
        cp $C_CYCL_WORK_DIR/filter/obs_seq.final $DATA_DIR/$CDATE/filter_out/
        ncea -O $C_CYCL_WORK_DIR/filter/filter_out/filter_restart_d01* $DATA_DIR/$CDATE/filter_out/output_mean.nc
        ncea -O $C_CYCL_DATA_DIR/DA_prior/DA_prior* $DATA_DIR/$CDATE/filter_out/preassim_mean.nc
        
      fi

      # Link
      for IMEM in $(seq 1 $NUM_ENS)
      do
        TARGET_DIR1=$C_CYCL_WORK_DIR/filter/filter_out/
        TARGET_DIR2=$C_CYCL_DATA_DIR/DA_post/
        if [ ! -d $TARGET_DIR2  ]; then mkdir -p $TARGET_DIR2 ; fi
        TARGET_FILE1=$TARGET_DIR1/filter_restart_d01.$(printf %04i $IMEM)
        TARGET_FILE2=$TARGET_DIR2/DA_post_$(printf %04i $IMEM)
        ln -fs $TARGET_FILE1 $TARGET_FILE2  
      done

      # Adaptive LPF-EAKF Hybrid
      if [ ! -f $C_CYCL_WORK_DIR/filter_skip_flag ]; then
        if [ $DA_FILTER -eq 13 ]; then
          cd $C_CYCL_WORK_DIR/filter
          mv ./output_mean.nc   ./pfiter.nc
          mv ./output_sd.nc     ./minres.nc
          ln -fs $TOP_BASE_DIR/scripts/101_cal_mean.sh ./101_cal_mean.sh
          qsub -v cwd=$PWD 101_cal_mean.sh 
        fi
      fi

    fi

    #------------------------
    # OBS diagnostics
    #------------------------
    if [ $OBS_DIAG_FLAG = YES ]; then
      if [ ! -f $C_CYCL_WORK_DIR/filter_skip_flag ]; then
        TARGET_DIR1=$C_CYCL_WORK_DIR/filter/obs_diag
        if [ -d $TARGET_DIR1 ]; then rm -rf $TARGET_DIR1; fi
        mkdir -p $TARGET_DIR1
        cd $TARGET_DIR1
        ln -fs $OBS_DIAGNOS                              ./obs_diag
        ln -fs $OBS_SEQ_NCF                              ./obs_seq_to_netcdf
        ln -fs $C_CYCL_WORK_DIR/filter/obs_seq.final     ./obs_seq.final
        ln -fs $C_CYCL_WORK_DIR/filter/input_mean.nc     ./input_mean.nc
        ln -fs $C_CYCL_WORK_DIR/filter/output_mean.nc    ./output_mean.nc
        ln -fs $TOP_BASE_DIR/scripts/obs_diag_test.m     ./obs_diag_test.m
        ln -fs $TOP_BASE_DIR/scripts/605_obs_diag.sh     ./605_obs_diag.sh
        qsub -v cwd=$PWD 605_obs_diag.sh 
      fi
    fi
     
    #------------------------
    # WRF Forecast
    #------------------------
    if [ $FORECAST_FLAG = YES ]; then

      echo "ready to integrate ensemble members"
      WRF_FCST_DIR=$C_CYCL_WORK_DIR/assim_advance/

      #--- Prep1 (ncks: DA_post -> WRF input) ---
      if [ $PREP1_FORECAST_FLAG = YES ]; then
        for IMEM in $(seq 1 $NUM_ENS)
        do
          TARGET_DIR1=$WRF_FCST_DIR/mem$(printf %04i $IMEM)/prep1
          if [ -d $TARGET_DIR1 ]; then rm -rf $TARGET_DIR1; fi
          mkdir -p $TARGET_DIR1
          cd $TARGET_DIR1
          ln -fs $TEMP_FILE1                                              ./input.nml 
          ln -fs $C_CYCL_DATA_DIR/DA_post/DA_post_$(printf %04i $IMEM)    ./filter_restart_d01 
          ln -fs $TOP_BASE_DIR/scripts/606_prep1_forecast.sh              ./606_prep1_forecast.sh
          if [ $CDATE -eq $SDATE ]; then
            cp -p $C_CYCL_DATA_DIR/DA_prior/DA_prior_$(printf %04i $IMEM) ./wrfinput_d01
          else
            cp -p $CYCL_DATA_DIR/$PDATE/WRF_OUT/wrfrst_d01_$(printf %04i $IMEM)_$YY-$MM-${DD}_${HR}:${MI}:00 ./wrfinput_d01
          fi
          qsub -v cwd=$PWD 606_prep1_forecast.sh
        done
  
        # Wait 
        for IMEM in $(seq 1 $NUM_ENS)
        do
          TARGET_DIR1=$WRF_FCST_DIR/mem$(printf %04i $IMEM)/prep1
          while [ ! -f ${TARGET_DIR1}/prep1_forecast_ready ]; do
            echo "waiting for prep1 member $IMEM"
            sleep 5
          done
        done
      fi

      #--- Prep2 ( Add noise ) ---
      if [ $PREP2_FORECAST_FLAG = YES ]; then
        for IMEM in $(seq 1 $NUM_ENS)
        do
          TARGET_DIR1=$WRF_FCST_DIR/mem$(printf %04i $IMEM)/prep2
          if [ -d $TARGET_DIR1 ]; then rm -rf $TARGET_DIR1; fi
          mkdir -p $TARGET_DIR1
          cd $TARGET_DIR1

          # radar additive noise option  
          echo $IMEM > text_ens_mem
          ln -fs $TEMP_FILE1                                              ./input.nml 
          ln -fs $GRID_REF_OB                                             ./grid_refl_obs
          ln -fs $ADD_PER_WHR                                             ./add_pert_where_high_refl
          cp -p  $WRF_FCST_DIR/mem$(printf %04i $IMEM)/prep1/wrfinput_d01 ./wrfinput_d01
          if [ ! -f $C_CYCL_WORK_DIR/filter_skip_flag ]; then
            ln -fs $C_CYCL_WORK_DIR/filter/obs_seq.final                  ./obs_seq.final
          fi

          # add noise to wrfbdy_d01
          ln -fs $ADD_BNK_PER                                ./add_bank_perts.ncl
          ln -fs $PERT_WRF_BC                                ./pert_wrf_bc
          cp -p $F_IC_FNAME                                  ./wrfvar_output
          cp -p $C_BC_FNAME                                  ./wrfbdy_d01 
          ln -fs $TOP_BASE_DIR/scripts/607_prep2_forecast.sh ./607_prep2_forecast.sh
          qsub -v cwd=$PWD 607_prep2_forecast.sh 
        done

        # Wait 
        for IMEM in $(seq 1 $NUM_ENS)
        do
          TARGET_DIR1=$WRF_FCST_DIR/mem$(printf %04i $IMEM)/prep2
          while [ ! -f ${TARGET_DIR1}/prep2_forecast_ready ]; do
            echo "waiting for prep2 member $IMEM"
            sleep 5
          done
        done

        # Link
        for IMEM in $(seq 1 $NUM_ENS)
        do
          TARGET_DIR1=$WRF_FCST_DIR/mem$(printf %04i $IMEM)/prep2
          TARGET_DIR2=$C_CYCL_DATA_DIR/WRF_IN/
          if [ ! -d $TARGET_DIR2  ]; then mkdir -p $TARGET_DIR2 ; fi
          TARGET_FILE1=$TARGET_DIR1/wrfinput_d01
          TARGET_FILE2=$TARGET_DIR2/wrfinput_d01.$(printf %04i $IMEM)
          ln -fs $TARGET_FILE1 $TARGET_FILE2  
          TARGET_FILE1=$TARGET_DIR1/wrfbdy_d01
          TARGET_FILE2=$TARGET_DIR2/wrfbdy_d01.$(printf %04i $IMEM)
          ln -fs $TARGET_FILE1 $TARGET_FILE2  
        done
      fi

      #--- Prep3 (namelists) ---
      if [ $PREP3_FORECAST_FLAG = YES ]; then
        for IMEM in $(seq 1 $NUM_ENS)
        do
          TARGET_DIR1=$WRF_FCST_DIR/mem$(printf %04i $IMEM)/prep3
          if [ -d $TARGET_DIR1 ]; then rm -rf $TARGET_DIR1; fi
          mkdir -p $TARGET_DIR1
          cd $TARGET_DIR1
          ln -fs $TOP_BASE_DIR/scripts/608_prep3_forecast.sh ./
          sh 608_prep3_forecast.sh $ASSIM_INT_MINS
        done
      fi

      #--- Run WRF ---
      if [ $WRF_RUN_FLAG = YES ]; then
        for IMEM in $(seq 1 $NUM_ENS)
        do
          TARGET_DIR1=$WRF_FCST_DIR/mem$(printf %04i $IMEM)/WRF_RUN
          if [ -d $TARGET_DIR1 ]; then rm -rf $TARGET_DIR1; fi
          mkdir -p $TARGET_DIR1
          cd $TARGET_DIR1
          ln -fs $WRF_DIR/run/*                                             ./
          ln -fs $DA_WRFVAR_E                                               ./da_wrfvar.exe
          ln -fs $BE_DAT_CV33                                               ./be.dat
          ln -fs $C_CYCL_DATA_DIR/WRF_IN/wrfinput_d01.$(printf %04i $IMEM)  ./wrfinput_d01
          ln -fs $C_CYCL_DATA_DIR/WRF_IN/wrfbdy_d01.$(printf %04i $IMEM)    ./wrfbdy_d01
          ln -fs $WRF_FCST_DIR/mem$(printf %04i $IMEM)/prep3/namelist.input ./namelist.input
          ln -fs $TOP_BASE_DIR/scripts/610_forecast.sh                      ./610_forecast.sh
          qsub -v cwd=$PWD 610_forecast.sh 
        done

        # Wait 1
        TARGET_DIR1=$WRF_FCST_DIR/mem$(printf %04i $NUM_ENS)/WRF_RUN
        FCST_COUNTER=0
        while [ $FCST_COUNTER -lt 50 ]; do
          if [ -f ${TARGET_DIR1}/run_forecast_str ]; then
            FCST_COUNTER=`expr $FCST_COUNTER + 1`
          fi
          sleep 5
        done

        # Wait 2
        for IMEM in $(seq 1 $NUM_ENS)
        do
          TARGET_DIR1=$WRF_FCST_DIR/mem$(printf %04i $IMEM)/WRF_RUN
          if [ ! -f ${TARGET_DIR1}/run_forecast_done ]; then
            cd $TARGET_DIR1
            rm ./run_forecast_str
            unlink ./namelist.input 
            touch ./small_time_step
            sed -e "s/time_step .*/time_step = 6,/g" $WRF_FCST_DIR/mem$(printf %04i $IMEM)/prep3/namelist.input > ./namelist.input
            qsub -v cwd=$PWD 610_forecast.sh 
          fi
        done

        # Wait 3
        for IMEM in $(seq 1 $NUM_ENS)
        do
          FCST_COUNTER=0
          TARGET_DIR1=$WRF_FCST_DIR/mem$(printf %04i $IMEM)/WRF_RUN
          while [ ! -f ${TARGET_DIR1}/run_forecast_done ]; do
            echo "waiting for forecast member $IMEM"
            sleep 5
            if [ -f ${TARGET_DIR1}/run_forecast_str ]; then
              FCST_COUNTER=`expr $FCST_COUNTER + 1`
              if [ $FCST_COUNTER -eq 80 ]; then
                cd $TARGET_DIR1
                unlink ./namelist.input 
                touch ./small_time_step2
                sed -e "s/time_step .*/time_step = 5,/g" $WRF_FCST_DIR/mem$(printf %04i $IMEM)/prep3/namelist.input > ./namelist.input
                qsub -v cwd=$PWD 610_forecast.sh 
              fi
            fi
          done
        done

        # Link
        YY=`echo ${FDATE}|cut -c 1-4` ; MM=`echo ${FDATE}|cut -c 5-6`
        DD=`echo ${FDATE}|cut -c 7-8` ; HR=`echo ${FDATE}|cut -c 9-10`
        MI=`echo ${FDATE}|cut -c 11-12`
        for IMEM in $(seq 1 $NUM_ENS)
        do
          TARGET_DIR1=$WRF_FCST_DIR/mem$(printf %04i $IMEM)/WRF_RUN
          TARGET_DIR2=$C_CYCL_DATA_DIR/WRF_OUT/
          if [ ! -d $TARGET_DIR2  ]; then mkdir -p $TARGET_DIR2 ; fi
          cd $TARGET_DIR1
          TARGET_FILE1=$TARGET_DIR1/wrfout_d01_$YY-$MM-${DD}_${HR}:${MI}:00
          TARGET_FILE2=$TARGET_DIR2/wrfout_d01_$(printf %04i $IMEM)_$YY-$MM-${DD}_${HR}:${MI}:00
          cp -p $TARGET_FILE1 $TARGET_FILE2  
          TARGET_FILE1=$TARGET_DIR1/wrfrst_d01_$YY-$MM-${DD}_${HR}:${MI}:00
          TARGET_FILE2=$TARGET_DIR2/wrfrst_d01_$(printf %04i $IMEM)_$YY-$MM-${DD}_${HR}:${MI}:00
          cp -p $TARGET_FILE1 $TARGET_FILE2  

          TARGET_DIR1="$C_CYCL_DATA_DIR/WRF_OUT/"
          TARGET_DIR2="$CYCL_DATA_DIR/$FDATE/DA_prior/"
          if [ ! -d $TARGET_DIR2  ]; then mkdir -p $TARGET_DIR2 ; fi
          TARGET_FILE1=$TARGET_DIR1/wrfout_d01_$(printf %04i $IMEM)_$YY-$MM-${DD}_${HR}:${MI}:00
          TARGET_FILE2=$TARGET_DIR2/DA_prior_$(printf %04i $IMEM)
          ln -fs $TARGET_FILE1 $TARGET_FILE2  
        done
      fi

    fi # FORECAST_FLAG end

    #------------------------
    # SAVE & REMOVE
    #------------------------
#    rm $C_CYCL_DATA_DIR/DA_post/*
#    rm $C_CYCL_DATA_DIR/WRF_IN/*
#    if [ ! -f $C_CYCL_WORK_DIR/filter_skip_flag ]; then
#      rm $C_CYCL_WORK_DIR/filter/preassim_member*.nc
#    fi
#    if [ $DA_FILTER -eq 13 ]; then
#      if [ -f $C_CYCL_WORK_DIR/filter/cal_mean_done ]; then
#        rm $C_CYCL_WORK_DIR/filter/filter_out/filter_restart*
#      fi
#    else
#      rm $C_CYCL_WORK_DIR/filter/filter_out/filter_restart*
#    fi
#    for IMEM in $(seq 1 $NUM_ENS)
#    do 
#      rm $C_CYCL_WORK_DIR/assim_advance/mem$(printf %04i $IMEM)/prep1/wrfinput_d01
#      rm $C_CYCL_WORK_DIR/assim_advance/mem$(printf %04i $IMEM)/prep2/wrfbdy_d01
#      rm $C_CYCL_WORK_DIR/assim_advance/mem$(printf %04i $IMEM)/prep2/wrfinput_d01
#      rm $C_CYCL_WORK_DIR/assim_advance/mem$(printf %04i $IMEM)/WRF_RUN/wrfout_d01*
#      rm $C_CYCL_WORK_DIR/assim_advance/mem$(printf %04i $IMEM)/WRF_RUN/wrfrst_d01*
#    done

    YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
    DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
    MI=`echo ${CDATE}|cut -c 11-12`
    PDATE=`date -d "${YY}${MM}${DD} ${HR}:${MI} 30 minute ago" +%Y%m%d%H%M`
    PMI=`echo ${PDATE}|cut -c 11-12`
    
    if [ $PDATE -gt $ADATE ]; then
       $TOP_BASE_DIR/scripts/998b_remove_online.sh ${ADATE} ${PDATE}
    fi
#    if [ $CDATE -ne $SDATE ]; then
#      if [ $PMI -ne 45 ]; then
#        rm $C_CYCL_DATA_DIR/../$PDATE/WRF_OUT/wrfrst*
#      fi
#    fi

    #------------------------
    # DATE
    #------------------------
    YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
    DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
    MI=`echo ${CDATE}|cut -c 11-12`
    NDATE=`date -d "${YY}${MM}${DD} ${HR}:${MI} $ASSIM_INT_MINS minute" +%Y%m%d%H%M`
    CDATE=$NDATE

  done






exit

