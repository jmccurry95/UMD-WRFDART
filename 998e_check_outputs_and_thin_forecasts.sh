#!/bin/sh 
set -ex
MODE="KENT"
EXPLIST='EXP122'
CONFIGLIST='0 1'
for EXP in $EXPLIST;do
for MESO_CONFIG in $CONFIGLIST;do

echo $EXP
echo $MESO_CONFIG

######
NUM_ENS=40
#EXP=EXP7
#MESO_CONFIG=0

if [ "$EXP" == "EXP21"  ]; then 
  export SDATE=202004130500
  export SFDATE=202004131100
  export ADATE=202004130600
  export EDATE=202004132000
elif [ "$EXP" == "EXP17"  ]; then 
  export SDATE=202008121200
  export ADATE=202008121200
  export SFDATE=202008121700
  export EDATE=202008130200
elif [ "$EXP" == "EXP23"  ]; then 
  export SDATE=202009031000
  export ADATE=202009031100
  export SFDATE=202009031600
  export EDATE=202009040100
elif [ "$EXP" == "EXP24"  ]; then 
  export SDATE=202107171100
  export ADATE=202107171200
  export EDATE=202107180200
elif [ "$EXP" == "EXP25"  ]; then
  export SDATE=202206081500
  export ADATE=202206081500
  export EDATE=202206090500
elif [ "$EXP" == "EXP26"  ]; then
  export SDATE=202207021400
  export ADATE=202207021500
  export EDATE=202207030500
elif [ "$EXP" == "EXP27"  ]; then
  export SDATE=202207161100
  export ADATE=202207161200
  export EDATE=202207170200
elif [ "$EXP" == "EXP8"  ]; then
  export SDATE=202008121200
  export ADATE=202008121200
  export EDATE=202008130200
elif [ "$EXP" == "EXP9"  ]; then
  export SDATE=202008121200
  export ADATE=202008121200
  export EDATE=202008130200
elif [ "$EXP" == "EXP122"  ]; then
  export SDATE=202008121200
  export ADATE=202008121200
  export EDATE=202008130200
fi

# DA_NAME=EAKF
# DA_NAME=LPF
# DA_NAME=LPF-EnKF_HYB0.50

case "$MODE" in 
"KENT")
DATA_DIR=/glade/scratch/jmccurry/WRF-DART/DATA/DATA/TEST_20230514/$EXP/CYCLE/config_$MESO_CONFIG
FCST_DIR=$DATA_DIR/forecasts
;;
"JMC")
DATA_DIR=/glade/scratch/jmccurry/WOF/realtime/$EXP.$MESO_CONFIG
FCST_DIR=$DATA_DIR
;;  
esac

cd $FCST_DIR
ls -d WRFOUTS_FCST* | sort -n | head -n 17 > forecast_init_times.txt
while read init_time;do
cd $init_time;echo $init_time
ls -d 20*15 | sort -n  > times_to_purge.txt
ls -d 20*45 | sort -n >> times_to_purge.txt
while read purge_times; do  
for i in {1..20};do
rm $purge_times/wrfout_d01_forecast_${purge_times}_${i}
#ls $purge_times/wrfout_d01_forecast_${purge_times}_${i}

done


done < times_to_purge.txt
cd $FCST_DIR
done < forecast_init_times.txt
  

######
done 
done

exit

