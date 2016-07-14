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
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
SCRIPT_FILE="${BASH_SOURCE[0]}";

setup() {
	# Day and time for right now
	DAY=$(date +"%Y%m%d")
	TIME=$(date +"%H%M%S")
	LOGFILE="${ROOTDIR}/log/camera-$DAY.log"

	# CAM_USER CAM_PASS and CAM_HOST config variables
	source "${ROOTDIR}/camera.conf";

	# Seconds to grab from camera (this is how many times we run the loop)
	c=60
}

main() {
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
		wget --timeout=2 --tries=1 -q -O "$DATAPATH/$TIME.jpg" "$URL"

		if [ ! -s "$DATAPATH/$TIME.jpg" ]; then
			# File is 0 bytes, an error or timeout occured
			echo "ERROR: $DATAPATH/$TIME.jpg is 0 bytes" >> $LOGFILE
			ls -l "$DATAPATH/$TIME.jpg" >> $LOGFILE
			echo "Deleting $DATAPATH/$TIME.jpg and delaying for 1 second..." >> $LOGFILE
			rm -I "$DATAPATH/$TIME.jpg"
			sleep 1
		else
			if [ "$NOTIFY" == true ]; then
				notify-send -i "$DATEPATH/$TIME" "Motion Detected" "$DAY at $TIME. Recording started..."
				NOTIFY=false
			fi
		fi
	done

	# Now create an MP4 video from the still images
	/usr/bin/nice -n 19 "${ROOTDIR}"/compressAndMakeGif.sh "${DAY}"
}

#Cleanup script
finish() {
	# Remove lockfile
	rm -f "${LOCKFILE}";
}

# Check if lock exists (process is already running)
# If so, verify the PID is still active
# and check the timestamp, if it's over 5 minutes, then
# kill the script and run now
verify_lock() {
	LOCKFILE="${ROOTDIR}/data/$(basename ${SCRIPT_FILE} .sh).lock";
	if [ -e ${LOCKFILE} ]; then
		# Lockfile exits, verify the PID is running
		kill -0 `cat ${LOCKFILE}`;
		if [[ $? = 0 ]]; then
			# PID exists
			local _lastmod=$(stat -c "%Y" "${LOCKFILE}") _now=$(date +%s) _diff=0
			let _diff=$_now-$_lastmod

#			echo "last: $_lastmod  now: $_now  diff: $_diff "  >> $LOGFILE
			if [ "$_diff" -gt 300 ]; then

				echo "Motion detection script has stalled. Terminating process." >> $LOGFILE
				rm -f "${LOCKFILE}"
				acquire_lock
			else
				echo "Motion detection is already running. Quitting..."
				exit 1
			fi
		else
			# PID does NOT exist. Stale lock file
			echo "Removing stale lock file." >> $LOGFILE
			rm -f "${LOCKFILE}"
			acquire_lock
		fi
	else
		# Lockfile does not exist
		acquire_lock
	fi
}

# Create the lock file (execution should continue here)
acquire_lock() {
	echo $$ > "${LOCKFILE}"

	#Run the finish method last
	trap finish EXIT

}

# Main execution area
setup
verify_lock
main
finish
