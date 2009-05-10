<?php
$testdir = dirname(__FILE__);
$basedir = dirname($testdir);
set_include_path(get_include_path() . PATH_SEPARATOR . $basedir);

///if (! extension_loaded('syck')) {
///    //$extdir = '/usr/local/lib/php/extensions/no-debug-non-zts-20050922';
///    if (dl('syck.so')) {
///        // OK
///    } elseif (dl("$extdir/syck.so")) {
///       // OK
///    } else {
///        die('cannot load syck extension.');
///    }
///}

require_once 'PHPUnit2/Framework/TestCase.php';


class TenjinDocumentTest_ extends PHPUnit2_Framework_TestCase {

    var $currdir = null;

    function setup() {
        $this->currdir = getcwd();
        $s = $this->getName();
        //if (preg_match('/^test_faq_/', $s, $m)) {
        //    chdir("data/faq");
        //}
        if (preg_match('/^test_(users_guide|faq|examples_([a-zA-Z0-9]+))/', $s, $m)) {
            if (isset($m[2])) {
                chdir("data/examples/{$m[2]}");
            }
            else {
                chdir("data/{$m[1]}");
            }
        }
    }

    function tearDown() {
        chdir($this->currdir);
    }

    function assertTextEqual($expected, $actual) {
        tenjin_assert_text_equals($expected, $actual);
    }

    function _test($filename) {
        $s = file_get_contents($filename);
        preg_match('/^\$ (.*?)\n/', $s, $m);
        $command = $m[1];
        $expected = substr($s, strlen($m[0]));
        $actual = `$command`;
        $actual = preg_replace('/(\/\w+)+\/Tenjin\.php/', '/usr/local/lib/php/Tenjin.php', $actual);
        $actual = preg_replace('/(T_ECHO in ).*\/(ex2\.phtml\.cache)/', '$1/home/tmp/$2', $actual);
        $this->assertTextEqual($expected, $actual);
    }

}


function tenjin_assert_text_equals($expected, $actual) {
    if ($expected != $actual) {
        //$tmpdir = php_get_tmpdir();
        $tmpdir = ".";
        $expected_filename = $tmpdir . "/.expected";
        $actual_filename   = $tmpdir . "/.actual";
        file_put_contents($expected_filename, $expected);
        file_put_contents($actual_filename,   $actual);
        ob_start();
        system("diff -u {$expected_filename} {$actual_filename}");
        $result = ob_get_clean();
        unlink($expected_filename);
        unlink($actual_filename);
        $preamble = "--- expected\n+++ actual\n";
        $result = preg_replace('/\A.*\n.*\n/', $preamble, $result);
        //$this->fail($result);
        PHPUnit2_Framework_Assert::fail($result);
    } else {
        PHPUnit2_Framework_Assert::assertEquals($expected, $actual);
    }
}


///function tenjin_load_testdata($filename, $untabify=true) {
///    $filename = preg_replace('/\.php$/', '.yaml', $filename);
///    $str = file_get_contents($filename);
///    if ($untabify) $str = tenjin_untabify($str);
///    $testdata_list = syck_load($str);
///    $table = array();   // hash
///    foreach ($testdata_list as $testdata) {
///        if (! array_key_exists('name', $testdata))
///            die("*** {$filename}: key 'name' is not found.");
///        $name = $testdata['name'];
///        if (array_key_exists($name, $table))
///            die("*** {$filename}: name '{$name}' is duplicated.");
///        $table[$name] = $testdata;
///    }
///    return $testdata_list;
///}
///
///
///function tenjin_select_testdata($testdata, $lang) {
///    $list = array();
///    foreach ($testdata as $data) {
///        foreach ($data as $key => $val) {
///            if ($key[strlen($key)-1] == '*') {
///                unset($data[$key]);
///                $key = substr($key, 0, strlen($key)-1);
///                $l = _tenjin_is_special_key($key) ? 'php' : $lang;
///                $val = $val[$l];
///                $data[$key] = $val;
///            }
///        }
///        $list[] = $data;
///    }
///    return $list;
///}
///
///
///function tenjin_build_testmethods($testdata, $classname, $parent_classname=null) {
///    if (! $parent_classname)
///        $parent_classname = $classname . '_';
///    $sb = array();
///    $sb[] = "class {$classname} extends {$parent_classname} {\n";
///    foreach ($testdata as $data) {
///        $sb[] =     "  function test_{$data['name']}(){\n";
///        foreach ($data as $key=>$val) {
///            $val = preg_replace('/\{\{\*|\*\}\}/', '', $val);
///            $expr = var_export($val, true);
///            $sb[] = "    \$this->{$key} = {$expr};\n";
///        }
///        $sb[] =     "    \$this->_test();\n";
///        $sb[] =     "  }\n";
///    }
///    $sb[] = "}\n";
///    return join($sb);
///}
///
///
///function tenjin_define_testmethods($testdata, $classname) {
///    $code = tenjin_build_testmethods($testdata, $classname);
///    eval($code);
///}
///
///
///function _tenjin_is_special_key($key) {
///    return $key == 'exception' || $key == 'errormsg';
///}
///
///
///function tenjin_build_testmethods_with_each_lang($testdata, $classname, $langs=null, $parent_classname=null) {
///    if (! $langs)
///        $langs = array('php', 'eruby', 'jstl', 'eperl');
///    if (! $parent_classname)
///        $parent_classname = $classname . '_';
///    $sb = array();
///    $sb[] = "class {$classname} extends {$parent_classname} {\n\n\n";
///    foreach ($langs as $lang) {
///        foreach ($testdata as $data) {
///            $sb[] =     "  function test_{$data['name']}_{$lang}(){\n";
///            $sb[] =     "    \$this->lang = '{$lang}';\n";
///            foreach ($data as $key=>$val) {
///                if ($key[strlen($key)-1] == '*') {
///                    $key = substr($key, 0, strlen($key)-1);
///                    $l = _tenjin_is_special_key($key) ? 'php' : $lang;
///                    $val = $val[$l];
///                }
///                $val = preg_replace('/\{\{\*|\*\}\}/', '', $val);
///                $expr = var_export($val, true);
///                $sb[] = "    \$this->{$key} = {$expr};\n";
///            }
///            $sb[] =     "    \$this->_test();\n";
///            $sb[] =     "  }\n";
///            $sb[] =     "\n\n";
///        }
///    }
///    $sb[] = "}\n";
///    return join($sb);
///}
///
///
///function tenjin_define_testmethods_with_each_lang($testdata, $classname, $langs=null) {
///    if (! $langs)
///        $langs = array('php', 'eruby', 'jstl');
///    $code = tenjin_build_testmethods_with_each_lang($testdata, $classname, $langs);
///    eval($code);
///}
///

error_reporting(E_ALL);


?>
