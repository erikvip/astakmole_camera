#!/bin/bash
#
# Fetch an image from the camera and save it to DAY/TIME.jpg
#

# Root dir of this script
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# CAM_USER CAM_PASS and CAM_HOST config variables
source "${ROOTDIR}/camera.conf";

while true
do

	DAY=$(/bin/date +"%Y%m%d")
	TIME=$(/bin/date +"%H%M%S")
	URL="http://${CAM_USER}:${CAM_PASS}@${CAM_HOST}/tmpfs/auto.jpg?$DAY$TIME"

	# DATA BASE PATH
	DATAPATH="${ROOTDIR}/data/$DAY"
	
	if [ ! -d $DATAPATH ]; then
		mkdir $DATAPATH
	fi
	wget --timeout=10 -q -O "$DATAPATH/$TIME.jpg" "$URL" 
	
	if [ ! -s "$DATAPATH/$TIME.jpg" ]; then
		# File is 0 bytes, an error or timeout occured
		echo "ERROR: $DATAPATH/$TIME.jpg is 0 bytes"
		ls -l "$DATAPATH/$TIME.jpg"
		echo "Deleting $DATAPATH/$TIME.jpg and delaying for 1 second..."
		rm -I "$DATAPATH/$TIME.jpg"
		sleep 1
		
	else
		# File size is normal
		#echo "Normal fetch for $DATAPATH/$TIME.jpg"
		# NOOP
		:
		# Now compress the image
#		/usr/bin/mogrify -compress JPEG -quality 9 "$DATAPATH/$TIME.jpg"
		# Example to write date and stuff...
# mogrify -fill white -gravity NorthEast -pointsize 28 -draw 'text 0,0 "2015-01-06 16:44:35"' -undercolor black -compress JPEG -quality 8 -strip -write compress.jpg test.jpg
# Example of human redable file mod date:
# stat -c %y lightweight-browsers.txt | cut -d "." -f1 


	fi
	
done

