#!/bin/bash

# Root dir of this script
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while true
do
	# Listen for connections
	sudo nc -d -v -v -w 1 -l 25 >> "${ROOTDIR}/ncinput.txt"
	RET=$?;

	[ $RET == 130 ] && exit ;

	if [ $RET == 0 ]; then
        DAY=$(date +"%Y%m%d")
        TIME=$(date +"%H%M%S")

        LOGFILE="${ROOTDIR}/log/camera-$DAY.log"

        # Spawn the motion detect script
        ${ROOTDIR}/motiondetected.sh >> $LOGFILE &	
        RET=$?

        echo "Motion detected at $DAY $TIME. Return value: ${RET}"

        
    fi;

done
