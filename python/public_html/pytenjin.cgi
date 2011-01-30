#!/usr/bin/env python
# -*- coding: utf-8 -*-

##
## CGI script to use Tenjin as PHP-like tool.
##
## setup:
##
##    $ tar xzf Tenjin-X.X.X.tar.gz
##    $ cd Tenjin-X.X.X/
##    $ cp lib/tenjin.py       ~/public_html/
##    $ cp public/pytenjin.cgi ~/public_html/
##    $ cp public/.htaccess    ~/public_html/
##    $ cp public/*.pyhtml     ~/public_html/
##    $ cd ~/public_html/
##    $ chmod a+x pytenjin.cgi
##    $ vi .htaccess   # edit '/~yourname/' and so on
##
##
## $Release: $
## $Copyright: copyright(c) 2007-2010 kuwata-lab.com all rights reserved. $
## $License: MIT License $
##

import sys, os
import tenjin
from tenjin.helpers import *
from tenjin.helpers.html import *
h = tenjin.helpers.html.escape_html

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3
if python3:
    unicode = str


class Config(object):

    encoding = 'utf-8'
    headers  = {}
    #debug = os.environ.get('SERVER_ADDR') == '::1'   # set debug mode true when on localhost
    debug = 'HTTP_X_FORWARDED_FOR' not in os.environ and \
            os.environ.get('SERVER_ADDR') == os.environ.get('REMOTE_ADDR')
    #debug = True
    tenjin_class = tenjin.SafeEngine    # or tenjin.Engine
    tenjin_options = {
        'layout':        '_layout.pyhtml',
        #'encoding':      encoding,
        'cache':         False,         # set True for performance
        'preprocess':    False,
    }

config = Config()

if config.encoding != 'utf-8':
    to_str = tenjin.generate_tostrfunc(encode=config.encoding)


class HttpError(Exception):

    def __init__(self, status, text, headers=None):
        Exception.__init__(self, "%s: %s" % (status, text))
        self.status  = status
        self.text    = text
        self.headers = headers


class TenjinApp(object):

    def __init__(self):
        self.engine = config.tenjin_class(**config.tenjin_options)
        self.status = '200 OK'
        self.headers = { 'Content-Type': 'text/html; charset=%s' % config.encoding }
        self.headers.update(config.headers)

    def _script_name(self, environ):
        ## get script name and request path
        script_name = environ.get('SCRIPT_NAME')   # ex. '/A/B/pytenjin.cgi'
        if not script_name:
            raise HttpError('500 Internal Server Error', "environ['SCRIPT_NAME'] is not set.")
        return script_name

    def _request_path(self, environ):
        req_uri = environ.get('REQUEST_URI')       # ex. '/A/B/C/foo.html?x=1'
        if not req_uri:
            raise HttpError('500 Internal Server Error', "environ['REQUEST_URI'] is not set.")
        req_path  = req_uri.split('?', 1)[0]       # ex. ('/A/B/C/foo.html', 'x=1')
        ## normalize request path and redirect if necessary
        normalized = os.path.normpath(req_path)
        if req_path[-1] == '/':
            normalized += '/'
        if req_path != normalized:
            #raise HttpError('404 Not Found', "%s: not found." % req_path)
            raise HttpError('302 Found', normalized, {'Location': normalized})
        return req_path

    def _file_path(self, req_path, script_name):
        base_path = os.path.dirname(script_name)       # ex. '/A/B'
        assert req_path.startswith(base_path)
        ## if file_path is a directory, add 'index.html'
        file_path = req_path[len(base_path)+1:]        # ex. 'C/foo.html'
        if not file_path:                              # access to root dir
            file_path = "index.html"
        elif os.path.isdir(file_path):                 # access to directory
            assert file_path[-1] == '/'
            file_path += "index.html"
        return file_path

    def main(self, environ):
        ## simulate CGI in command-line to debug your *.pyhtml file
        #environ['SCRIPT_NAME'] = '/A/B/pytenjin.cgi'
        #environ['REQUEST_URI'] = '/A/B/hello.html'
        ## get request info
        script_name = self._script_name(environ)       # ex. '/A/B/pytenjin.cgi'
        req_path    = self._request_path(environ)      # ex. '/A/B/hello.html'
        ## deny direct access to pytenjin.cgi
        if req_path == script_name:
            raise HttpError('403 Forbidden', "%s: not accessable." % req_path)
        ## template file path
        file_path = self._file_path(req_path, script_name)   # ex. 'hello.pyhtml'
        if not file_path.endswith('.html'):            # expected '*.html'
            raise HttpError('500 Internal Server Error', 'invalid .htaccess configuration.')
        template_path = file_path[:-5] + '.pyhtml'     # replace '.html' to '.pyhtml'
        if not os.path.isfile(template_path):          # file not found
            raise HttpError('404 Not Found', "%s: not found." % req_path)
        if os.path.basename(template_path)[0] == '_':  # deny access to '_*' (ex. _layout.pyhtml)
            raise HttpError('403 Forbidden', "%s: not accessable." % req_path)
        ## context object
        context = {
            'self': self,
        }
        ## render template
        output = self.engine.render(template_path, context)
        return output

    def __call__(self, environ, start_response):
        self.environ = environ
        #self.start_response = start_response
        try:
            return self._handle_request(environ, start_response)
        except HttpError:
            return self._handle_http_error(environ, start_response)
        except Exception:
            return self._handle_exception(environ, start_response)

    def _handle_request(self, environ, start_response):
        output = self.main(environ)
        if isinstance(output, unicode):
            output = output.encode(self.encoding)
        headers = [ (k, self.headers[k]) for k in self.headers ]
        if not self.headers.get('Content-Length'):
            headers.append(('Content-Length', str(len(output))))
        start_response(self.status, headers)
        return [output]

    def _handle_http_error(self, environ, start_response):
        ex = sys.exc_info()[1]
        ch = ex.status[0]
        if ch == '4' or ch == '5':   # 4xx or 5xx
            sys.stderr.write("*** [pytenjin.cgi] %s: %s\n" % (ex.status, ex.text))
        buf = []; a = buf.append
        a("<h1>%s</h1>\n" % h(ex.status))
        a("<p>%s</p>\n" % h(ex.text))
        output = ''.join(buf)
        d = ex.headers
        headers = d and [ (k, d[k]) for k in d ] or []
        headers.append(('Content-Type', 'text/html'))
        start_response(ex.status, headers)
        return [output]

    def _handle_exception(self, environ, start_response):
        ex = sys.exc_info()[1]
        sys.stderr.write("*** %s: %s\n" % (ex.__class__.__name__, str(ex)))
        import traceback
        lst = traceback.format_exception(*sys.exc_info())
        traceback_str = ''.join(lst)   # or traceback.format_exc()  # >=2.4
        sys.stderr.write(traceback_str)
        buf = []; a = buf.append
        a("<h1>500 Internal Server Error</h1>\n")
        if config.debug:
            a("<h3>%s: %s</h3>\n" % (h(ex.__class__.__name__), h(str(ex))))
            #a("<style type=\"text/css\">\n")
            #a("  pre.backtrace { font-size: large; }\n")
            #a("  span.from { color: #933; }\n")
            #a("  span.line { color: #333; }\n")
            #a("  span.first { font-weight: bold; font-size: x-large; }\n")
            #a("</style>\n")
            a("<pre class=\"backtrace\">\n")
            a(h(traceback_str))
            a("</pre>\n")
        output = ''.join(buf)
        headers = [('Content-Type', 'text/html')]
        start_response("500 Internal Server Error", headers)
        return [output]


if __name__ == '__main__':
    from wsgiref.handlers import CGIHandler
    app = TenjinApp()
    CGIHandler().run(app)
