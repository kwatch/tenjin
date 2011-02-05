# -*- coding: utf-8 -*-

###
### Benchmarks between str-based and unicode-based
###
### Requires Benchmarker 3.0
###   http://pypi.python.org/pypi/Benchmarker/
###

from __future__ import with_statement

import sys, os, re, glob

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3

import benchmarker
from benchmarker import Benchmarker
benchmarker.cmdopt.parse()
benchmarker.format.label_width = 32
#benchmarker.format.time        = '%9.4f'


##
## import tenjin
##
import tenjin
from tenjin.helpers import *


class BenchApp(object):

    encoding = 'utf-8'

    def __init__(self, file_name='bench_tenjin.pyhtml'):
        self.file_name = file_name
        self.cache_name = file_name + '.cache'

    def load_context(self, file_name='bench_context.py'):
        with open(file_name) as f:
            src = f.read()
        codeobj = compile(src, file_name, 'exec')
        local_vars = {}
        exec(codeobj, globals(), local_vars)
        if 'stocks' not in local_vars:
            local_vars['stocks'] = local_vars['items']
        if python2:
            for stock in local_vars['stocks']:
                d = stock.__dict__
                for k in ('name', 'name2', 'url', 'symbol',):
                    if isinstance(d[k], str):
                        d[k] = unicode(d[k])
        return local_vars

    def generate_template(self, encoding='utf-8'):
        with open('templates/_header.html') as f:
            header = f.read()
        with open('templates/_footer.html') as f:
            footer = f.read()
        with open('templates/' + self.file_name) as f:
            body = f.read()
        new_body = re.sub(r"item\['(.*?)'\]", r"item.\1", body)
        assert new_body != body
        body = new_body
        content = ''.join((encoding and '''<?py # coding: %s ?>\n''' % encoding or '',
                           '''<?py #@ARGS stocks ?>\n''',
                           header, body, footer))
        with open(self.file_name, 'wb') as f:
            f.write(content)

    def remove_cache(self):
        if os.path.exists(self.cache_name):
            os.unlink(self.cache_name)

    def before(self, encoding):
        self.generate_template(encoding)
        self.remove_cache()

    def after(self, engine):
        engine.cache.clear()

    def main(self):

        context = self.load_context()
        #for stock in context['stocks']:
        #    print(stock.__dict__)

        for bm in Benchmarker(loop=10000):

            ##
            ## str-base template
            ##
            self.before(self.encoding)
            engine = tenjin.Engine()
            for _ in bm('tenjin (str based)'):
                output = engine.render(self.file_name, context)
                #assert type(output) is str
            #print(output)
            self.after(engine)

            ##
            ## unicode-base template
            ##
            self.before(None)
            engine = tenjin.Engine(encoding=self.encoding)
            for _ in bm('tenjin (unicode based)'):
                output = engine.render(self.file_name, context)
                #assert type(output) is unicode
            #print(output)
            self.after(engine)

            ##
            ## unicode-base template with converting into str
            ##
            self.before(None)
            engine = tenjin.Engine(encoding=self.encoding)
            for _ in bm('tenjin (unicode & encode)'):
                output = engine.render(self.file_name, context)
                #assert type(output) is unicode
                output = output.encode(self.encoding)
            #print(output)
            self.after(engine)

        #self.after()


if __name__ == '__main__':
    BenchApp().main()



###
### Output Example
###
# $ python bench_unicode.py -c 5 -X 1
# ## benchmarker:       release 0.0.0 (for python)
# ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5664)]
# ## python version:    2.7.1
# ## python executable: /usr/local/python/2.7.1/bin/python
#
# ## Average of 5 (=7-2*1)             user       sys     total      real
# tenjin (str based)                 4.7560    0.0020    4.7580    4.7655
# tenjin (unicode based)             5.0160    0.0020    5.0180    5.0236
# tenjin (unicode & encode)          5.1540    0.0080    5.1620    5.1628
#
# ## Ranking                           real
# tenjin (str based)                 4.7655 (100.0%) *************************
# tenjin (unicode based)             5.0236 ( 94.9%) ************************
# tenjin (unicode & encode)          5.1628 ( 92.3%) ***********************
#
# ## Ratio Matrix                      real    [01]    [02]    [03]
# [01] tenjin (str based)            4.7655  100.0%  105.4%  108.3%
# [02] tenjin (unicode based)        5.0236   94.9%  100.0%  102.8%
# [03] tenjin (unicode & encode)     5.1628   92.3%   97.3%  100.0%
#
