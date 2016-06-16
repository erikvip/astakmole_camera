TWO tcp sockets are required. 

The first is an HTTP GET channel which is the DATA channel.
The second is an HTTP POST channel which acts as a CONTROL channel.

We will call these channels DATA and CONTROL respectively. 

- The DATA channels opens and sends an HTTP GET request, with a unique session cookie (The client makes it up. But it *must* match between DATA and CONTROL channels).   

	GET /iphone.mov HTTP/1.0
	User-Agent: QuickTime/7.6.4 (qtver=7.6.4;os=Windows NT 5.1Service Pack 3)
	x-sessioncookie: byZGRM+UAABg+ScHCIAAAA
	Accept: application/x-rtsp-tunnelled
	Pragma: no-cache
	Cache-Control: no-cache
	Authorization: Basic YWRtaW46YWRtaW4=


