# RTSP connection setup

TWO tcp sockets are required.   

- The first is an HTTP GET channel which is the DATA channel.
- The second is an HTTP POST channel which acts as a CONTROL channel.

We will call these channels DATA and CONTROL respectively.   

- The DATA channels opens and sends an HTTP GET request, with a unique session cookie (The client makes it up. But it *must* match between DATA and CONTROL channels).   
- Must also contain the login data using standard HTTP Basic Authentication

## DATA socket initial request
```
    GET /iphone.mov HTTP/1.0
    User-Agent: QuickTime/7.7.6 (qtver=7.7.6;os=Windows NT 5.1Service Pack 3)
    x-sessioncookie: fEYfARF0AABeEgIABoAAAA
    Accept: application/x-rtsp-tunnelled
    Pragma: no-cache
    Cache-Control: no-cache
    Authorization: Basic YWRtaW46YWRtaW4=
```

The server responds immediately with an HTTP 200:   

### DATA socket initial response
```
    HTTP/1.0 200 OK
    Server: HiIpcam/V100R003 VodServer/1.0.0
    Connection: Close
    Cache-Control: no-store
    Pragma: no-cache
    Content-Type: application/x-rtsp-tunnelled
```

Now we open the CONTROL socket, and send an HTTP POST request for /iphone.mov. Note the Content-Length is guesstimated, since we don't know the full length...   

## CONTROL socket initial request
```
    POST /iphone.mov HTTP/1.0
    User-Agent: QuickTime/7.7.6 (qtver=7.7.6;os=Windows NT 5.1Service Pack 3)
    x-sessioncookie: fEYfARF0AABeEgIABoAAAA
    Content-Type: application/x-rtsp-tunnelled
    Pragma: no-cache
    Cache-Control: no-cache
    Authorization: Basic YWRtaW46YWRtaW4=
    Content-Length: 32767
    Expires: Sun, 9 Jan 1972 00:00:00 GMT
```

Now we immediately send the first CONTROL MESSAGE packet, containing the RTSP DESCRIBE command.
All CONTROL MESSAGES must be base64 encoded.   

## CONTROL socket message #1 (Describe):

RAW:   
```
REVTQ1JJQkUgcnRzcDovLzEwLjAuMC4xMjAvaXBob25lLm1vdiBSVFNQLzEuMA0KQ1NlcTogMQ0KQWNjZXB0OiBhcHBsaWNhdGlvbi9zZHANCkJhbmR3aWR0aDogNTEyMDAwDQpBY2NlcHQtTGFuZ3VhZ2U6IGVuLVVTDQpVc2VyLUFnZW50OiBRdWlja1RpbWUvNy43LjYgKHF0dmVyPTcuNy42O29zPVdpbmRvd3MgTlQgNS4xU2VydmljZSBQYWNrIDMpDQoNCg==
```

Decoded:   
```
    DESCRIBE rtsp://10.0.0.120/iphone.mov RTSP/1.0
    CSeq: 1
    Accept: application/sdp
    Bandwidth: 512000
    Accept-Language: en-US
    User-Agent: QuickTime/7.7.6 (qtver=7.7.6;os=Windows NT 5.1Service Pack 3)
```

Now, after about a 10 second delay, we should get an RTSP 200 ok, along with the resource info, on the DATA channel:   

### DATA socket Describe response (+10 seconds later):
```
    RTSP/1.0 200 OK
    Server: HiIpcam/V100R003 VodServer/1.0.0
    CSeq: 1
    Cache-Control: no-cache
    Content-length: 421
    Date: Wed, 5 Dec 2007 13:01:00 GMT
    Expires: Wed, 5 Dec 2007 13:01:00 GMT
    Content-Type: application/sdp
    Content-Base: rtsp://10.0.0.120/iphone.mov/

    v=0
    o=StreamingServer 3441443066 1110182530000 IN IP4 10.0.0.120
    s=\iphone.mov
    u=http:///
    e=admin@
    c=IN IP4 0.0.0.0
    b=AS:360
    t=0 0
    a=range:npt=now-
    a=control:*
    m=video 0 RTP/AVP 96
    b=AS:256
    a=rtpmap:96 H264/90000
    a=fmtp:96 packetization-mode=0;profile-level-id=4D400C;sprop-parameter-sets=Z0LgHtqCgPRA,aM48gA==
    a=control:trackID=3
    m=audio 0 RTP/AVP 8
    b=AS:64
    a=rtpmap:8 PCMA/8000/1
    a=control:trackID=4
```

As soon as the Describe response is received on the DATA Socket, we immediately send the first SETUP request on the CONTROL socket. Note there is **NO SPACING** or other delimiters between the first DESCRIBE and the SETUP command. Nor any other CONTROL messages (No delimiters at all...).   

## CONTROL socket message #2 (SETUP command. After receiving DESCRIBE reply):

RAW:   
```
U0VUVVAgcnRzcDovLzEwLjAuMC4xMjAvaXBob25lLm1vdi90cmFja0lEPTMgUlRTUC8xLjANCkNTZXE6IDINClRyYW5zcG9ydDogUlRQL0FWUC9UQ1A7dW5pY2FzdA0KeC1keW5hbWljLXJhdGU6IDENCngtdHJhbnNwb3J0LW9wdGlvbnM6IGxhdGUtdG9sZXJhbmNlPTIuOTAwMDAwDQpVc2VyLUFnZW50OiBRdWlja1RpbWUvNy43LjYgKHF0dmVyPTcuNy42O29zPVdpbmRvd3MgTlQgNS4xU2VydmljZSBQYWNrIDMpDQpBY2NlcHQtTGFuZ3VhZ2U6IGVuLVVTDQoNCg==
```

Decoded:   
```
    SETUP rtsp://10.0.0.120/iphone.mov/trackID=3 RTSP/1.0
    CSeq: 2
    Transport: RTP/AVP/TCP;unicast
    x-dynamic-rate: 1
    x-transport-options: late-tolerance=2.900000
    User-Agent: QuickTime/7.7.6 (qtver=7.7.6;os=Windows NT 5.1Service Pack 3)
    Accept-Language: en-US
```

Which should receive an immediate RTSP 200 response on the DATA channel with the stream info:   

### DATA socket Setup response (immediately after SETUP request on CONTROL channel):
```
    RTSP/1.0 200 OK
    Server: HiIpcam/V100R003 VodServer/1.0.0
    Cseq: 2
    Cache-Control: no-cache
    Session:: 85014289
    Date: Wed, 5 Dec 2007 13:01:00 GMT
    Expires: Wed, 5 Dec 2007 13:01:00 GMT
    Transport: RTP/AVP/TCP;unicast;interleaved=0-1;ssrc=000026E9
```

## **DELAY**   

Now, we wait about 20 seconds (17.55 to be exact). Why? Who knows why...but this delay seems to matter. YAY for QuickTime.   

After our 20 second nap, we can send the next SETUP request on the CONTROL channel:  

## CONTROL socket message #3 (SETUP command #2. +17.55 seconds after the first SETUP RESPONSE):

RAW:   
```
U0VUVVAgcnRzcDovLzEwLjAuMC4xMjAvaXBob25lLm1vdi90cmFja0lEPTQgUlRTUC8xLjANCkNTZXE6IDMNClRyYW5zcG9ydDogUlRQL0FWUC9UQ1A7dW5pY2FzdA0KeC1keW5hbWljLXJhdGU6IDENCngtdHJhbnNwb3J0LW9wdGlvbnM6IGxhdGUtdG9sZXJhbmNlPTIuOTAwMDAwDQpVc2VyLUFnZW50OiBRdWlja1RpbWUvNy43LjYgKHF0dmVyPTcuNy42O29zPVdpbmRvd3MgTlQgNS4xU2VydmljZSBQYWNrIDMpDQpBY2NlcHQtTGFuZ3VhZ2U6IGVuLVVTDQoNCg==
```

Decoded:   
```
    SETUP rtsp://10.0.0.120/iphone.mov/trackID=4 RTSP/1.0
    CSeq: 3
    Transport: RTP/AVP/TCP;unicast
    x-dynamic-rate: 1
    x-transport-options: late-tolerance=2.900000
    User-Agent: QuickTime/7.7.6 (qtver=7.7.6;os=Windows NT 5.1Service Pack 3)
    Accept-Language: en-US
```

And we get another immediate RTSP 200 Response on the DATA channel:   

### DATA socket Setup #2 response (immediately after 2nd SETUP response in CONTROL socket):   
```
    RTSP/1.0 200 OK
    Server: HiIpcam/V100R003 VodServer/1.0.0
    Cseq: 3
    Cache-Control: no-cache
    Session:: 85014289
    Date: Wed, 5 Dec 2007 13:01:00 GMT
    Expires: Wed, 5 Dec 2007 13:01:00 GMT
    Transport: RTP/AVP/TCP;unicast;interleaved=2-3;ssrc=000026B9
```

And now we can immediately send our next and final CONTROL MESSAGE, the PLAY command:   

## CONTROL socket message #4 (PLAY command, immediately after our 2nd SETUP response):

RAW:   
```
UExBWSBydHNwOi8vMTAuMC4wLjEyMC9pcGhvbmUubW92IFJUU1AvMS4wDQpDU2VxOiA0DQpSYW5nZTogbnB0PTAuMDAwMDAwLQ0KeC1wcmVidWZmZXI6IG1heHRpbWU9Mi4wMDAwMDANClVzZXItQWdlbnQ6IFF1aWNrVGltZS83LjcuNiAocXR2ZXI9Ny43LjY7b3M9V2luZG93cyBOVCA1LjFTZXJ2aWNlIFBhY2sgMykNCg0K
```

Decoded:   
```
    PLAY rtsp://10.0.0.120/iphone.mov RTSP/1.0
    CSeq: 4
    Range: npt=0.000000-
    x-prebuffer: maxtime=2.000000
    User-Agent: QuickTime/7.7.6 (qtver=7.7.6;os=Windows NT 5.1Service Pack 3)
```

Which should get another RTSP 200 response on the DATA channel:      

## DATA socket Play response (immediately after PLAY request on CONTROL socket):
```
    RTSP/1.0 200 OK
    Server: HiIpcam/V100R003 VodServer/1.0.0
    Cseq: 4
    Session: 85014289
    Range: npt=now-
    RTP-Info: url=rtsp://10.0.0.120/iphone.mov/trackID=3;seq=0;rtptime=2533734208,url=rtsp://10.0.0.120/iphone.mov/trackID=4;seq=0;rtptime=988770560
```

And now our RTSP stream starts playing. Yay. We leave both DATA and CONTROL open. The CONTROL channel is left open (I guess), so we can send STOP commands and stuff...I haven't captured that yet.
