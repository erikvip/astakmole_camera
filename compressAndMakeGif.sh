#!/bin/bash

############################################################################################
# Convert all the JPG's in the Camera directory into an animated gif
#
# Works in conjunction with the camera server.sh & motiondetect.sh scripts
#
# Expects a date, in the form YYYYMMDD, which should be found under $IMGDIR and $LOGDIR
# We parse the log file to find the start of the motion
############################################################################################

# Config. No trailing slash on directories
CAPTURESECONDS=120;
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

    EVENTS=$(egrep -o '[0-9]{6}$' ${LOGFILE});
    EVENTCOUNT=$(egrep -c '[0-9]{6}$' ${LOGFILE});

    # Finished gif's are moved into output, while images used are moved to processed
    OUTPUTDIR="$IMGDIR/output";
    PROCESSEDDIR="$IMGDIR/processed";
    [ ! -d "$OUTPUTDIR" ] && mkdir $OUTPUTDIR;
    [ ! -d "$PROCESSEDDIR" ] && mkdir $PROCESSEDDIR;

    COUNT=0;
    for e in $EVENTS; do
        (( COUNT += 1))
        
        # STARTTIME and ENDTIME get set in add_seconds
        add_seconds $e $CAPTURESECONDS
        WILDCARD="${STARTTIME}..${ENDTIME}";
        WILDCARD="$IMGDIR/{$WILDCARD}.jpg";
        
        IMAGEFILES=$(eval ls $WILDCARD 2> /dev/null);
        IMAGECOUNT=$(eval ls $WILDCARD 2> /dev/null | wc -l);

        TOTALDONE=$(echo $COUNT / $EVENTCOUNT \* 100 | bc -l | xargs printf %0.1f);

        echo "Start event #${COUNT} of ${EVENTCOUNT}. Overall: ${TOTALDONE}% done.";

        RUNCOUNT=0;
        for f in $IMAGEFILES; do
            (( RUNCOUNT += 1 ))
            FILETIME=$(basename $f | cut -d. -f1);

            # bc doesn't work here due to floating point precision
            PERDONE=$(echo $RUNCOUNT / $IMAGECOUNT \* 100 | bc -l | xargs printf %0.1f );
            CTIME="${REQDATE:0:4}-${REQDATE:4:2}-${REQDATE:6:2} ${FILETIME:0:2}:${FILETIME:2:2}:${FILETIME:4:2}";
            PADRUNCOUNT=$(printf %02d $RUNCOUNT);
            echo "Processing Event #${COUNT} (${e}) File: $FILETIME ${RUNCOUNT} of ${IMAGECOUNT} ${PERDONE}% done ...";

            #mogrify -fill white -gravity NorthEast -pointsize 28 -draw "text 0,0 '${CTIME}'" -undercolor black -compress JPEG -quality 8 -strip $f
            #mogrify -fill white -gravity NorthEast -pointsize 28 -draw "text 0,0 '${CTIME}'" -undercolor black -compress JPEG -quality 1 -strip $f
            mogrify -fill white -gravity NorthEast -pointsize 28 -draw "text 0,0 'Event #${COUNT}/${EVENTCOUNT} ${CTIME} #${PADRUNCOUNT}/${IMAGECOUNT}'" -undercolor black $f
        done;

        # Now make the gif image
        GIFNAME="${REQDATE}_Event-${COUNT}_${STARTTIME}-${ENDTIME}.gif";
        [ ! -d "$PROCESSEDDIR/$COUNT" ] && mkdir "$PROCESSEDDIR/$COUNT";

        echo "Building GIF $GIFNAME ...";
        convert -delay 50 $IMAGEFILES -loop 0 "${OUTPUTDIR}/$GIFNAME" && mv $IMAGEFILES "$PROCESSEDDIR/$COUNT"

    done;
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
    [ $ENDHOUR -ge 23 ] && ENDHOUR=0;   # Crossing midnight but oh well...camera motion track breaks anyway

    ENDTIME=$(printf %02d $ENDHOUR $ENDMIN $ENDSEC);
}

# Main exec
main