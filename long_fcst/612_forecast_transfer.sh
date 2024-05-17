#!/bin/sh 
SOURCE_DIR=${1}
ARCHIVE_DIR=${2}
IMEM=${3}
###########
#list files
wrfout_arr=($(ls $SOURCE_DIR/wrfout* | sort -n))
wrfrst_arr=($(ls $SOURCE_DIR/wrfrst* | sort -n))



###########
#transfer files
for wrfout in "${wrfout_arr[@]}";do
wrfout_b=`basename $wrfout`
YY=`echo $wrfout_b | cut -c 12-15`
MM=`echo $wrfout_b | cut -c 17-18`
DD=`echo $wrfout_b | cut -c 20-21`
hh=`echo $wrfout_b | cut -c 23-24`
mm=`echo $wrfout_b | cut -c 26-27`
TARGET_DIR=$ARCHIVE_DIR/${YY}${MM}${DD}${hh}${mm}
mkdir -p $TARGET_DIR
if [ -f $wrfout ]; then
echo $wrfout
mv $wrfout $TARGET_DIR/wrfout_d01_forecast_${YY}${MM}${DD}${hh}${mm}_${IMEM} 
fi
done

for wrfout in "${wrfrst_arr[@]}";do
wrfout_b=`basename $wrfout`

YY=`echo $wrfout_b | cut -c 12-15`
MM=`echo $wrfout_b | cut -c 17-18`
DD=`echo $wrfout_b | cut -c 20-21`
hh=`echo $wrfout_b | cut -c 23-24`
mm=`echo $wrfout_b | cut -c 26-27`
TARGET_DIR=$ARCHIVE_DIR/${YY}${MM}${DD}${hh}${mm}
mkdir -p $TARGET_DIR
if [ -f $wrfout ]; then
echo $wrfout
#cp $wrfout $TARGET_DIR/wrfout_d01_forecast_${YY}${MM}${DD}${hh}${mm}_${IMEM} 
rm $wrfout


fi
done

##########
#delete remaining files

