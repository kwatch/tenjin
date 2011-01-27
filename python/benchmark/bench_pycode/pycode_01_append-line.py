## name: 
## desc: append (line)
_buf = []; _buf.append('<?xml version="1.0" encoding="UTF-8"?>\n');
_buf.append('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n');
_buf.append('          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n');
_buf.append('<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n');
_buf.append(' <head>\n');
_buf.append('  <title>Stock Prices</title>\n');
_buf.append('  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />\n');
_buf.append('  <meta http-equiv="Content-Style-Type" content="text/css" />\n');
_buf.append('  <meta http-equiv="Content-Script-Type" content="text/javascript" />\n');
_buf.append('  <link rel="shortcut icon" href="/images/favicon.ico" />\n');
_buf.append('  <link rel="stylesheet" type="text/css" href="/css/style.css" media="all" />\n');
_buf.append('  <script type="text/javascript" src="/js/util.js"></script>\n');
_buf.append('  <style type="text/css">\n');
_buf.append('  /*<![CDATA[*/\n');
_buf.append('\n');
_buf.append('body {\n');
_buf.append('    color: #333333;\n');
_buf.append('    line-height: 150%;\n');
_buf.append('}\n');
_buf.append('\n');
_buf.append('thead {\n');
_buf.append('    font-weight: bold;\n');
_buf.append('    background-color: #CCCCCC;\n');
_buf.append('}\n');
_buf.append('\n');
_buf.append('.odd {\n');
_buf.append('    background-color: #FFCCCC;\n');
_buf.append('}\n');
_buf.append('\n');
_buf.append('.even {\n');
_buf.append('    background-color: #CCCCFF;\n');
_buf.append('}\n');
_buf.append('\n');
_buf.append('.minus {\n');
_buf.append('    color: #FF0000;\n');
_buf.append('}\n');
_buf.append('\n');
_buf.append('  /*]]>*/\n');
_buf.append('  </style>\n');
_buf.append('\n');
_buf.append(' </head>\n');
_buf.append('\n');
_buf.append(' <body>\n');
_buf.append('\n');
_buf.append('  <h1>Stock Prices</h1>\n');
_buf.append('\n');
_buf.append('  <table>\n');
_buf.append('   <thead>\n');
_buf.append('    <tr>\n');
_buf.append('     <th>#</th><th>symbol</th><th>name</th><th>price</th><th>change</th><th>ratio</th>\n');
_buf.append('    </tr>\n');
_buf.append('   </thead>\n');
_buf.append('   <tbody>\n');

n = 0
for item in items:
    n += 1

    _buf.append('    <tr class="'); _buf.append(n % 2 and 'odd' or 'even'); _buf.append('">\n');
    _buf.append('     <td style="text-align: center">'); _buf.append(str(n)); _buf.append('</td>\n');
    _buf.append('     <td>\n');
    _buf.append('      <a href="/stocks/'); _buf.append(item.symbol); _buf.append('">'); _buf.append(item.symbol); _buf.append('</a>\n');
    _buf.append('     </td>\n');
    _buf.append('     <td>\n');
    _buf.append('      <a href="'); _buf.append(item.url); _buf.append('">'); _buf.append(item.name); _buf.append('</a>\n');
    _buf.append('     </td>\n');
    _buf.append('     <td>\n');
    _buf.append('      <strong>'); _buf.append(item.s_price); _buf.append('</strong>\n');
    _buf.append('     </td>\n');
    if item.change < 0.0:
        _buf.append('     <td class="minus">'); _buf.append(item.s_change); _buf.append('</td>\n');
        _buf.append('     <td class="minus">'); _buf.append(item.s_ratio); _buf.append('</td>\n');
    else:
        _buf.append('     <td>'); _buf.append(item.s_change); _buf.append('</td>\n');
        _buf.append('     <td>'); _buf.append(item.s_ratio); _buf.append('</td>\n');
    #endif
    _buf.append('    </tr>\n');

#endfor

_buf.append('   </tbody>\n')
_buf.append('  </table>\n')
_buf.append('\n')
_buf.append(' </body>\n')
_buf.append('</html>\n');
_result = ''.join(_buf)
