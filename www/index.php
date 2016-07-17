<?php

    # Grab a list of all available videos
    $videos = `find ./data/ -iname '*.mp4' | sort -n -t- -k2`;
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
        $day_ts = DateTime::createFromFormat("Ymd", $day)->format('U');
        if ($event === 'All') {
            $compilation["{$day}"] = array(
                'event_number' => 0, 
                'file' => $file, 
                'day' => $day,
                'day_ts' => $day_ts,
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

        
        $start_ts = DateTime::createFromFormat("Ymd His", "{$day} {$start_time}")->format('U');
        $end_ts = DateTime::createFromFormat("Ymd His", "{$day} {$end_time}")->format('U');

        $events["{$day}"]["{$event_number}"] = array(
            'event_number' => $event_number, 
            'day' => $day, 
            'day_ts' => $day_ts,
            'file' => $file, 
            'start_time' => $start_time, 
            'start_time_ts' => $start_ts,
            'end_time' => $end_time, 
            'end_time_ts' => $end_ts,
            'filesize' => filesize($file_path),
            'filepath' => $file_path
        );
    }

    //Now fix the sorting on all the event days
    krsort($events);
    foreach($events as $k=>$v) {
        ksort($events["$k"]);
    }

    # Generate table body for a list of camera events
    function generate_event_list_table($day) {
        $html = "
            <table class='events'>
                <thead>
                    <th>Preview</th>
                    <th>Info</th>
                </thead>
                <tbody>
        ";

        foreach($day as $number=>$e) {
            $fmt = "g:i:s a";
            $start = date($fmt, $e['start_time_ts']);
            $end = date($fmt, $e['end_time_ts']);
            $preview = str_replace("Event", "Preview", $e['filepath']);
            $preview = str_replace(".mp4", ".gif", $preview);
/*
            $html .= "
                <tr>
                    <td><a class='show-video' href='javascript:void(0);' data-file='{$e['filepath']}' title='{$e['file']}'>{$e['file']}</a></td>
                    <td>{$number}</td>
                    <td>{$start} - {$end}</td>
                    <td>" . human_filesize($e['filesize']) . "</td>
                    <td><img src='{$preview}' /></td>
                </tr>
*/                
            
            $html .= "
                <tr>
                    <td class='preview'><a class='show-video' href='javascript:void(0);' data-file='{$e['filepath']}' title='{$e['file']}'><img src='{$preview}' /></a></td>
                    <td>
                        <a class='show-video' href='javascript:void(0);' data-file='{$e['filepath']}' title='{$e['file']}'>
                        <b>Event #{$number}</b><br />
                        <b>Time: </b>{$start} - {$end}<br />
                        <b>Size: " . human_filesize($e['filesize']) . "</b><br />
                        {$e['file']}</a>
                    </td>
                </tr>
            ";
        }
        $html .= "</tbody></table>";
        return $html;
    }



?><!doctype html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=2" />
    <meta name="viewport" content="width=420,initial-scale=1, maximum-scale=1">
<style>
    .desktop #leftcol {
        width: 640px;
    }
    .desktop #live {
        margin: 12px 0 0 0;
        width: 640px;
        height: 480px;
    }
    .phone #liveimg {
        width: 320px;
        height: 20px;
    }
    .phone .livefixed {
        position: fixed;
        bottom: 5px;
        left: 32px;
        height: 240px !important;
    }
    .desktop #page {
        overflow: scroll;
        position: fixed;
        top: 0;
        right: 0;
        bottom: 0;
        left: 640px;
    }
    table.events {
        width: 100%;
    }
    body.phone #video {
        display: none;
        position: fixed;
        z-index: 10000;
        left: 32px;
        top: 30%;
        
        /* give it dimensions */
        width: 320px;
        height: 240px;
        
    }
/*
    body.desktop #video {
        float: left;
        height: 480px;
        width: 640px;
        margin: 12px 40px;
    }
*/
    body.dim #video {
        display: block;
    }

    #video #close-btn img {
        width: 48px;
        height: 48px;
        position: absolute;
        top: -30px;
        left: -30px;
    }

    body.dim {
        background-color: #000;
    }
    body.dim #page {
        opacity: 0.4;
    }

    .desktop table.events td.preview {
        width: 220px;
    }

    ul#camera-dates {
        list-style-type: none;
        clear: both;
    }
    ul#camera-dates li {
        border: 1px solid #333;
        margin: 4px 0;
        padding: 4px 16px;
        width: 75%;
    }
    .phone ul#camera-dates { padding: 0; }
    .phone ul#camera-dates li { width: 80%; }
    ul#camera-dates li a {
        color: #111;
        text-decoration: none;
    }
    ul#camera-dates li a:hover {
        text-decoration: underline;
        color: #333;
    }
</style>
</head>
<body>
    <div id="leftcol">
        <div id="video">
            <video width="320" height="240" controls>
              <source src="data/20151214/output/20151214_All_Events.mp4" type="video/mp4">
              Your browser does not support the video tag.
            </video>
        </div>
        <div id="live">
            <a href="javascript:void(0);" onClick="show_live_feed();"><img id="liveimg" src="blank.jpg" alt="Click to load live image" /></a>
            <p id="livestatus">Live Image</p>
        </div>
    </div>


<div id="page">
    <ul id="camera-dates">
        <?php
             foreach($events as $day=>$e) {
                $total = count($e);
                $day_ts = $compilation["$day"]['day_ts'];
                $title = "<b>{$day}</b> - " . date("D, F jS Y", $day_ts) . " - ${total} events";
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


<script>

    addCls = function(className, element) {
        if (element.classList)
            element.classList.add(className);
        else
            element.className += ' ' + className;
    }
   
    detect_mobile = function() {
        var isPhone = function() {
          var check = false;
          (function(a){if(/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i.test(a)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0,4)))check = true})(navigator.userAgent||navigator.vendor||window.opera);
          return check;
        }

        b = document.body;
        if (!isPhone()) {
            addCls('desktop', b);
            window.isPhone = false;
        } else {
            addCls('phone', b);
            window.isPhone = true;
        }
    };
    ready(detect_mobile);

    update_live_image = function() {
        liveimg = document.getElementById('liveimg');
        livestatus = document.getElementById('livestatus');
        src = liveimg.src;
        liveimg.onload=function() {
            w = liveimg.width; 
            h = liveimg.height;
            var d = new Date();

            window.setTimeout(function() {
                liveimg.src = src + "?r=" + (d.getTime()+1);
                livestatus.innerHTML='Updated at ' + (d.getHours() + ':' + d.getMinutes() + ':' + d.getSeconds())
            }, 500);
        }
    };

    //We don't call update_live_image when page is loading, because
    //It slows down everything if camera is lagging...
    //So now we load page & wait for user to click on live image, if they wish to view it from the 'historical' page anyway
    function show_live_feed() {
        var liveimg = document.getElementById('liveimg');
        if ( liveimg.alt != 'Live Image' ) {
            liveimg.src='live.jpg.php';
            liveimg.alt = "Live Image";
            update_live_image();
            window.pokecount=0;
            if (window.isPhone == true) addCls('livefixed', liveimg);

        } else {
            if (window.pokecount++>5) document.getElementById('livestatus').innerHTML='Stop poking me!!!';
            if (window.isPhone == true) liveimg.classList.remove('livefixed');
        }
    }
    show_event_date = function() {
        video = document.getElementById('#video');
        ul = document.getElementById('camera-dates');
        li = ul.querySelectorAll('li');
        Array.prototype.forEach.call(li, function(el, i){
            link = el.querySelectorAll('a')[0];
            
            link.addEventListener('click', function() {
                div = el.querySelectorAll('div.day')[0];    
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
        width = 320;
        height = 240;
        container = document.getElementById('video');
        video = container.querySelectorAll('video source')[0];
        f = el.dataset.file;

        if (!window.isPhone) {
            width = 640;
            height = 480;
        }
        html = '<video width="'+width+'" height="'+height+'" controls autoplay><source src="'+f+'" type="video/mp4"> Your browser does not support the video tag.</video><a href="javascript:void(0);" id="close-btn"><img src="static/close.png" alt="Close" /></a>';
        //video.innerHTML = video;
        container.innerHTML=html;
        closebtn = container.querySelectorAll('a#close-btn')[0];

        closebtn.addEventListener('click', function() {
            bodycls = document.body.classList.remove('dim');
        });

        b = document.body;
        if (window.isPhone) {
            className='dim';
            if (b.classList)
                b.classList.add(className);
            else
                b.className += ' ' + className;
        }

    }
    Array.prototype.remove = function() {
        var what, a = arguments, L = a.length, ax;
        while (L && this.length) {
            what = a[--L];
            while ((ax = this.indexOf(what)) !== -1) {
                this.splice(ax, 1);
            }
        }
        return this;
    };


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