#!/bin/sh
###############################
#experiment settings
###############################
export EXP_MODE=real #real,osse
export CAMPAIGN=PROJECT3
export EXP=EXP20190717;
export SDATE=201907170700
export ADATE=201907170800
export EDATE=201907171200
export CDATE=201907170800
export MESO_CONFIG=NONPARAMETRIC5 #for exp_mode = osse
export NUM_ENS=40
export ASSIM_INT_MINS=15
export BIAS='' #leave blank for no added bias
export DA_FILTER=11 #1:EAKF 11:LPF 12:LPF-EnKF (50-50) 13:LPF-EnKF (adaptive)
export FILTER_WALLTIME=00:30:00
export FILTER_NODES=3
export FILTER_CORES_PER_NODE=128 
export ADD_NOISE_FLAG_MAIN=YES
export PHYS_SETTINGS=THOMP #NSSL, THOMP
export LBC_PERT_AMPLITUDE=default #default xfifth
export NONPARAMETRIC_OERROR=YES

###############################
#experiment paths
###############################
export TOP_DIR=/glade/derecho/scratch/jmccurry/WRF-DART
export MDEL_DIR=/glade/work/jmccurry/DART_MAY9/models/wrf/work/
export EXP_NAME_BASE=$CAMPAIGN/$EXP/CYCLE/$MESO_CONFIG


export TOP_WORK_DIR=$TOP_DIR/WORK/
export TOP_DATA_DIR=$TOP_DIR/DATA/
export TOP_BASE_DIR=$TOP_DIR/BASE/  # templates dir

export WORK_DIR=$TOP_WORK_DIR/$EXP_NAME_BASE/
export DATA_DIR=$TOP_DATA_DIR/DATA/$EXP_NAME_BASE/
export DART_DIR=$TOP_DATA_DIR/DART/

export WRF_DIR=$TOP_DATA_DIR/WRF/
export WPS_DIR=$TOP_DATA_DIR/WPS/
export WRFDA_DIR=$TOP_DATA_DIR/WRFDA/

export ICBC_DATA_DIR=$TOP_DIR/ICBC/${SDATE:0:8}/output${BIAS}
export CYCL_DATA_DIR=$DATA_DIR #made
export CYCL_WORK_DIR=$WORK_DIR #made

##############################
#optional experiment paths
##############################
export OERROR_STORE_DIR=$TOP_DIR/BASE/template/oerror_store
###############################
#namelist locations
###############################
export TEMP_FILE1=$TOP_BASE_DIR/template/input_nmls/$PHYS_SETTINGS/input.nml.project3
export TEMP_FILE2=$TOP_BASE_DIR/template/wrf_namelists/namelist.wps.template
export TEMP_FILE3=$TOP_BASE_DIR/template/wrf_namelists/$PHYS_SETTINGS/namelist.input.project3


##############################
#additive noise settings
##############################
export TIME_BTP=`expr $ASSIM_INT_MINS \* 60`    # Time between perturbations (seconds)
export MINI_REF=25.0   # minimum reflectivity threshold (dBZ) for where noise is added
export HORI_LEN=9000.0 # horizontal length scale (m) for perturbations
export VERT_LEN=3000.0 # vertical length scale (m) for perturbations
export NOISE_UU=0.25 #0.125   # 0.50 std. dev. of u noise (m/s), before smoothing, during first time period
export NOISE_VV=0.25 #0.125   # 0.50 std. dev. of v noise (m/s), before smoothing, during first time period
export NOISE_WW=0.0    # std. dev. of w noise (m/s), before smoothing, during first time period
export NOISE_TT=0.25 #0.125   # 0.50  std. dev. of temperature noise (K), before smoothing, during first time period
export NOISE_TD=0.00 # std. dev. of dewpoint noise (K), before smoothing, during first time period
export NOISE_QV=0.25 #0.125 # 0.50   # std. dev. of water vapor noise (g/kg), before smoothing, during first time period

