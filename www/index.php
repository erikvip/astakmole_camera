<?php

    # Grab a list of all available videos
    $videos = `find ./data/ -iname '*.mp4'`;
    $videos = explode("\n", $videos);

    $events = array();
    $compilation = array();
    $counts = array();

    //Video line from find will look like this:
    //./data/20151211/output/20151211_Event-12_052841-052941.mp4
   
    foreach($videos as $v) { 
        if (substr_count($v, '/') < 2) 
            continue;

        list($null, $null, $day, $dir, $file) = explode("/", $v);


        
        if ($dir !== 'output') {
            continue;
        }

        list($day, $event, $time) = explode("_", strstr($file, '.', true));
        if ($event === 'All') {
            $compilation["{$day}"] = array(
                'event_number' => 0, 
                'file' => $file, 
                'day' => $day,
                'start_time' => '000000', 
                'end_time' => '115959'
            );
            continue;
        }

        list($null, $event_number) = explode('-', $event);
        list($start_time, $end_time) = explode('-', $time);

        if (!isset($events["{$day}"])) {
            $events["{$day}"] = array();
            $counts["{$day}"] = 0;
        }
        $counts["{$day}"]++;

        $events["{$day}"]["{$event_number}"] = array(
            'event_number' => $event_number, 
            'day' => $day, 
            'file' => $file, 
            'start_time' => $start_time, 
            'end_time' => $end_time
        );
    }

    //Now fix the sorting on all the event days
    ksort($events);
    foreach($events as $k=>$v) {
        ksort($events["$k"]);
    }

#print_r($events);

#exit;

?><!doctype html>
<html>
<body>
 
<div id="live">
    <img src="http://10.0.0.120/tmpfs/auto.jpg" alt="Live feed" />
</div>
<p id="livestatus">Live Image</p>


<video width="320" height="240" controls>
  <source src="data/20151214/output/20151214_All_Events.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

<script>
    
    update_live_image = function() {
        live=document.getElementById('live');
        liveimg = live.children[0];
        st = document.getElementById('livestatus')

        liveimg.onload=function() {
            src = liveimg.src;
            w = liveimg.width; 
            h = liveimg.height;

            window.setInterval(function() {
                var d = new Date();
                var time = d.getHours() + '-' + d.getMinutes() + '-' + d.getSeconds();
                liveimg.src = src + "?r=" + d.getTime();
                st.innerHTML='Updated at ' + time;
            }, 500);

        }
    };
    ready(update_live_image);

    //Window loaded
    function ready(fn) {
      if (document.readyState != 'loading'){
        fn();
      } else {
        document.addEventListener('DOMContentLoaded', fn);
      }
    }

</script>
</body>
</html>
