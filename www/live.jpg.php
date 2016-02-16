<?php
/**
 * Proxy for connecting to camera on local network & passing through data to outside
*/ 
$conf = parse_config();

$base_url = "http://{$conf['CAM_USER']}:{$conf['CAM_PASS']}@{$conf['CAM_HOST']}";
$image_url = "{$base_url}/tmpfs/auto.jpg?r=" . time();


$data = file_get_contents($image_url);


header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

header("Content-type: image/jpeg");

echo $data;


/**
 * Return key/value pairs from bash-style config
*/
function parse_config() {
    $file = realpath(dirname(__FILE__) . '/../camera.conf');
    if (!file_exists($file)) {
        throw new exception ("Could not locate config file at {$file}");
    }
    
    $data = file_get_contents($file);
    $data = explode("\n", $data);
    $conf = array();
    foreach($data as $line) {
        if (!strstr($line, "="))
            continue;
        list($key, $value) = explode("=", $line);
        //Strip " ' from beginning and end of line
        $replacements = array(
            "/^(\"|\')/", 
            "/(\"|\')$/", 
        );
        $v = preg_replace($replacements, '', $value);
        if (strlen($key) < 0 || strlen($v) < 0)
            continue;

        $conf[$key] = $v;
    }

    return $conf;
}