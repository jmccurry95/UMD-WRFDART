#!/bin/sh 
#-------------------------------------------
# Kenta Kurosawa : July 2022
#
# Main script for running cycling data assimilation experiments
# with WRF model for DART
#
# (Ver.0: Created May 2009, Ryan Torn, U. Albany: WRF-DART tutorial)
#-------------------------------------------

set -ex

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
# Setting 1
# DA 
#===========================================
EXP=EXP132
MESO_CONFIG=0


if [ "$EXP" == "EXP1"  ]; then
  export SDATE=202004130500
  export ADATE=202004130600
  export SFDATE=202004131100
  export EDATE=202004132000
elif [ "$EXP" == "EXP21"  ]; then
  export SDATE=202004130500
  export ADATE=202004130600
  export SFDATE=202004131100
  export EDATE=202004132000
elif [ "$EXP" == "EXP2"  ]; then
  export SDATE=202008121100
  export ADATE=202008121200
  export SFDATE=202008121700
  export EDATE=202008130200
elif [ "$EXP" == "EXP3"  ]; then
  export SDATE=202009031000
  export ADATE=202009031100
  export SFDATE=202009031600
  export EDATE=202009040100
elif [ "$EXP" == "EXP23"  ]; then
  export SDATE=202009031000
  export ADATE=202009031100
  export SFDATE=202009031600
  export EDATE=202009040100
elif [ "$EXP" == "EXP4"  ]; then
  export SDATE=202107171100
  export ADATE=202107171200
  export SFDATE=202107180100
  export EDATE=202107180100
elif [ "$EXP" == "EXP24"  ]; then
  export SDATE=202107171100
  export ADATE=202107171200
  export SFDATE=202107171700
  export EDATE=202107180200
elif [ "$EXP" == "EXP25"  ]; then
  export SDATE=202206081400
  export ADATE=202206081500
  export SFDATE=202206082000
  export EDATE=202206090500
elif [ "$EXP" == "EXP26"  ]; then
  export SDATE=202207021400
  export ADATE=202207021500
  export SFDATE=202207022000
  export EDATE=202207030500
elif [ "$EXP" == "EXP27"  ]; then
  export SDATE=202207161100
  export ADATE=202207161200
  export SFDATE=202207161700
  export EDATE=202207170200
elif [ "$EXP" == "EXP8"  ]; then
  export SDATE=202008121100
  export ADATE=202008121200
  export SFDATE=202008130100
  export EDATE=202008130200
elif [ "$EXP" == "EXP17"  ]; then
  export SDATE=202008121100
  export ADATE=202008121200
  export SFDATE=202008121700
  export EDATE=202008130200
elif [ "$EXP" == "EXP132"  ]; then
  export SDATE=202008121100
  export ADATE=202008121200
  export SFDATE=202008121700
  export EDATE=202008122200
fi

echo $SDATE
echo $EDATE
CUT_SDATE=`echo ${SDATE}|cut -c 1-8`

export ASSIM_INT_MINS=15   # DA interval (min)
BIAS='' # leave blank for no bias
max_processes=120 #most processes that can be run at once
if [ $MESO_CONFIG -eq 0 ]; then #default network
export OBSTYPE='cropped_osse' #obs naming convention default
else
export OBSTYPE="cropped_osse_config_$MESO_CONFIG" #obs naming convention CONFIGS
fi
export LONG_FCST_MINS=180  # long forecast (min)
export LONG_FCST_NUM_ENS=20
#--- EXP name ---
DA_FILTER=1  #  1:EAKF
             # 11:LPF
             # 12:LPF-EnKF(50-50)
             # 13:LPF-EnKF(Adaptive)

if   [ $DA_FILTER -eq 1  ]; then # EAKF
  DA_KIND=EAKF
elif [ $DA_FILTER -ge 11 ]; then # PF
  case $DA_FILTER in
    "11") # LPF
    DA_KIND=LPF
    ;;
    "12") # LPF-EnKF(50-50)
    MIN_RES=0.5
    DA_KIND=LPF-EnKF_HYB`printf "%3.2f" $MIN_RES`
    ;;
    "13") # LPF-ADAPTIVE-HYBRID
    DA_KIND=LPF-EnKF_ADPT_HYB_Feb2023 # <-- 
    ;;
  esac
fi
DA_KIND=${DA_KIND}_wo_noise

#===========================================
# Setting 2
# Paths to data and WRF & DART components 
#===========================================
MODEL=wrf
EXP_NAME_BASE=TEST_20230514/$EXP/CYCLE/config_$MESO_CONFIG # <-- !!
export TOP_DIR=/glade/scratch/jmccurry/WRF-DART/
export TOP_WORK_DIR=$TOP_DIR/WORK/
export TOP_DATA_DIR=$TOP_DIR/DATA/
export TOP_BASE_DIR=$TOP_DIR/BASE/  # templates dir

export WORK_DIR=$TOP_WORK_DIR/$EXP_NAME_BASE/
export DATA_DIR=$TOP_DATA_DIR/DATA/$EXP_NAME_BASE/
export DART_DIR=$TOP_DATA_DIR/DART/
export MDEL_DIR=$DART_DIR/models/$MODEL/work/ # <- !!
export MDEL_DIR=/glade/u/home/jmccurry/DART_MAY10/models/wrf/work/

export WRF_DIR=$TOP_DATA_DIR/WRF/
export WPS_DIR=$TOP_DATA_DIR/WPS/
export WRFDA_DIR=$TOP_DATA_DIR/WRFDA/

export OBSR_DATA_DIR=$TOP_DIR/OBS #made -needs modification
export ICBC_DATA_DIR=$TOP_DIR/ICBC/${CUT_SDATE}/output${BIAS} #made -needs modification
export CYCL_DATA_DIR=$DATA_DIR
export CYCL_WORK_DIR=$WORK_DIR

#--- namelists ---
export TEMP_FILE1=$TOP_BASE_DIR/template/input_nmls/input.nml.osse_enkf_40mem_nssl
export TEMP_FILE2=$TOP_BASE_DIR/template/wrf_namelists/namelist.wps.template
export TEMP_FILE3=$TOP_BASE_DIR/template/wrf_namelists/namelist.input.osse_40mem_nssl
#--- Add noise ---
GRID_REF_OB=$MDEL_DIR/grid_refl_obs
ADD_PER_WHR=$MDEL_DIR/add_pert_where_high_refl

#--- WRF ---
PERT_WRF_BC=$MDEL_DIR/pert_wrf_bc
DA_WRFVAR_E=$WRFDA_DIR/var/build/da_wrfvar.exe
BE_DAT_CV33=$WRFDA_DIR/var/run/be.dat.cv3
ADD_BNK_PER=/glade/u/home/jmccurry/DART/models/wrf/shell_scripts/add_bank_perts.${CUT_SDATE}.ncl

#--- advance time ---
export ADVANCE_TIME=${MDEL_DIR}/advance_time

#===========================================
# Setting 3
# Parameters & Flags 
#===========================================
# 606.sh
#export VARS_A="U,V,W,PH,T,MU,QVAPOR,QCLOUD,QRAIN,QICE,QSNOW,QGRAUP,QNICE,QNRAIN,U10,V10,T2,TH2,Q2,PSFC,REFL_10CM"
export VARS_A="U,V,W,PH,T,MU,QVAPOR,QCLOUD,QRAIN,QICE,QSNOW,QGRAUP,QHAIL,QNICE,QNRAIN,QNDROP,QNSNOW,QNGRAUPEL,QNHAIL,QVGRAUPEL,QVHAIL,U10,V10,T2,TH2,Q2,PSFC,REFL_10CM"

export VARS_B="U,V,W,PH,MU"

# 607.sh (add noise)
export TIME_BTP=`expr $ASSIM_INT_MINS \* 60`    # Time between perturbations (seconds)
export MINI_REF=25.0   # minimum reflectivity threshold (dBZ) for where noise is added
export HORI_LEN=9000.0 # horizontal length scale (m) for perturbations
export VERT_LEN=3000.0 # vertical length scale (m) for perturbations
export NOISE_UU=0.50   # std. dev. of u noise (m/s), before smoothing, during first time period
export NOISE_VV=0.50   # std. dev. of v noise (m/s), before smoothing, during first time period
export NOISE_WW=0.0    # std. dev. of w noise (m/s), before smoothing, during first time period
export NOISE_TT=0.50   # std. dev. of temperature noise (K), before smoothing, during first time period
export NOISE_TD=0.00 #0.50   # std. dev. of dewpoint noise (K), before smoothing, during first time period
export NOISE_QV=0.50 # 0.0    # std. dev. of water vapor noise (g/kg), before smoothing, during first time period

#===========================================
# 4
# DA Cycle 
#===========================================

  # Main loop
  export CDATE=$SFDATE
#  export CDATE=201905281215 #201907171430 # 201907032015 #20190717080900 #201907171645
  while [[ $CDATE -le $EDATE ]]; do
  
    echo "==========================================="
    echo "Starting $CDATE (001_long_forecast.sh)"
    echo `pwd`
    echo "==========================================="
  
    #------------------------
    # Set & Check Files
    #------------------------
    export C_CYCL_WORK_DIR=$CYCL_WORK_DIR/$CDATE
    export C_CYCL_DATA_DIR=$CYCL_DATA_DIR/$CDATE

    YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
    DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
    MI=`echo ${CDATE}|cut -c 11-12`
    export FDATE=`date -d "${YY}${MM}${DD} ${HR}:${MI} $ASSIM_INT_MINS minute" +%Y%m%d%H%M`
    export CUT_CDATE=`echo ${CDATE}|cut -c 1-10`
    export CUT_FDATE=`echo ${FDATE}|cut -c 1-10`
    FDATE2=`date -d "${YY}${MM}${DD} ${HR}:${MI} 60 minute" +%Y%m%d%H%M` # prep2
    CUT_FDATE2=`echo ${FDATE2}|cut -c 1-10`                              # prep2
    PDATE=`date -d "${YY}${MM}${DD} ${HR}:${MI} $ASSIM_INT_MINS minute ago" +%Y%m%d%H%M` # prior
    mkdir -p $CYCL_DATA_DIR/forecasts/WRFOUTS_FCST${CDATE}
    #------------------------
    # WRF Forecast
    #------------------------
    #if [ -d $C_CYCL_WORK_DIR/long_forecast/ ]; then rm -rf $C_CYCL_WORK_DIR/long_forecast; fi
    
    mem_completed=`find -L $CYCL_DATA_DIR/forecasts/WRFOUTS_FCST${CDATE} -name "wrfout*" -type f | wc -l`
    all_complete=260
    if [ $mem_completed -eq $all_complete ]; then
    echo "all forecasts complete, nothing to do here"
    else
    for IMEM in $(seq 1 $LONG_FCST_NUM_ENS); do 
      imem_completed=`find -L $CYCL_DATA_DIR/forecasts/WRFOUTS_FCST${CDATE} -name "wrfout*_${IMEM}" -type f | wc -l`
      all_imem_complete=13
      if [ $imem_completed -eq $all_imem_complete ];then
      echo "all forecasts complete for member: " $IMEM
      else
      export WRF_FCST_DIR=$C_CYCL_WORK_DIR/long_forecast/mem$(printf %04i $IMEM)
      wrfrst_arr=($(ls $WRF_FCST_DIR/WRF_RUN/wrfrst* | sort -n))
      if [ ${#wrfrst_arr[@]} -eq 0 ]; then
       echo "restarting forecast for mem" $IMEM
       if [ -d $WRF_FCST_DIR ]; then rm -rf $WRF_FCST_DIR; fi
       mkdir -p $WRF_FCST_DIR 
       cd $WRF_FCST_DIR
       cp $TOP_BASE_DIR/scripts/long_fcst/611_long_forecast.sh    ./611_long_forecast.sh
       sh 611_long_forecast.sh $IMEM > test.log 2>&1 &
      else 
       echo "finishing forecast for mem" $IMEM
       cd $WRF_FCST_DIR
       cp $TOP_BASE_DIR/scripts/long_fcst/611_long_forecast.sh    ./611_long_forecast.sh
       sh 611_long_forecast.sh $IMEM > test.log 2>&1 &
      fi

       #cp $TOP_BASE_DIR/scripts/long_fcst/613_long_forecast.sh    ./613_long_forecast.sh
       #sh 613_long_forecast.sh $IMEM > complete.log 2>&1 &
      fi

    done
    fi
    #------------------------
    # DATE
    #------------------------
    YY=`echo ${CDATE}|cut -c 1-4` ; MM=`echo ${CDATE}|cut -c 5-6`
    DD=`echo ${CDATE}|cut -c 7-8` ; HR=`echo ${CDATE}|cut -c 9-10`
    MI=`echo ${CDATE}|cut -c 11-12`
    NDATE=`date -d "${YY}${MM}${DD} ${HR}:${MI} 30 minute" +%Y%m%d%H%M`
    CDATE=$NDATE
    num_processes=`ps | wc -l`
    echo "num processes running: " $num_processes
    while [[ $num_processes -gt $max_processes ]];do
    num_processes=`ps | wc -l`
    sleep 60  
    done
    sleep 10 

  done






exit

