#!/bin/bash

# Fetch an image from the camera and save it to DAY.TIME/TIME.jpg
# Loops for 120 times - which should be around 2 minutes

DAY=$(/usr/bin/date +"%Y%m%d")
TIME=$(/usr/bin/date +"%H:%M:%S")
LOGFILE="/home/Erik/c/camera/log/camera-$DAY.log"
echo "Motion detect at $DAY $TIME" >> $LOGFILE

c=120

while [ "$c" -gt 0 ]
do
	c=$((c-1))

	DAY=$(/usr/bin/date +"%Y%m%d")
	TIME=$(/usr/bin/date +"%H%M%S")
	URL="http://192.168.1.120/tmpfs/auto.jpg?$DAY$TIME"

	# BASE PATH
	PATH="/home/Erik/c/camera/data/$DAY"

	if [ ! -d $PATH ]; then
		/usr/bin/mkdir $PATH
	fi
	/usr/bin/wget --timeout=10 -q -O "$PATH/$TIME.jpg" "$URL" 
	
	if [ ! -s "$PATH/$TIME.jpg" ]; then
		# File is 0 bytes, an error or timeout occured
		echo "ERROR: $PATH/$TIME.jpg is 0 bytes" >> $LOGFILE
		/usr/bin/ls -l "$PATH/$TIME.jpg" >> $LOGFILE
		echo "Deleting $PATH/$TIME.jpg and delaying for 1 second..." >> $LOGFILE
		/usr/bin/rm -I "$PATH/$TIME.jpg"
		/usr/bin/sleep 1
		
	else
		# File size is normal
		# NOOP
		:
		# Now compress the image
#		/usr/bin/mogrify -compress JPEG -quality 9 "$PATH/$TIME.jpg"
		# Example to write date and stuff...
# mogrify -fill white -gravity NorthEast -pointsize 28 -draw 'text 0,0 "2015-01-06 16:44:35"' -undercolor black -compress JPEG -quality 8 -strip -write compress.jpg test.jpg
# Example of human redable file mod date:
# stat -c %y lightweight-browsers.txt | cut -d "." -f1 
# 
# Make video example:
# ls *.jpg | jpeg2yuv -f 4 -I p | yuv2lav -o stream.avi


	fi
	


done

