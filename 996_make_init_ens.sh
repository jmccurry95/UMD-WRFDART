#!/bin/sh 
set -ex

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


NUM_ENS=64
EXP=EXP2
if [ "$EXP" == "EXP1"  ]; then
  SDATE=201905281200
elif [ "$EXP" == "EXP2"  ]; then
  SDATE=201907031100
fi

DD=`echo ${SDATE}|cut -c 7-8`
HR=`echo ${SDATE}|cut -c 9-10`
SDATE2=`echo ${SDATE}|cut -c 1-10`

BASE_DIR=/glade/work/kkurosaw/WRF-DART/DATA/DATA/TEST_20220805/$EXP/CYCLE/EAKF/$SDATE/DA_prior
ADD_BNK_PER=/glade/u/home/jmccurry/DART/models/wrf/shell_scripts/add_bank_perts.20190717.ncl
IC=$BASE_DIR/../../../../ICBC/$SDATE2/wrfinput_d01

#------------------------------------------------------
# Add noise
#------------------------------------------------------
cd $BASE_DIR

for IMEM in $(seq 1 $NUM_ENS)
do
  cp $IC ./wrfvar_output
  CMD3="ncl 'MEM_NUM=${IMEM}' 'CYCLE=${DD}${HR}' $ADD_BNK_PER"
  if [ -f ./nclrun3.out ]; then rm ./nclrun3.out ; fi
  cat > ./nclrun3.out << EOF
  $CMD3
EOF
  chmod +x ./nclrun3.out
  ./nclrun3.out >& add_perts.out
  mv wrfvar_output DA_prior_$(printf %04i $IMEM)
done

exit

