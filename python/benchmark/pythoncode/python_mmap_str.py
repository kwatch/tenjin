#import yaml
#ydoc = yaml.load(open('bench_context.yaml'))
#class StockInfo:
#    def __init__(self, name, name2, url, symbol, price, change, ratio):
#        self.name   = name
#        self.name2  = name2
#        self.url    = url
#        self.symbol = symbol
#        self.price  = price
#        self.change = change
#        self.ratio  = ratio
#
#list = [StockInfo(**hash) for hash in ydoc['list']]
#import mmap
#map_ = mmap.mmap(-1, 4096, mmap.MAP_ANONYMOUS)
#_buf = mmap.mmap(-1, 8096);
_buf.write('''<?xml version="1.0" encoding="UTF-8"?>
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
   <tbody>\n''');

n = 0
for item in list:
    n += 1

    _buf.write('''    <tr class="'''); _buf.write(str(n % 2 == 0 and 'even' or 'odd')); _buf.write('''">
     <td style="text-align: center">'''); _buf.write(str(n)); _buf.write('''</td>
     <td>
      <a href="/stocks/'''); _buf.write(str(item.symbol)); _buf.write('''">'''); _buf.write(str(item.symbol)); _buf.write('''</a>
     </td>
     <td>
      <a href="'''); _buf.write(str(item.url)); _buf.write('''">'''); _buf.write(str(item.name)); _buf.write('''</a>
     </td>
     <td>
      <strong>'''); _buf.write(str(item.price)); _buf.write('''</strong>
     </td>\n''');
    if item.change < 0.0:
        _buf.write('''     <td class="minus">'''); _buf.write(str(item.change)); _buf.write('''</td>
     <td class="minus">'''); _buf.write(str(item.ratio)); _buf.write('''</td>\n''');
    else:
        _buf.write('''     <td>'''); _buf.write(str(item.change)); _buf.write('''</td>
     <td>'''); _buf.write(str(item.ratio)); _buf.write('''</td>\n''');
    #endif
    _buf.write('''    </tr>\n''');

#endfor

_buf.write('''   </tbody>
  </table>

 </body>
</html>\n''');
_buflen = _buf.tell();
_buf.seek(0);
output = _buf.read(_buflen);
_buf.seek(0);
