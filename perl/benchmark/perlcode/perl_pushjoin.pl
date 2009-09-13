#@ARGS list
my @_buf = (); push(@_buf, q`<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
 <head>
  <title>Stock Prices</title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta http-equiv="Content-Style-Type" content="text/css" />
  <meta http-equiv="Content-Script-Type" content="text/javascript" />
  <link rel="shortcut icon" href="/images/favicon.ico" />
  <link rel="stylesheet" type="text/css" href="/css/style.css" media="all" />
  <script type="text/javascript" src="/js/util.js"></script>
  <style type="text/css">
  /*<![CDATA[*/

body {
    color: #333333;
    line-height: 150%;
}

thead {
    font-weight: bold;
    background-color: #CCCCCC;
}

.odd {
    background-color: #FFCCCC;
}

.even {
    background-color: #CCCCFF;
}

.minus {
    color: #FF0000;
}

  /*]]>*/
  </style>

 </head>

 <body>

  <h1>Stock Prices</h1>

  <table>
   <thead>
    <tr>
     <th>#</th><th>symbol</th><th>name</th><th>price</th><th>change</th><th>ratio</th>
    </tr>
   </thead>
`, ); my $list = $_context->{list}; 
push(@_buf, q`   <tbody>
`, ); 
my $n = 0;
for my $item (@$list) {
    $n += 1;

push(@_buf, q`    <tr class="`,  $n % 2 == 0 ? 'even' : 'odd' , q`">
     <td style="text-align: center">`,  $n , q`</td>
     <td>
      <a href="/stocks/`,  $item->{symbol} , q`">`,  $item->{symbol} , q`</a>
     </td>
     <td>
      <a href="`,  $item->{url} , q`">`,  $item->{name} , q`</a>
     </td>
     <td>
      <strong>`,  $item->{price} , q`</strong>
     </td>
`, );     if ($item->{change} < 0.0) {
push(@_buf, q`     <td class="minus">`,  $item->{change} , q`</td>
     <td class="minus">`,  $item->{ratio} , q`</td>
`, );     } else {
push(@_buf, q`     <td>`,  $item->{change} , q`</td>
     <td>`,  $item->{ratio} , q`</td>
`, );     }
push(@_buf, q`    </tr>
`, ); 
}

push(@_buf, q`   </tbody>
  </table>

 </body>
</html>
`, ); join('', @_buf);
