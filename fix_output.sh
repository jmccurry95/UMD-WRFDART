#!/bin/bash
for date in 1100 1115 1130 1145 1200 1215 1230 1245 1300 1315 1330 1345 1400 1415 1430 1445 1500; do
	cd /glade/derecho/scratch/jmccurry/WRF-DART/WORK/PROJECT3/EXP2_20200812/CYCLE/nonparametric1/20200812${date}/filter	
	cp preassim_sd.nc /glade/derecho/scratch/jmccurry/WRF-DART/DATA/DATA/PROJECT3/EXP2_20200812/CYCLE/nonparametric1/20200812${date}/filter_out/
	cp output_sd.nc /glade/derecho/scratch/jmccurry/WRF-DART/DATA/DATA/PROJECT3/EXP2_20200812/CYCLE/nonparametric1/20200812${date}/filter_out/

done

