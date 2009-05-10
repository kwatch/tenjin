<?php
$data = array();
while (($line = fgets(STDIN)) !== false) {
    if (preg_match('/([-\w]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/', $line, $m)) {
        $name = $m[1];
        if (! isset($data[$name])) $data[$name] = array();
        $data[$name][] = array(floatval($m[2]), floatval($m[3]), floatval($m[4]), floatval($m[5]));
    }
}

printf("%20s%10s %10s %10s %10s\n", ' ', 'user', 'sys', 'total', 'real');
foreach ($data as $name=>$tuples) {
    //var_export($item);
    $utime = $stime = $total = $real = 0.0;
    foreach ($tuples as $tuple) {
        $utime += $tuple[0];
        $stime += $tuple[1];
        $total += $tuple[2];
        $real  += $tuple[3];
    }
    //printf("%-20s%10.4f %10.4f %10.4f %10.4f\n", $name, $utime, $stime, $total, $real);
    //printf("%-20s%10.4f %10.4f %10.4f %10.4f\n", $name, $utime/10.0, $stime/10.0, $total/10.0, $real/10.0);
    printf("%-20s%8.2f00 %8.2f00 %8.2f00 %10.4f\n", $name, $utime/10.0, $stime/10.0, $total/10.0, $real/10.0);
}
?>