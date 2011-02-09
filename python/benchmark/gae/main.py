#!/usr/bin/env python

import sys, os, re

from google.appengine.ext import webapp
from google.appengine.ext.webapp import util, template

import logging
logger = logging.getLogger()

import tenjin
from tenjin.helpers import *
import tenjin.gae; tenjin.gae.init()

from bench_context import items
for item in items:
    item.minus_ = item.change < 0.0


class DjangoHandler(webapp.RequestHandler):
    def get(self):
        flag_escape = self.request.get('escape')
        file_name = flag_escape and 'escape_django.html' or 'bench_django.html'
        path = os.path.dirname(__file__) + '/templates/' + file_name
        #logger.info('** path=%r' % path)
        context = {'items': items}
        html = template.render(path, context)
        self.response.out.write(html)


class TenjinHandler(webapp.RequestHandler):
    def get(self):
        flag_escape = self.request.get('escape')
        file_name = flag_escape and 'escape_tenjin.pyhtml' or 'bench_tenjin.pyhtml'
        path = [os.path.dirname(__file__) + '/templates']
        #logger.info('** file_name=%r' % file_name)
        context = {'items': items}
        engine = tenjin.Engine(path=path)
        html = engine.render(file_name, context)
        self.response.out.write(html)


class SingletonTenjinHandler(webapp.RequestHandler):
    engine = tenjin.Engine(path=[os.path.dirname(__file__) + '/templates'])
    def get(self):
        flag_escape = self.request.get('escape')
        file_name = flag_escape and 'escape_tenjin.pyhtml' or 'bench_tenjin.pyhtml'
        #logger.info('** file_name=%r' % file_name)
        context = {'items': items}
        html = self.engine.render(file_name, context)
        self.response.out.write(html)


mappings = [                                # (no escape),  (escape)
    ('/django', DjangoHandler),             # 40.0 req/sec, 35.4 req/sec
    ('/tenjin', TenjinHandler),             # 48.8 req/sec, 48.0 req/sec
    ('/singleton', SingletonTenjinHandler), # 49.2 req/sec, 48.3 req/sec
]

is_dev = os.environ.get('SERVER_SOFTWARE', '').startswith('Devel')

def main():
    app = webapp.WSGIApplication(mappings, debug=is_dev)
    util.run_wsgi_app(app)


if __name__ == '__main__':
    main()
