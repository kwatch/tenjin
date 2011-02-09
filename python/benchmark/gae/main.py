#!/usr/bin/env python

###
### Benchmark Django v.s. Tenjin on Google App Engine
###
### without datastore:
###
###    $ ab -n 100 -c 5 http://127.0.0.1:8080/django
###    $ ab -n 100 -c 5 http://127.0.0.1:8080/django?escape=1
###    $ ab -n 100 -c 5 http://127.0.0.1:8080/tenjin
###    $ ab -n 100 -c 5 http://127.0.0.1:8080/tenjin?escape=1
###    $ ab -n 100 -c 5 http://127.0.0.1:8080/t
###    $ ab -n 100 -c 5 http://127.0.0.1:8080/tenjin?escape=1
###
### with datastore (before benchmark, access to http://localhost:8080/stocks/):
###
###    $ ab -n 100 -c 5 http://127.0.0.1:8080/stocks/django
###    $ ab -n 100 -c 5 http://127.0.0.1:8080/stocks/django?escape=1
###    $ ab -n 100 -c 5 http://127.0.0.1:8080/stocks/tenjin
###    $ ab -n 100 -c 5 http://127.0.0.1:8080/stocks/tenjin?escape=1
###
###
### $Release: $
### $Copyright: copyright(c) 2007-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re

from google.appengine.ext import webapp, db
from google.appengine.ext.webapp import util, template

is_dev = os.environ.get('SERVER_SOFTWARE', '').startswith('Devel')

import logging
logger = logging.getLogger()
if is_dev:
    logger.setLevel(logging.DEBUG)

import tenjin
from tenjin.helpers import *
import tenjin.gae; tenjin.gae.init()

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


class DjangoHandler(webapp.RequestHandler):

    def get(self):
        flag_escape = self.request.get('escape')
        file_name = flag_escape and 'escape_django.html' or 'bench_django.html'
        path = os.path.dirname(__file__) + '/templates/' + file_name
        #logger.info('** path=%r' % path)
        context = {'items': _items}
        html = template.render(path, context)
        self.response.out.write(html)


class TenjinHandler(webapp.RequestHandler):

    engine = tenjin.Engine(path=[os.path.dirname(__file__) + '/templates'])

    def get(self):
        flag_escape = self.request.get('escape')
        file_name = flag_escape and 'escape_tenjin.pyhtml' or 'bench_tenjin.pyhtml'
        #logger.info('** file_name=%r' % file_name)
        context = {'items': _items}
        #engine = tenjin.Engine(path=[os.path.dirname(__file__) + '/templates'])
        #html = engine.render(file_name, context)
        html = self.engine.render(file_name, context)
        self.response.out.write(html)


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


class StocksDjangoHandler(webapp.RequestHandler):

    def get(self):
        flag_escape = self.request.get('escape')
        file_name = flag_escape and 'escape_django.html' or 'bench_django.html'
        path = os.path.dirname(__file__) + '/templates/' + file_name
        #logger.info('** path=%r' % path)
        context = {'items': Stock.all().order('-price').fetch(100)}
        html = template.render(path, context)
        self.response.out.write(html)


class StocksTenjinHandler(webapp.RequestHandler):

    engine = tenjin.Engine(path=[os.path.dirname(__file__) + '/templates'])

    def get(self):
        flag_escape = self.request.get('escape')
        file_name = flag_escape and 'escape_tenjin.pyhtml' or 'bench_tenjin.pyhtml'
        #logger.info('** file_name=%r' % file_name)
        context = {'items': Stock.all().order('-price').fetch(100)}
        html = self.engine.render(file_name, context)
        self.response.out.write(html)


mappings = [                                 # (no escape),  (escape)
    ('/django',    DjangoHandler),           # 40.0 req/sec, 35.4 req/sec
    ('/tenjin',    TenjinHandler),           # 49.2 req/sec, 48.3 req/sec
    ('/stocks/django', StocksDjangoHandler), # 16.1 req/sec, 15.1 req/sec
    ('/stocks/tenjin', StocksTenjinHandler), # 18.1 req/sec, 17.6 req/sec
    ('/stocks',        StocksHandler),
]

def main():
    app = webapp.WSGIApplication(mappings, debug=is_dev)
    util.run_wsgi_app(app)


if __name__ == '__main__':
    main()
