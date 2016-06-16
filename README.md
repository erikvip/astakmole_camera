# Astak Mole Camera Recorder

This script will monitor a Astak Mole camera for motion events, and when detected, will capture a
video by grabbing a new image every second and display a desktop notification.   

Afterwards, it uses ffmpeg to build a video of the event from the still images, and also includes
an end-of-day processor to make one video of all the day's motion events. 

## Why not use the built in event recorder?

I inherited my Astak Mole camera from a friend, and the SD card reader was broken. Therefore I
could not record any motion events (kind of a required feature...). So I built this script to 
handle record motion events locally on my linux desktop.   

Also, besides the SD card issue, the Mole will only upload to an FTP server, or youtube...and who
the hell wants to run a lameo FTP server just for a camera?!    

## Features

- Uses the Mole's built in motion detector
- Records motion events using a series of still images, automatically builds an MP4 video
  - I tried animated GIF's initially, but the file size & processing time was ridiculous, so I switched to mp4 videos.
  - I think the animated GIF code is still there, just commented out.  But I wouldn't recommend using GIF's. 
- Also will build an end of day "summary" video containing all motion events. 
- Desktop notification when a new event is triggered. 
- Very basic HTTP browser for motion events, so you can view events remotely
  - The HTTP browser is very basic and still kind of a work in progress...though I doubt I'll be doing much more to it very soon. 
- Working on capturing the RTSP stream, instead of still jpeg images, so we can support sound.

## RTSP Live Video Stream

I'm working on making the RTSP viewer work in Linux / VLC and not require a dumbass Windows box 
just to view the live video stream. The Mole uses some weirdo RTSP stream that only QuickTime 
seems to support, VLC does not.   

It creates two TCP sockets (a control, and a data socket), and they just need to be opened in 
the right order, and *then* you can get to the normal RTSP stream which vlc does support...   

Clear documentation on this process (and authenticating) is almost non-existent.  But after 
studying network traffic, I figured it out & got it working in VLC.  However, I haven't automated
this process yet.  The procedure is documented in doc/rtsp.  It just needs a wrapper created to 
handle the connection setup, and then proxy it to a regular RTSP stream, or dump it to a video file,
or whatever...

## Usage

- Configure the Mole motion detection / email to send an email when a new motion event occurs. 
- **But** use your local machine for the SMTP server (the script starts recording whenever a connect on port 25/smtp is received)
- Copy **camera.conf-default** to **camera.conf** and update the URL and login info for the camera
- Run **server.sh**. It currently runs in the foreground, so you'll want to start it up in tmux or screen

This script is really rough at the moment, and does not clean up old files, so you may want to
setup a cron job to clear out old days under data/ and log/ or something...   

Works good for my purposes.  If you've got a Astak Mole camera, and would like to try it, I'd love to get some feedback!


