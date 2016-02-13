#!/bin/bash

###############################################################################
# Fetch an image from the camera and save it to DAY.TIME/TIME.jpg
# ~~Loops for 120 times - which should be around 2 minutes~~
# Updated to loop 60 times, or about 60 seconds.
# Verified the Astek Mole Camera will fire the even tracking email
# Every 60 seconds when there is continuous motion (well, seems like 
# 61 seconds, probably due to lag in capture / smtp relay)
###############################################################################

# Root dir of this script
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Day and time for right now
DAY=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")
LOGFILE="${ROOTDIR}/log/camera-$DAY.log"

# CAM_USER CAM_PASS and CAM_HOST config variables
source "${ROOTDIR}/camera.conf";

# Seconds to grab from camera (this is how many times we run the loop)
c=60

#Should only be 1 copy of this script running, exit() if we're already running
PCOUNT=$(ps -ef | grep -v grep | grep -c "bash $0");

#if [[ $PCOUNT -gt 1 ]]; then
#	echo "${TIME} Script is already running. Exiting."
#	exit 1
#fi;

echo "Motion detect at $DAY $TIME" >> $LOGFILE
NOTIFY=true

while [ "$c" -gt 0 ]
do
	c=$((c-1))

	DAY=$(date +"%Y%m%d")
	TIME=$(date +"%H%M%S")

	URL="http://${CAM_USER}:${CAM_PASS}@${CAM_HOST}/tmpfs/auto.jpg?$DAY$TIME"

	# DATA BASE PATH
	DATAPATH="${ROOTDIR}/data/$DAY"

	if [ ! -d $DATAPATH ]; then
		mkdir $DATAPATH
	fi
	wget --timeout=2 -q -O "$DATAPATH/$TIME.jpg" "$URL" 
	
	if [ ! -s "$DATAPATH/$TIME.jpg" ]; then
		# File is 0 bytes, an error or timeout occured
		echo "ERROR: $DATAPATH/$TIME.jpg is 0 bytes" >> $LOGFILE
		ls -l "$DATAPATH/$TIME.jpg" >> $LOGFILE
		echo "Deleting $DATAPATH/$TIME.jpg and delaying for 1 second..." >> $LOGFILE
		rm -I "$DATAPATH/$TIME.jpg"
		sleep 1
	else
		notify-send -i "$DATEPATH/$TIME" "Motion Detected" "$DAY at $TIME. Recording started..."
	fi



done

