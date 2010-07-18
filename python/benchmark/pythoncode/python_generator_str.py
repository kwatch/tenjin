def _gen(list):
  yield '''<?xml version="1.0" encoding="UTF-8"?>
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
   <tbody>\n'''

  n = 0
  for item in list:
    n += 1

    yield '''    <tr class="'''; yield str(n % 2 == 0 and 'even' or 'odd'); yield '''">
     <td style="text-align: center">'''; yield str(n); yield '''</td>
     <td>
      <a href="/stocks/'''; yield str(item.symbol); yield '''">'''; yield str(item.symbol); yield '''</a>
     </td>
     <td>
      <a href="'''; yield str(item.url); yield '''">'''; yield str(item.name); yield '''</a>
     </td>
     <td>
      <strong>'''; yield str(item.price); yield '''</strong>
     </td>\n''';
    if item.change < 0.0:
        yield '''     <td class="minus">'''; yield str(item.change); yield '''</td>
     <td class="minus">'''; yield str(item.ratio); yield '''</td>\n''';
    else:
        yield '''     <td>'''; yield str(item.change); '''</td>
     <td>'''; yield str(item.ratio); yield '''</td>\n''';
    #endif
    yield '''    </tr>\n''';

  #endfor

  yield '''   </tbody>
  </table>

 </body>
</html>\n''';
#output = _buf.join()
