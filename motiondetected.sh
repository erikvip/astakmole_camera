#!/bin/bash

# Fetch an image from the camera and save it to DAY.TIME/TIME.jpg
# Loops for 120 times - which should be around 2 minutes


DAY=$(date +"%Y%m%d")
TIME=$(date +"%H:%M:%S")
LOGFILE="/home/erikp/work/camera/log/camera-$DAY.log"
echo "Motion detect at $DAY $TIME" >> $LOGFILE

c=10

while [ "$c" -gt 0 ]
do
	c=$((c-1))

	DAY=$(date +"%Y%m%d")
	TIME=$(date +"%H%M%S")
	URL="http://10.0.0.120/tmpfs/auto.jpg?$DAY$TIME"

	# DATA BASE PATH
	DATAPATH="/home/erikp/work/camera/data/$DAY"

	if [ ! -d $DATAPATH ]; then
		mkdir $DATAPATH
	fi
	wget --timeout=10 -q -O "$DATAPATH/$TIME.jpg" "$URL" 
	
	if [ ! -s "$DATAPATH/$TIME.jpg" ]; then
		# File is 0 bytes, an error or timeout occured
		echo "ERROR: $DATAPATH/$TIME.jpg is 0 bytes" >> $LOGFILE
		ls -l "$DATAPATH/$TIME.jpg" >> $LOGFILE
		echo "Deleting $DATAPATH/$TIME.jpg and delaying for 1 second..." >> $LOGFILE
		rm -I "$DATAPATH/$TIME.jpg"
		sleep 1
		
	else
		# File size is normal
		# NOOP
		:
		# Now compress the image
#		/usr/bin/mogrify -compress JPEG -quality 9 "$DATAPATH/$TIME.jpg"
		# Example to write date and stuff...
# mogrify -fill white -gravity NorthEast -pointsize 28 -draw 'text 0,0 "2015-01-06 16:44:35"' -undercolor black -compress JPEG -quality 8 -strip -write compress.jpg test.jpg
# Example of human redable file mod date:
# stat -c %y lightweight-browsers.txt | cut -d "." -f1 
# 
# Make video example:
# ls *.jpg | jpeg2yuv -f 4 -I p | yuv2lav -o stream.avi


	fi
	


done

