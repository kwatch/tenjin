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
import tenjin
from tenjin.helpers import *
from tenjin.helpers.html import *
h = tenjin.helpers.html.escape_html

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3

encoding = 'utf-8'
headers = {}
#debug = os.environ.get('SERVER_ADDR') == '::1'   # set debug mode true when on localhost
debug = 'HTTP_X_FORWARDED_FOR' not in os.environ and \
        os.environ.get('SERVER_ADDR') == os.environ.get('REMOTE_ADDR')
#debug = True


class HttpError(Exception):

  def __init__(self, status, text, headers=None):
      Exception.__init__(self, "%s: %s" % (status, text))
      self.status  = status
      self.text    = text
      self.headers = headers


class TenjinApp(object):

    encoding = 'utf-8'
    engineclass = tenjin.SafeEngine    # or tenjin.Engine
    engineopts = {
        'cache': False,          # set True for performance
        'preprocess': False,
    }

    def __init__(self, encoding='utf-8', engineclass=None, engineopts=None):
        if engineclass is not None:
            self.engineclass = engineclass
        self.engineopts = opts = self.__class__.engineopts.copy()
        if engineopts:
            opts.merge(engineopts)
        if 'layout' not in opts and os.path.isfile('_layout.pyhtml'):
            opts['layout'] = '_layout.pyhtml'
        self.engine = self.engineclass(**opts)
        self.status = '200 OK'
        self.headers = { 'Content-Type': 'text/html; charset=%s' % self.encoding }

    def _script_name(self, env):
        ## get script name and request path
        script_name = env.get('SCRIPT_NAME')    # ex. '/A/B/pytenjin.cgi'
        if not script_name:
            raise HttpError('500 Internal Error', "ENV['SCRIPT_NAME'] is not set.")
        return script_name

    def _request_path(self, env):
        req_uri = env.get('REQUEST_URI')        # ex. '/A/B/C/foo.html?x=1'
        if not req_uri:
            raise HttpError('500 Internal Error', "ENV['REQUEST_URI'] is not set.")
        req_path  = req_uri.split('?', 1)[0]    # ex. ('/A/B/C/foo.html', 'x=1')
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

    def main(self, env):
        ## simulate CGI in command-line to debug your *.rbhtml file
        env['SCRIPT_NAME'] = '/A/B/pytenjin.cgi'
        env['REQUEST_URI'] = '/A/B/hello.html'
        ## get request info
        script_name = self._script_name(env)           # ex. '/A/B/pytenjin.cgi'
        req_path    = self._request_path(env)          # ex. '/A/B/hello.html'
        ## deny direct access to pytenjin.cgi
        if req_path == script_name:
            raise HttpError('403 Forbidden', "#{req_path}: not accessable.")
        ## template file path
        file_path = self._file_path(req_path, script_name)   # ex. 'hello.pyhtml'
        if not file_path.endswith('.html'):            # expected '*.html'
            raise HttpError('500 Internal Error', 'invalid .htaccess configuration.')
        template_path = re.sub(r'\.html$', '.pyhtml', file_path)
        if not os.path.isfile(template_path):          # file not found
            raise HttpError('404 Not Found', "%s: not found." % req_path)
        if os.path.basename(template_path)[0] == '_':  # deny access to '_*' (ex. _layout.rbhtml)
            raise HttpError('403 Forbidden', "%s: not accessable." % req_path)
        ## context object
        context = {
            'self': self,
        }
        ## render template
        output = self.engine.render(template_path, context)
        return output

    def __call__(self, env, start_response):
        self.env = env
        self.start_response = start_response
        try:
            output = self.main(env)
            if python2:
                if isinstance(output, unicode):
                    output = output.encode(self.encoding)
            elif python3:
                #if isinstance(output, str):
                #    output = output.encode(self.encoding)
                sys.stderr.write("\033[0;31m*** debug: type(output)=%r\033[0m\n" % (type(output), ))
            headers = [ (k, self.headers[k]) for k in self.headers ]
            if not self.headers.get('Content-Length'):
                headers.append(('Content-Length', str(len(output))))
            self.start_response(self.status, headers)
            return [output]
        except HttpError:
            ex = sys.exc_info()[1]
            return self.handle_http_error(ex)
        except Exception:
            ex = sys.exc_info()[1]
            return self.handle_exception(ex)

    def handle_http_error(self, ex):
        buf = []; a = buf.append
        a("<h1>%s</h1>\n" % h(ex.status))
        a("<p>%s</p>\n" % h(ex.text))
        output = ''.join(buf)
        d = ex.headers
        headers = d and [ (k, d[k]) for k in d ] or []
        headers.append(('Content-Type', 'text/html'))
        start_response(ex.status, headers)
        return [output]

    def handle_exception(self, ex):
        sys.stderr.write("*** %s: %s\n" % (ex.__class__.__name__, str(ex)))
        import traceback
        traceback.print_exc(file=sys.stderr)
        buf = []; a = buf.append
        a("<h1>500 Internal Server Error</h1>\n")
        if debug:
            a("<h3>%s: %s</h3>\n" % (h(ex.__class__.__name__), h(str(ex))))
            a("<style type=\"text/css\">\n")
            a("  pre.backtrace { font-size: large; }\n")
            #a("  span.from { color: #933; }\n")
            #a("  span.line { color: #333; }\n")
            #a("  span.first { font-weight: bold; font-size: x-large; }\n")
            a("</style>\n")
            a("<pre class=\"backtrace\">\n")
            traceback.print_exc(file=sys.stdout)
            a("</pre>\n")
        output = ''.join(buf)
        headers = [('Content-Type', 'text/html')]
        self.start_response("500 Internal Server Error", headers)
        return [output]


if __name__ == '__main__':
    from wsgiref.handlers import CGIHandler
    app = TenjinApp()
    CGIHandler().run(app)
