#!/usr/bin/env python
# -*- coding: utf-8 -*-

##
## CGI script to use Tenjin as PHP-like tool.
##
## setup:
##
##    $ tar xzf Tenjin-X.X.X.tar.gz
##    $ cd Tenjin-X.X.X/
##    $ cp lib/tenjin.py ~/public_html/
##    $ cd public_html/
##    $ cp pytenjin.cgi .htaccess *.pyhtml ~/public_html/
##    $ chmod a+x ~/public_html/pytenjin.cgi
##    $ cat ~/public_html/.htaccess
##    RewriteEngine on
##    RewriteRule \.(py|pyhtml|cache)$ - [R=404,L]
##    RewriteCond %{SCRIPT_FILENAME} !-f
##    RewriteRule \.html$ pytenjin.cgi
##    RewriteRule ^$ pytenjin.cgi
##    RewriteRule /$ pytenjin.cgi
##
##
## $Release: $
## $Copyright: copyright(c) 2007-2010 kuwata-lab.com all rights reserved. $
## $License: MIT License $
##

import sys
import os
import re

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3

encoding = 'utf-8'
headers = {}
debug = os.environ.get('SERVER_ADDR') == '::1'   # set debug mode true when on localhost

def h(val):
    return str(val).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;')


class HttpError(Exception):

  def __init__(self, status, text, headers=None):
      Exception.__init__(self, "%s: %s" % (status, text))
      self.status  = status
      self.text    = text
      self.headers = headers


try:

    import tenjin
    from tenjin.helpers import *
    from tenjin.helpers.html import *

    kwargs = {}
    if os.path.isfile('_layout.pyhtml'):
        kwargs['layout'] = '_layout.pyhtml'
    kwargs['cache'] = False   # set True for perfomance
    #kwargs['preprocess'] = True
    engine = tenjin.SafeEngine(**kwargs)   # or tenjin.Engine(**kwargs)

    ## simulate CGI in command-line to debug your *.rbhtml file
    #os.environ['SCRIPT_NAME'] = '/A/B/pytenjin.cgi'
    #os.environ['REQUEST_URI'] = '/A/B/hello.html'

    ## get script name and request path
    script_name = os.environ.get('SCRIPT_NAME')    # ex. '/A/B/pytenjin.cgi'
    if not script_name:
        raise HttpError('500 Internal Error', "ENV['SCRIPT_NAME'] is not set.")
    req_uri     = os.environ.get('REQUEST_URI')    # ex. '/A/B/C/foo.html?x=1'
    if not req_uri:
        raise HttpError('500 Internal Error', "ENV['REQUEST_URI'] is not set.")
    req_path = req_uri.split('?', 1)[0]            # ex. ('/A/B/C/foo.html', 'x=1')

    ## deny direct access to pytenjin.cgi
    if req_path == script_name:
        raise HttpError('403 Forbidden', "#{req_path}: not accessable.")

    ## assert request path
    base_path = os.path.dirname(script_name)       # ex. '/A/B'
    assert req_path.startswith(base_path)

    ## normalize request path and redirect if necessary
    req_path2 = req_path
    req_path2 = req_path2.replace(r'\\', '/')      # ex. '\A\B\C' -> '/A/B/C'
    req_path2 = re.sub(r'//+', '/', req_path2)     # ex. '/A///B//C' -> '/A/B/C'
    #while True:
    #    s = re.sub(r'/[^\/]+/\.\./', '/', req_path2)  # ex. '/A/../B' -> '/B'
    #    if s == req_path2: break
    #    req_path2 = s
    if req_path != req_path2:
        raise HttpError.new('302 Found', req_path2, {'Location': req_path2})

    ## if file_path is a directory, add 'index.html'
    file_path = req_path[len(base_path)+1:]        # ex. 'C/foo.html'
    if not file_path:                              # access to root dir
        file_path = "index.html"
    elif os.path.isdir(file_path):                 # access to directory
        assert file_path[-1] == '/'
        file_path += "index.html"

    ## request validation
    if not file_path.endswith('.html'):            # expected '*.html'
        raise HttpError('500 Internal Error', 'invalid .htaccess configuration.')
    template_path = re.sub(r'\.html$', '.pyhtml', file_path)
    if not os.path.isfile(template_path):          # file not found
        raise HttpError('404 Not Found', "%s: not found." % req_path)
    if os.path.basename(template_path)[0] == '_':  # deny access to '_*' (ex. _layout.rbhtml)
        raise HttpError('403 Forbidden', "%s: not accessable." % req_path)

    ## render template
    output = engine.render(template_path)
    if python2:
        if isinstance(output, unicode):
            output = output.encode(encoding)
    elif python3:
        pass  # TODO:

except HttpError:
    ex = sys.exc_info()[1]
    w = sys.stdout.write
    w("Status: %s\r\n" % (h(ex.status), ))
    w("Content-Type: text/html\r\n")
    if ex.headers:
        for k in ex.headers:
            w("%s: %s\r\n" % (k, ex.headers[k]))
    w("\r\n")
    w("<h1>%s</h1>\n" % (h(ex.status), ))
    w("<p>%s</p>\n" % (h(ex.text), ))

except Exception:
    ex = sys.exc_info()[1]
    sys.stderr.write("*** %s: %s\n" % (ex.__class__.__name__, str(ex)))
    import traceback
    traceback.print_exc(file=sys.stderr)
    w = sys.stdout.write
    w("Status: 500 Internal Error\r\n")
    w("Content-Type: text/html\r\n")
    w("\r\n")
    w("<h1>500 Internal Error</h1>\n")
    if debug:
        w("<h3>%s: %s</h3>\n" % (h(ex.__class__.__name__), h(str(ex))))
        w("<style type=\"text/css\">\n")
        w("  pre.backtrace { font-size: large; }\n")
        #w("  span.from { color: #933; }\n")
        #w("  span.line { color: #333; }\n")
        #w("  span.first { font-weight: bold; font-size: x-large; }\n")
        w("</style>\n")
        w("<pre class=\"backtrace\">\n")
        traceback.print_exc(file=sys.stdout)
        w("</pre>\n")

else:
    ## print response header and body
    w = sys.stdout.write
    if headers.get('Status'):
        w("Status: %s\r\n" % (headers.pop('Status'), ))
    for k in headers:
        w("%s: %s\r\n" % (k, headers[k]))
    if not headers.get('Content-Type'):
        w("Content-Type: text/html\r\n")
    if not headers.get('Content-Length'):
        w("Content-Length: %s\r\n" % len(output))
    w("\r\n")
    w(output)
