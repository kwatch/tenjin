_buf = []; _extend = _buf.extend; _extend(('''<?xml version="1.0" encoding="UTF-8"?>
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
   <tbody>\n''', ));

n = 0
for item in list:
    n += 1

    _extend(('''    <tr class="''', to_str(n % 2 == 0 and 'even' or 'odd').replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;'), '''">
     <td style="text-align: center">''', to_str(n).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;'), '''</td>
     <td>
      <a href="/stocks/''', to_str(item.symbol).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;'), '''">''', to_str(item.symbol).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;'), '''</a>
     </td>
     <td>
      <a href="''', to_str(item.url).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;'), '''">''', to_str(item.name).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;'), '''</a>
     </td>
     <td>
      <strong>''', to_str(item.price).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;'), '''</strong>
     </td>\n''', ));
    if item.change < 0.0:
        _extend(('''     <td class="minus">''', to_str(item.change).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;'), '''</td>
     <td class="minus">''', to_str(item.ratio).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;'), '''</td>\n''', ));
    else:
        _extend(('''     <td>''', to_str(item.change).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;'), '''</td>
     <td>''', to_str(item.ratio).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;'), '''</td>\n''', ));
    #endif
    _extend(('''    </tr>\n''', ));

#endfor

_extend(('''   </tbody>
  </table>

 </body>
</html>\n''', ));
output = ''.join(_buf)
