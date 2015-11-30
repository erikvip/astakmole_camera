#!/bin/bash
while true
do
	# Listen for connctions
	sudo nc -v -v -w 1 -l 25

        DAY=$(date +"%Y%m%d")
        TIME=$(date +"%H%M%S")

	LOGFILE="/home/erikp/work/camera/log/camera-$DAY.log"

	# Spawn the motion detect script
	/home/erikp/work/camera/motiondetected.sh >> $LOGFILE &	

	echo "Motion detect at $DAY $TIME"

	echo "Motion detect at $DAY $TIME" >> $LOGFILE

done
