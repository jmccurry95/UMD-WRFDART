#!/bin/bash
configs='config_0 config_1 config_2 config_3 config_4'
#exps='1 2 3 4 5 6 7'
exp=1
for config in configs;do
sed -e "/MESO_CONFIG=/c\MESO_CONFIG=${config}" -e "0,/MESO_CONFIG/{s/EXP=EXP[0-9]*/EXP=${exp}/}" 001_driver_long.sh > test.sh
nohup ./test.sh > E${exp}C${config} &
done
