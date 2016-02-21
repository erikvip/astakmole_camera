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

        $file_path = "data/{$day}/output/{$file}";

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
            'end_time' => $end_time, 
            'filesize' => filesize($file_path),
            'filepath' => $file_path
        );
    }

    //Now fix the sorting on all the event days
    ksort($events);
    foreach($events as $k=>$v) {
        ksort($events["$k"]);
    }

    # Generate table body for a list of camera events
    function generate_event_list_table($day) {
        $html = "
            <table class='events'>
                <thead>
                    <th>File</th>
                    <th>Event Number</th>
                    <th>Start Time - End Time</th>
                    <th>File Size</th>
                </thead>
                <tbody>
        ";

        foreach($day as $number=>$e) {
            $html .= "
                <tr>
                    <td><a class='show-video' href='javascript:void(0);' data-file='{$e['filepath']}' title='{$e['file']}'>{$e['file']}</a></td>
                    <td>{$number}</td>
                    <td>{$e['start_time']} - {$e['end_time']}</td>
                    <td>" . human_filesize($e['filesize']) . "</td>
                </tr>
            ";
        }
        $html .= "</tbody></table>";
        return $html;
    }



?><!doctype html>
<html>
<style>
    #live {
        width: 640px;
        height: 480px;
    }
    table.events {
        width: 100%;
    }
    #video {
        display: none;
        position: fixed;
        z-index: 10000;
        right: 0;
        left: 0;
        top: 0;
        bottom: 0;
        margin: auto;
        
        /* give it dimensions */
        height: 240px;
        width: 320px;
    }
    body.dim #video {
        display: block;
    }

    body.dim {
        background-color: #000;
    }
    body.dim #page {
        opacity: 0.4;
    }
</style>
<body>
<div id="page">
    <div id="live">
        <img src="live.jpg.php" alt="Live feed" />
    </div>
    <p id="livestatus">Live Image</p>

    <ul id="camera-dates">
        <?php
            foreach($events as $day=>$e) {
                $total = count($e);
                $title = "{$day} - ${total} events";
                echo "
                    <li>
                        <a href='javascript:void(0);' title='{$title}'>{$title}</a>
                        <div style='display:none' class='day'>
                            " . generate_event_list_table($e) . "
                        </div>
                    </li>";
            }
        ?>
    </ul>
</div>

<div id="video">
    <video width="320" height="240" controls>
      <source src="data/20151214/output/20151214_All_Events.mp4" type="video/mp4">
      Your browser does not support the video tag.
    </video>
</div>

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

    show_event_date = function() {
        video = document.getElementById('#video');
        ul = document.getElementById('camera-dates');
        li = ul.querySelectorAll('li');
        Array.prototype.forEach.call(li, function(el, i){
            link = el.querySelectorAll('a')[0];
            div = el.querySelectorAll('div.day')[0];
            link.addEventListener('click', function() {
                div.style.display = (div.style.display=='none') ?  '' : 'none';
            })
        });

        e = ul.querySelectorAll('li div table td a.show-video');
        Array.prototype.forEach.call(e, function(el, i){
            el.addEventListener('click', function() {
                show_video(el);
            })
        });
    }
    ready(show_event_date); 

    //Window loaded
    function ready(fn) {
      if (document.readyState != 'loading'){
        fn();
      } else {
        document.addEventListener('DOMContentLoaded', fn);
      }
    }

    function show_video(el) {
        container = document.getElementById('video');

        video = container.querySelectorAll('video source')[0];


        f = el.dataset.file;
        html = '<video width="320" height="240" controls><source src="'+f+'" type="video/mp4"> Your browser does not support the video tag.</video>';
        //video.innerHTML = video;
        container.innerHTML=html;
        //video.src = f;
        b = document.body;

        console.log(video);

        className='dim';
        if (b.classList)
            b.classList.add(className);
        else
            b.className += ' ' + className;

    }

</script>
</body>
</html>

<?php

# Helper functions

function human_filesize($bytes, $decimals = 2) {
  $sz = 'BKMGTP';
  $factor = floor((strlen($bytes) - 1) / 3);
  return sprintf("%.{$decimals}f", $bytes / pow(1024, $factor)) . @$sz[$factor];
}