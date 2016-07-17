#!/bin/bash

############################################################################################
# Convert all the JPG's in the Camera directory into an animated gif
#
# Works in conjunction with the camera server.sh & motiondetected.sh scripts
#
# Expects a date, in the form YYYYMMDD, which should be found under $IMGDIR and $LOGDIR
# We parse the log file to find the start of the motion
############################################################################################

# Config. No trailing slash on directories
CAPTURESECONDS=60;
IMGDIR="/home/erikp/work/camera/data";
LOGDIR="/home/erikp/work/camera/log";
REQDATE=$1
IMGDIR="${IMGDIR}/${REQDATE}";
LOGFILE="/home/erikp/work/camera/log/camera-${REQDATE}.log";

[ -z $REQDATE ]  && echo "Must specify a date, corresponding to data folder, in the form YYYYMMDD" && exit 1
[ ! -d $IMGDIR ] && echo "Image Data Directory $IMGDIR not found." && exit 1
[ ! -f $LOGFILE ] && echo "Could not locate log file $LOGFILE" && exit 1

########################################################################
# Main event loop
# Figure out the START and END file, then use bash wildcards to pass
# the list of files into loop, downsample them, and make a GIF
########################################################################
main() {

    EVENTS=$(grep 'Motion detected at' ${LOGFILE} | egrep -o '[0-9]{6}$');
    EVENTCOUNT=$(grep -c 'Motion detected at' ${LOGFILE});

    # Finished gif's are moved into output, while images used are moved to processed
    OUTPUTDIR="$IMGDIR/output";
    PROCESSEDDIR="$IMGDIR/processed";
    [ ! -d "$OUTPUTDIR" ] && mkdir $OUTPUTDIR;
    [ ! -d "$PROCESSEDDIR" ] && mkdir $PROCESSEDDIR;

    echo "${EVENTCOUNT} Total Events for ${REQDATE}"

    COUNT=0;
    for e in $EVENTS; do
        (( COUNT += 1))
    
        EVENTNUMBER=$(printf %02d ${COUNT});

        # STARTTIME and ENDTIME get set in add_seconds
        add_seconds $e $CAPTURESECONDS
        WILDCARD="${STARTTIME}..${ENDTIME}";
        WILDCARD="$IMGDIR/{$WILDCARD}.jpg";
        
        IMAGEFILES=$(eval ls $WILDCARD 2> /dev/null);
        IMAGECOUNT=$(eval ls $WILDCARD 2> /dev/null | wc -l);

        TOTALDONE=$(echo $COUNT / $EVENTCOUNT \* 100 | bc -l | xargs printf %0.1f);

        #echo -ne "\033[2K\rEvent #${COUNT} of ${EVENTCOUNT}. Overall: ${TOTALDONE}% done.\n";
        echo -ne "\033[2K\r";
        ProgressBar ${COUNT} ${EVENTCOUNT} "Event #${COUNT} of ${EVENTCOUNT}. Total";
        echo ;

        RUNCOUNT=0;
        for f in $IMAGEFILES; do
            (( RUNCOUNT += 1 ))
            FILETIME=$(basename $f | cut -d. -f1);

            # bc doesn't work here due to floating point precision
            PERDONE=$(echo $RUNCOUNT / $IMAGECOUNT \* 100 | bc -l | xargs printf %0.1f );
            CTIME="${REQDATE:0:4}-${REQDATE:4:2}-${REQDATE:6:2} ${FILETIME:0:2}:${FILETIME:2:2}:${FILETIME:4:2}";
            PADRUNCOUNT=$(printf %02d $RUNCOUNT);
            #echo -ne "Processing Event #${COUNT} (${e}) File: $FILETIME ${RUNCOUNT} of ${IMAGECOUNT} ${PERDONE}% done ...\r";
            ProgressBar ${RUNCOUNT} ${IMAGECOUNT} "Processing Event #${COUNT} (${e}) File: $FILETIME ${RUNCOUNT} of ${IMAGECOUNT}.";

            #mogrify -fill white -gravity NorthEast -pointsize 28 -draw "text 0,0 '${CTIME}'" -undercolor black -compress JPEG -quality 8 -strip $f
            #mogrify -fill white -gravity NorthEast -pointsize 28 -draw "text 0,0 '${CTIME}'" -undercolor black -compress JPEG -quality 1 -strip $f
            #mogrify -fill white -gravity NorthEast -pointsize 28 -draw "text 0,0 'Event #${COUNT}/${EVENTCOUNT} ${CTIME} #${PADRUNCOUNT}/${IMAGECOUNT}'" -undercolor black $f
            mogrify -fill white -gravity NorthEast -pointsize 28 -draw "text 0,0 'Event #${COUNT} ${CTIME} #${PADRUNCOUNT}/${IMAGECOUNT}'" -undercolor black $f

        done;

        # Output a new line to clear status line, only if we processed something
        #[ $RUNCOUNT -gt 0 ] && echo -ne "\r" && echo -ne "\033[2K"

        # Now make the gif image
        GIFNAME="${REQDATE}_Event-${EVENTNUMBER}_${STARTTIME}-${ENDTIME}.gif";
        MP4NAME="${REQDATE}_Event-${EVENTNUMBER}_${STARTTIME}-${ENDTIME}.mp4";
        PREVIEWNAME="${REQDATE}_Preview-${EVENTNUMBER}_${STARTTIME}-${ENDTIME}.gif";
        [ ! -d "$PROCESSEDDIR/$COUNT" ] && mkdir "$PROCESSEDDIR/$COUNT";

        #[ $IMAGECOUNT -gt 0 ] && mv $IMAGEFILES "$PROCESSEDDIR/$COUNT";
        if [ $IMAGECOUNT -gt 0 ]; then
            echo -ne "\r\033[2KBuilding MP4 $MP4NAME\r"
            mv $IMAGEFILES "$PROCESSEDDIR/$COUNT";
            ffmpeg -y -loglevel 16 -framerate 5 -pattern_type glob -i "${PROCESSEDDIR}/${COUNT}/*.jpg" -c:v libx264 -vf "fps=30,format=yuv420p" "${OUTPUTDIR}/${MP4NAME}"
            
            echo -ne "\r\033[2KBuilding GIF Preview ${PREVIEWNAME}\r"
            convert -resize 200x150 -delay 50 `find "${PROCESSEDDIR}/${COUNT}/" -type f -iname '*.jpg' | sort | head -10` -loop 0 "${OUTPUTDIR}/${PREVIEWNAME}";
        fi

        # Move cursor up one line
        echo -ne "\033[1A";

    done;

    # Now build the entire day into a single video...
    # Create a list.txt file with each file on a line, prefixed with "file "
    echo "Building All Events into single video file"
    MP4NAME="${REQDATE}_All_Events.mp4";

    # If the full day file already exists, remove it so we can update it again, incase mid-day build was run
    [ -f "${MP4NAME}" ] && rm "${MP4NAME}"
    find "${OUTPUTDIR}" -size +100k -iname '*_Event-*.mp4' | sort -n -t- -k2 | awk '{ print "file "$0 }' > "${OUTPUTDIR}/fflist.txt"
    ffmpeg -y -f concat -i "${OUTPUTDIR}/fflist.txt" -c copy "${OUTPUTDIR}/${MP4NAME}"
}

########################################################################
# Add global CAPTURESECONDS to $1 as a timestamp
#
# e.g. if $1 is 105920 and add 120, we get 110120
#
# @param int $1 The time in form HHMMSS
########################################################################
add_seconds() {
    STARTTIME=$1;
    
    HOUR=${STARTTIME:0:2};
    MIN=${STARTTIME:2:2};
    SEC=${STARTTIME:4:2};

    INC=$CAPTURESECONDS;

    HOURADD=$(expr $INC / 3600);
    INC=$(expr $INC - $HOURADD \* 3600);
    MINADD=$(expr $CAPTURESECONDS / 60);
    INC=$(expr $INC - $MINADD \* 60);
    SECADD=$INC;

    ENDSEC=$(expr $SEC + $SECADD);
    [ $ENDSEC -ge 60 ] && ENDSEC=$(expr $ENDSEC - 60) && (( MINADD += 1 ));

    ENDMIN=$(expr $MIN + $MINADD);
    [ $ENDMIN -ge 60 ] && ENDMIN=$(expr $ENDMIN - 60) && (( HOURADD += 1 ));

    ENDHOUR=$(expr $HOUR + $HOURADD);
    [ $ENDHOUR -ge 23 ] && ENDHOUR=23 && ENDMIN=59 && ENDSEC=59   # Crossing midnight but oh well...camera motion track breaks anyway

    ENDTIME=$(printf %02d $ENDHOUR $ENDMIN $ENDSEC);
}

#######################
# Progress bar from
# https://github.com/fearside/ProgressBar/
# Modified to show a custom message

######################
function ProgressBar {
    # Process data
        let _progress=(${1}*100/${2}*100)/100
        let _done=(${_progress}*4)/10
        let _left=40-$_done
        #let _msg="\"${3}\""


    # Build progressbar string lengths
        _done=$(printf "%${_done}s")
        _left=$(printf "%${_left}s")

    # 1.2 Build progressbar strings and print the ProgressBar line
    # 1.2.1 Output example:
    # 1.2.1.1 Progress : [########################################] 100%
    printf "\r${3} Progress : [${_done// /#}${_left// /-}] ${_progress}%%"

}



# Main exec
main
