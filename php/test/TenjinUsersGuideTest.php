<?php

///
/// $Rev$
/// $Release$
/// $Copyright$
///

require_once 'TenjinTest.inc';
require_once 'PHPUnit2/Framework/TestCase.php';

$files = array();
$files = array_merge($files,
                     glob('data/users_guide/*.result'),
                     glob('data/users_guide/*.sources'));

$buf = array();
$buf[] = "class TenjinUsersGuideTest extends TenjinDocumentTest_ {\n";
foreach ($files as $file) {
    $basename = basename($file);
    $s = preg_replace('/^data\//', '', $file);
    $s = preg_replace('/[^\w]/', '_', $s);
    $buf[] = "  function test_$s() {\n";
    $buf[] = "    \$this->_test('$basename');\n";
    $buf[] = "  }\n";
}

$buf[] = "\n}\n";
$classdef = join('', $buf);

//echo "*** classdef=$classdef";
eval($classdef);