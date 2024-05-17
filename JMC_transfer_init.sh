#!/bin/bash
#transfer rundir output to DA prior folder

CAMPAIGN='PROJECT3'
EXP='EXP20190717'
TRIAL='NONPARAMETRIC1'
INIT_TIME='201907170700'


DATA=/glade/derecho/scratch/jmccurry/WRF-DART/DATA/DATA/${CAMPAIGN}/${EXP}/CYCLE/${TRIAL}
WORK=/glade/derecho/scratch/jmccurry/WRF-DART/WORK/${CAMPAIGN}/${EXP}/CYCLE/${TRIAL}

rm -rf ${WORK}
rm -rf ${DATA}/$INIT_TIME/DA_prior
mkdir -p ${DATA}/$INIT_TIME/DA_prior



for IMEM in {1..40};do 
cp /glade/campaign/univ/umcp0011/PAPER_1/ENSEMBLE_ICBC/${INIT_TIME:0:8}/rundir_3km/advance_temp${IMEM}/wrfinput_d01 $DATA/$INIT_TIME/DA_prior/DA_prior_$(printf %04i $IMEM)
done


