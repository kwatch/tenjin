<?php

error_reporting(E_ALL);

/*
 * utility
 */

function usage($command) {
    $s = <<<END
Usage: $command [..options..] testname
  -h, --help  : help
  -n N        : loop N times
  -p          : print result

END;
    return $s;
}

function include_in_sandbox($filename, $context) {
    extract($context);
    include($filename);
}

function init_array_keys_by_chars($str, $val=null) {
    $arr = array();
    for ($i = 0; $i < strlen($str); $i++) {
        $ch = substr($str, $i, 1);
        $arr[$ch] = null;
    }
    return $arr;
}

function load_datafile($_filename) {
    eval(file_get_contents($_filename));
    return $context;
    //$_data = get_defined_vars();
    //unset($_data['_fileame']);
    //return $_data;
}

//function load_yaml_file($filename) {
//    /// load yaml parser
//    $syck_so = '/usr/local/lib/php/extensions/no-debug-non-zts-20060613/syck.so';
//    if (! extension_loaded('syck')) {
//        if (! dl('syck.so')) {   // or dl('/some/where/to/syck.so')
//            die('cannot load syck extension.');
//        }
//    }
//    /// parse yaml file and create context data
//    $s = file_get_contents('bench_context.yaml');
//    $context = syck_load($s);
//    return $context;
//}


/*
 * parse argv
 */
function parse_args($argc, $argv, $noargopts='', $argopts='') {
    $options = init_array_keys_by_chars($noargopts . $argopts);
    $properties = array();
    for ($i = 1; $i < $argc; $i++) {
        if (substr($argv[$i], 0, 1) != '-')
            break;
        $optstr = $argv[$i];
        if ($optstr == '-') {
            $i++;
            break;
        }
        elseif (preg_match('/^--([-\w]+)(=(.*))?/', $optstr, $m)) {
            $name = $m[1];
            $value = array_key_exists(2, $m) && $m[2] ? $m[3] : true;
            $properties[$name] = $value;
        }
        else {
            $optstr = substr($optstr, 1);
            while ($optstr) {
                $ch = substr($optstr, 0, 1);
                $optstr = substr($optstr, 1);
                if (strpos("hp", $ch) !== false) {
                    $options[$ch] = true;
                }
                elseif (strpos("n", $ch) !== false) {
                    if     ($optstr)       $options[$ch] = $optstr;
                    elseif (++$i < $argc)  $options[$ch] = $argv[$i];
                    else throw "-$ch: argument required.";
                    break;
                }
                else {
                    throw "-$ch: unknown option.";
                }
            }
        }
    }
    $filenames = array_slice($argv, $i);
    return array($options, $properties, $filenames);
}


/*
 *  main
 */
function main($argc, $argv) {
    /// parse args
    $tuple = parse_args($argc, $argv, "hp", "n");
    $options    = $tuple[0];
    $properties = $tuple[1];
    $filenames  = $tuple[2];

    /// help
    $command = basename($argv[0]);
    if ($options['h'] || array_key_exists('help', $properties)) {
        echo usage($command);
        return 0;
    }

    /// set values
    $ntimes = $options['n'] ? (0 + $options['n']) : 1000;
    if (! $filenames) {
        //$filenames = split(' ', 'tenjin tenjin_reuse smarty smarty_reuse php php_nobuf');
        $filenames = split(' ', 'tenjin tenjin_reuse smarty smarty_reuse php');
    }

    /// load context data
    //$context = load_yaml_file('bench_context.yaml');
    $context = load_datafile('bench_context.php');
    //var_export($context);

    /// create smarty template
    $templates = array();
    $templates['smarty'] = 'bench_smarty.tpl';
    $s = '{literal}'
       . file_get_contents('templates/_header.html')
       . '{/literal}'
       . file_get_contents("templates/_".$templates['smarty'])
       . file_get_contents('templates/_footer.html');
    file_put_contents("templates/".$templates['smarty'], $s);

    /// create php template file
    $templates['php'] = 'templates/bench_php.php';
    $s = file_get_contents('templates/_header.html')
       . file_get_contents('templates/_bench_php.php')
       . file_get_contents('templates/_footer.html');
    $s = preg_replace('/^<\?xml/', '<<?php ?>?xml', $s);
    file_put_contents($templates['php'], $s);

    /// create php template file
    $templates['tenjin'] = 'templates/bench_tenjin.phtml';
    $s = file_get_contents('templates/_header.html')
       . file_get_contents('templates/_bench_tenjin.phtml')
       . file_get_contents('templates/_footer.html');
    file_put_contents($templates['tenjin'], $s);

    /// load smarty library
    //define('SMARTY_DIR', '/usr/local/lib/php/Smarty/');
    $flag_smarty = @include_once('Smarty.class.php');

    /// load tenjin library
    $flag_tenjin = @include_once('Tenjin.php');

    /// invoke benchmark function
    fprintf(STDERR, "*** ntimes=$ntimes\n");
    fprintf(STDERR, "%-20s%10s %10s %10s %10s\n", ' ', 'user', 'system', 'total', 'real');
    foreach ($filenames as $name) {
        if (preg_match('/smarty/', $name) && !$flag_smarty ||
            preg_match('/tenjin/', $name) && !$flag_tenjin) {
            fprintf(STDERR, "%-20s   (not installed)\n", $name);
            continue;
        }

        $func = 'bench_' . preg_replace('/-/', '_', $name);
        $key = null;
        foreach (array('smarty', 'tenjin', 'php') as $s) {
            if (strpos($name, $s) !== false) {
                $key = $s;
                break;
            }
        }
        if (! array_key_exists($key, $templates)) {
            throw new Exception("$name: invalid target.");
        }
        //
        $filename = $templates[$key];
        $start_microtime = microtime(true);
        $start_time = posix_times();
        $output = $func($ntimes, $filename, $context);
        $stop_time = posix_times();
        $stop_microtime = microtime(true);
        //
        $utime = ($stop_time['utime'] - $start_time['utime'])/100.0;
        $stime = ($stop_time['stime'] - $start_time['stime'])/100.0;
        $total = $utime + $stime;
        $real  = $stop_microtime - $start_microtime;
        //
        fprintf(STDERR, "%-20s%10.5f %10.4f %10.4f %10.4f\n", $name, $utime, $stime, $total, $real);
        //
        if ($options['p']) {
            file_put_contents("output.$name", $output);
        }
    }

    return 0;
}


/*
 *  benchmark functions
 */

function bench_smarty($ntimes, $filename, $context) {
    $output = null;
    for ($i = 0; $i < $ntimes; $i++) {
        $smarty = new Smarty;            // create smarty object
        foreach ($context as $k=>$v) {
            $smarty->assign($k, $v);     // assign context data
        }
        ob_start();
        $smarty->display($filename);     // render template
        $output = ob_get_contents();
        ob_end_clean();
    }
    return $output;
}

function bench_smarty_nobuf($ntimes, $filename, $context) {
    for ($i = 0; $i < $ntimes; $i++) {
        $smarty = new Smarty;            // create smarty object
        foreach ($context as $k => $v) {
            $smarty->assign($k, $v);     // assign context data
        }
        $smarty->display($filename);     // render template
    }
    return null;
}

function bench_smarty_reuse($ntimes, $filename, $context) {
    $output = null;
    $smarty = new Smarty;            // create smarty object
    foreach ($context as $k => $v) {
        $smarty->assign($k, $v);     // assign context data
    }
    for ($i = 0; $i < $ntimes; $i++) {
        ob_start();
        $smarty->display($filename);     // render template
        $output = ob_get_contents();
        ob_end_clean();
    }
    return $output;
}

function bench_php($ntimes, $filename, $context) {
    $output = null;
    for ($i = 0; $i < $ntimes; $i++) {
        ob_start();
        //include($filename);
        include_in_sandbox($filename, $context);
        $output = ob_get_contents();
        ob_end_clean();
    }
    return $output;
}

function bench_php_nobuf($ntimes, $filename, $context) {
    $output = null;
    $list = $context['list'];
    for ($j = 0; $j < $ntimes; $j++) {
        //ob_start();
        include($filename);
        //include_in_sandbox($filename);
        $output = ob_get_contents();
        //ob_end_clean();
    }
    return null;
}

function bench_tenjin($ntimes, $filename, $context) {
    $output = null;
    for ($i = 0; $i < $ntimes; $i++) {
        $engine = new Tenjin_Engine();
        $output = $engine->render($filename, $context);
        //$template = new Tenjin_Template($filename);
        //$output = $template->render($context);
    }
    return $output;
}

function bench_tenjin_reuse($ntimes, $filename, $context) {
    $output = null;
    $engine = new Tenjin_Engine();
    //$template = new Tenjin_Template($filename);
    for ($i = 0; $i < $ntimes; $i++) {
        $output = $engine->render($filename, $context);
        //$output = $template->render($context);
    }
    return $output;
}

function bench_tenjin2($ntimes, $filename, $context) {
    $output = null;
    for ($i = 0; $i < $ntimes; $i++) {
        $template = new Tenjin_Template2($filename);
        $output = $template->render($context);
    }
    return $output;
}

function bench_tenjin2_reuse($ntimes, $filename, $context) {
    $output = null;
    $template = new Tenjin_Template2($filename);
    for ($i = 0; $i < $ntimes; $i++) {
        $output = $template->render($context);
    }
    return $output;
}


/*
 *  invoke main program
 */
main($argc, $argv);

?>
