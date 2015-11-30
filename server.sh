#!/bin/bash
while true
do
	# Listen for connctions
	nc -v -v -w 1 -l 25

        DAY=$(/usr/bin/date +"%Y%m%d")
        TIME=$(/usr/bin/date +"%H%M%S")

	LOGFILE="/home/Erik/c/camera/log/camera-$DAY.log"

	# Spawn the motion detect script
	/home/Erik/c/camera/motiondetected.sh >> $LOGFILE &	

	echo "Motion detect at $DAY $TIME"

	echo "Motion detect at $DAY $TIME" >> $LOGFILE

done
