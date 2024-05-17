#!/bin/sh
set -ex

echo "==========================================="
echo "Starting 608_prep3_forecast.sh"
echo `pwd`
echo "==========================================="

FCST_TIME=${1}

S_YY=`echo $CDATE | cut -b1-4`
S_MO=`echo $CDATE | cut -b5-6`
S_DD=`echo $CDATE | cut -b7-8`
S_HH=`echo $CDATE | cut -b9-10`
S_MI=`echo $CDATE | cut -b11-12`
S_SS="00"
S_STRING=${S_YY}-${S_MO}-${S_DD}_${S_HH}:${S_MI}:${S_SS}

NDATE=`date -d "${S_YY}${S_MO}${S_DD} ${S_HH}:${S_MI} $FCST_TIME minute" +%Y%m%d%H%M`
E_YY=`echo $NDATE | cut -b1-4`
E_MO=`echo $NDATE | cut -b5-6`
E_DD=`echo $NDATE | cut -b7-8`
E_HH=`echo $NDATE | cut -b9-10`
E_MI=`echo $NDATE | cut -b11-12`
E_SS="00"
E_STRING=${E_YY}-${E_MO}-${E_DD}_${E_HH}:${E_MI}:${E_SS}

INT_MI=$ASSIM_INT_MINS
INT_SS=`expr $FCST_TIME \* 60`
MY_NUM_DOMAINS=1

if [ $CDATE -eq $SDATE ]; then
  RESTART_FLAG=.false.
 else
  RESTART_FLAG=.true.
fi

cat > script.sed << EOF
  /restart_interval/c\
  restart_interval           = ${ASSIM_INT_MINS},
  /run_hours/c\
  run_hours                  = 0,
  /run_minutes/c\
  run_minutes                = 0,
  /run_seconds/c\
  run_seconds                = ${INT_SS},
  /start_year/c\
  start_year                 = ${MY_NUM_DOMAINS}*${S_YY},
  /start_month/c\
  start_month                = ${MY_NUM_DOMAINS}*${S_MO},
  /start_day/c\
  start_day                  = ${MY_NUM_DOMAINS}*${S_DD},
  /start_hour/c\
  start_hour                 = ${MY_NUM_DOMAINS}*${S_HH},
  /start_minute/c\
  start_minute               = ${MY_NUM_DOMAINS}*${S_MI},
  /start_second/c\
  start_second               = ${MY_NUM_DOMAINS}*${S_SS},
  /end_year/c\
  end_year                   = ${MY_NUM_DOMAINS}*${E_YY},
  /end_month/c\
  end_month                  = ${MY_NUM_DOMAINS}*${E_MO},
  /end_day/c\
  end_day                    = ${MY_NUM_DOMAINS}*${E_DD},
  /end_hour/c\
  end_hour                   = ${MY_NUM_DOMAINS}*${E_HH},
  /end_minute/c\
  end_minute                 = ${MY_NUM_DOMAINS}*${E_MI},
  /end_second/c\
  end_second                 = ${MY_NUM_DOMAINS}*${E_SS},
  /history_interval/c\
  history_interval           = ${MY_NUM_DOMAINS}*${INT_MI},
  /frames_per_outfile/c\
  frames_per_outfile         = ${MY_NUM_DOMAINS}*1,
  /max_dom/c\
  max_dom                    = ${MY_NUM_DOMAINS},
EOF
sed -f script.sed $TEMP_FILE3 > tmp_namelist.input
sed -e "s/restart_flag000/$RESTART_FLAG/g" tmp_namelist.input > namelist.input
rm tmp_namelist.input


touch ./prep3_forecast_ready

exit



exit 

