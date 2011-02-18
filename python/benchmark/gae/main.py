#!/usr/bin/env python

###
### Benchmark Django v.s. Tenjin on Google App Engine
###
### without datastore:
###
###    $ ab -n 100 -c 5 'http://127.0.0.1:8080/django'
###    $ ab -n 100 -c 5 'http://127.0.0.1:8080/django?escape=1'
###    $ ab -n 100 -c 5 'http://127.0.0.1:8080/tenjin'
###    $ ab -n 100 -c 5 'http://127.0.0.1:8080/tenjin?escape=1'
###
### with datastore (before benchmark, access to http://localhost:8080/stocks/):
###
###    $ ab -n 100 -c 5 'http://127.0.0.1:8080/db/django'
###    $ ab -n 100 -c 5 'http://127.0.0.1:8080/db/django?escape=1'
###    $ ab -n 100 -c 5 'http://127.0.0.1:8080/db/tenjin'
###    $ ab -n 100 -c 5 'http://127.0.0.1:8080/db/tenjin?escape=1'
###
###
### $Release: $
### $Copyright: copyright(c) 2007-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re

USE_DJANGO_12 = True
#USE_DJANGO_12 = False

from google.appengine.dist import use_library
if USE_DJANGO_12:
    use_library('django', '1.2')
from google.appengine.ext import webapp, db
from google.appengine.ext.webapp import util

is_dev = os.environ.get('SERVER_SOFTWARE', '').startswith('Devel')

sys.path.insert(0, 'lib')

import logging
logger = logging.getLogger()
if is_dev:
    logger.setLevel(logging.DEBUG)


##
## context data
##
class Stock(db.Model):
    name    = db.StringProperty()
    name2   = db.StringProperty()
    url     = db.StringProperty()
    symbol  = db.StringProperty()
    price   = db.FloatProperty()
    change  = db.FloatProperty()
    ratio   = db.FloatProperty()
    created_at = db.DateTimeProperty(auto_now_add=True)
    updated_at = db.DateTimeProperty()
    #
    def is_minus(self):
        return self.change < 0.0

from bench_context import items as _items
for item in _items:
    item.minus_ = item.change < 0.0

class SimpleContext(object):
    def _context(self):
        return {'items': _items}

class DatastoreContext(object):
    def _context(self):
        return {'items': Stock.all().order('-price').fetch(100)}


##
## handler class to register context data into datastore
##
class StocksHandler(webapp.RequestHandler):

    def get(self):
        query = Stock.all()
        key = self.request.get('sort')
        if key:
            query = query.order(key)
        stocks = query.fetch(100)
        engine = tenjin.Engine(path=[os.path.dirname(__file__) + '/templates'])
        html = engine.render('stocks.pyhtml', {'items': stocks})
        self.response.out.write(html)

    def post(self):
        if self.request.get('submit_create'):
            logger.debug("\033[0;31m*** submit_create button pressed\033[0m\n")
            for item in _items:
                x = item
                stock = Stock(name=x.name, name2=x.name2, url=x.url, symbol=x.symbol,
                              price=x.price, change=x.change, ratio=x.ratio)
                stock.put()
        elif self.request.get('submit_clear'):
            logger.debug("\033[0;31m*** submit_cancel button pressed\033[0m\n")
            stocks = Stock.all().fetch(100)
            for stock in stocks:
                stock.delete()
        self.redirect('/stocks')


##
## null handler
##
class NotInstalled(webapp.RequestHandler):
    def get(self):
        self.response.out.write("<p>NOT INSTALLED</p>")


##
## index page
##
class IndexPage(webapp.RequestHandler):
    def get(self):
        w = self.response.out.write
        w(('<!doctype html>\n'
           '<html>\n'
           '<body>\n'
           '  <h2>Context Data Page</h2>\n'
           '  <p><a href="/stocks">Go to Context Data Page</a></p>\n'
           '  <h2>URLs for each template engine benchmark</h2>\n'
           '  <table>\n'
           '    <thead>\n'
           '      <td><b>No Escape</b></td>\n'
           '      <td><b>HTML Escape</b></td>\n'
           '      <td><b>Using Datastore</b></td>\n'
           '    </thead>\n'
           '    <tbody>\n'
           ))
        for path, klass in mappings:
            w(    '      <tr>\n')
            if klass is NotInstalled:
                w('        <td><s>%s</s>(not installed)</td>\n' % path)
                w('        <td><s>%s?escape=1</s>(not installed)</td>\n' % path)
            else:
                w('        <td><a href="%s">%s</td>\n' % (path, path))
                w('        <td><a href="%s?escape=1">%s?escape=1</td>\n' % (path, path))
            using_datastore = path.startswith('/db/') and 'Yes' or 'No'
            w(    '        <td>%s</td\n' % using_datastore)
            w(    '      </tr>\n')
        w(('    </tbody>\n'
           '  </table>\n'
           '</body>\n'
           '</html>\n'))


##
## Django
##
from google.appengine.ext.webapp import template
try:
    import django
    sys.stderr.write("*** django.VERSION=%r\n" % (django.VERSION, ))
except ImportError:
    sys.stderr.write("*** django not installed\n")
    django = None
    SimpleDjangoHandler = DatastoreDjangoHandler = NotInstalled
else:

    class DjangoHandler(webapp.RequestHandler):
        templates_dir = os.path.dirname(__file__) + '/templates'
        def get(self):
            flag_escape = self.request.get('escape')
            if USE_DJANGO_12:
                file_name = flag_escape and 'escape_django12.html' or 'bench_django12.html'
            else:
                file_name = flag_escape and 'escape_django.html' or 'bench_django.html'
            path = self.templates_dir + '/' + file_name
            #logger.info('** path=%r' % path)
            html = template.render(path, self._context())
            self.response.out.write(html)

    class SimpleDjangoHandler(DjangoHandler, SimpleContext):
        pass

    class DatastoreDjangoHandler(DjangoHandler, SimpleContext):
        pass


##
## Mako
##
try:
    import mako.template
    import mako.lookup
    sys.stderr.write("*** mako.__version__=%r\n" % (mako.__version__, ))
except ImportError:
    sys.stderr.write("*** mako not installed\n")
    mako = None
    SimpleMakoHandler = DatastoreMakoHandler = NotInstalled
else:

    class MakoHandler(webapp.RequestHandler):
        templates_path = os.path.dirname(__file__) + "/templates"
        #lookup = mako.lookup.TemplateLookup(directories=[templates_path], input_encoding='utf-8')
        lookup = mako.lookup.TemplateLookup(directories=[templates_path])
        def get(self):
            flag_escape = self.request.get('escape')
            file_name = flag_escape and "escape_mako.html" or "bench_mako.html"
            template = self.lookup.get_template(file_name)
            html = template.render_unicode(**self._context())
            self.response.out.write(html)

    class SimpleMakoHandler(MakoHandler, SimpleContext):
        pass

    class DatastoreMakoHandler(MakoHandler, DatastoreContext):
        pass


##
## Jinja2
##
try:
    import jinja2
    sys.stderr.write("*** jinja2.__version__=%r\n" % (jinja2.__version__, ))
except ImportError:
    sys.stderr.write("*** jinja2 not installed\n")
    jinja2 = None
    SimpleJinjaHandler = DatastoreJinjaHandler = NotInstalled
else:

    class Jinja2Handler(webapp.RequestHandler):
        templates_dir = os.path.dirname(__file__) + "/templates"
        loader = jinja2.FileSystemLoader([templates_dir], encoding="utf8")
        bench_env  = jinja2.Environment(loader=loader, autoescape=False)
        escape_env = jinja2.Environment(loader=loader, autoescape=True)
        def get(self):
            flag_escape = self.request.get('escape')
            file_name = flag_escape and 'escape_jinja2.html' or 'bench_jinja2.html'
            env = flag_escape and self.escape_env or self.bench_env
            #logger.info('** file_name=%r' % file_name)
            template = env.get_template(file_name)
            html = template.render(self._context())
            self.response.out.write(html)

    class SimpleJinja2Handler(Jinja2Handler, SimpleContext):
        pass

    class DatastoreJinja2Handler(Jinja2Handler, DatastoreContext):
        pass


##
## Tenjin
##
try:
    import tenjin
    from tenjin.helpers import *
    from tenjin.helpers.html import *
    import tenjin.gae; tenjin.gae.init()
    tenjin.logger = logger
    sys.stderr.write("*** tenjin.__release__=%r\n" % (tenjin.__release__, ))
except ImportError:
    sys.stderr.write("*** tenjin not installed\n")
    tenjin = None
    SimpleTenjinHandler = DatastoreTenjinHandler = NotInstalled
    SimpleSafeTenjinHandler = DatastoreSafeTenjinHandler = NotInstalled
else:

    class TenjinHandler(webapp.RequestHandler):
        engine = tenjin.Engine(path=[os.path.dirname(__file__) + '/templates'])
        def get(self):
            flag_escape = self.request.get('escape')
            file_name = flag_escape and 'escape_tenjin.pyhtml' or 'bench_tenjin.pyhtml'
            #logger.info('** file_name=%r' % file_name)
            #engine = tenjin.Engine(path=[os.path.dirname(__file__) + '/templates'])
            html = self.engine.render(file_name, self._context())
            self.response.out.write(html)

    class SimpleTenjinHandler(TenjinHandler, SimpleContext):
        pass

    class DatastoreTenjinHandler(TenjinHandler, SimpleContext):
        pass

    class SafeTenjinHandler(webapp.RequestHandler):
        engine = tenjin.SafeEngine(path=[os.path.dirname(__file__) + '/templates'])
        def get(self):
            flag_escape = self.request.get('escape')
            file_name = flag_escape and 'escape_safetenjin.pyhtml' or 'bench_safetenjin.pyhtml'
            #logger.info('** file_name=%r' % file_name)
            #engine = tenjin.Engine(path=[os.path.dirname(__file__) + '/templates'])
            html = self.engine.render(file_name, self._context())
            self.response.out.write(html)

    class SimpleSafeTenjinHandler(SafeTenjinHandler, SimpleContext):
        pass

    class DatastoreSafeTenjinHandler(SafeTenjinHandler, SimpleContext):
        pass


##
## WSGI application
##
mappings = [                                        # (no escape),  (escape)
    ('/django',        SimpleDjangoHandler),        # 31.5 req/sec, 28.6 req/sec  (ver 1.2.5)
                                                    # 40.0 req/sec, 35.5 req/sec  (ver 0.96)
    ('/mako',          SimpleMakoHandler),          # 44.1 req/sec, 41.1 req/sec
    ('/jinja2',        SimpleJinja2Handler),        # 41.0 req/sec, 38.1 req/sec
    ('/tenjin',        SimpleTenjinHandler),        # 48.3 req/sec, 47.8 req/sec
    ('/safetenjin',    SimpleSafeTenjinHandler),    # 47.6 req/sec, 45.8 req/sec
    ('/db/django',     DatastoreDjangoHandler),     # 16.0 req/sec, 15.2 req/sec  (ver 1.2.5)
                                                    # 17.4 req/sec, 16.4 req/sec  (ver 0.96)
    ('/db/mako',       DatastoreMakoHandler),       # 18.2 req/sec, 17.7 req/sec
    ('/db/jinja2',     DatastoreJinja2Handler),     # 17.4 req/sec, 16.8 req/sec
    ('/db/tenjin',     DatastoreTenjinHandler),     # 19.0 req/sec, 18.8 req/sec
    ('/db/safetenjin', DatastoreSafeTenjinHandler), # 19.0 req/sec, 18.7 req/sec
]
all_mappings = [
    ('/',              IndexPage),
    ('/stocks',        StocksHandler),
] + mappings


def main():
    app = webapp.WSGIApplication(all_mappings, debug=is_dev)
    util.run_wsgi_app(app)


if __name__ == '__main__':
    main()
