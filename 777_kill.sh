#!/bin/sh 
set -x

COUNTER=18310
while [ $COUNTER -lt 24598 ]; do
#  qdel $COUNTER
  kill $COUNTER
  COUNTER=`expr $COUNTER + 1`
done

exit
