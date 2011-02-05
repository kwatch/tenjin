# -*- coding: utf-8 -*-

###
### Benchmarks for converted Python code
###
### Requires Benchmarker 3.0
###   http://pypi.python.org/pypi/Benchmarker/
###

from __future__ import with_statement


import sys, os, re, glob

import benchmarker
from benchmarker import Benchmarker


##
## parse command-line options
##
benchmarker.cmdopt.parse()


##
## set output format
##
benchmarker.format.label_width = 32
#benchmarker.format.time        = '%9.4f'


##
## helper functions called in template file
##
def to_str(val):
    if val is None:
        return ''
    else:
        return str(val)

def escape_html(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')#.replace("'", '&039;')

try:
    import webext
    from webext import to_str as webext_to_str, escape_html as webext_escape_html
except ImportError:
    webext = None


##
## load context data
##
local_vars = {}
with open('bench_context.py') as f:
    exec(f, globals(), local_vars)
items = local_vars['items']


##
## load python scripts and create benchmark functions
##
benchmark_functions = []

def load_script(file_name):
    def find_keyword(string, keyword):
        pat = r'^#+ *' + keyword + ': *(.*)'
        m = re.compile(pat, re.M).search(string)
        if m:  return m.group(1)
        return None
    with open(file_name) as f:
        script = f.read()
    name = find_keyword(script, 'name') or re.search(r'pycode_(?:\d\d_)?(.*)\.py', file_name).group(1)
    desc = find_keyword(script, 'desc') or name
    bytecode = compile(script, file_name, 'exec')
    return name, desc, bytecode

for file_name in glob.glob(__file__.replace('.py', '/pycode*.py')):
    name, desc, bytecode = load_script(file_name)
    def f(items, _bytecode=bytecode):
        local_vars = {'items': items, '_result': None}
        exec(_bytecode, globals(), local_vars)
        return local_vars['_result']
    f.__name__ = name
    f.__doc__  = desc
    f._skip    = None
    benchmark_functions.append(f)

if not webext:
    for func in benchmark_functions:
        if func.__name__.find('webext') >= 0:
            func._skip = '** skipped: webext is not installed **'


##
## check whether all benchmark code generates the same output or not
##
if benchmark_functions:
    expected = benchmark_functions[0](items)
    for func in benchmark_functions:
        if func._skip:
            continue
        actual = func(items)
        if actual != expected:
            import difflib
            for x in difflib.unified_diff(expected, actual, 'expected', 'actual', n=2):
                print repr(x)
            sys.exit(1)


##
## do benchmarks
##
for bm in Benchmarker(loop=10000, cycle=1, extra=0):
    for func in benchmark_functions:
        if func._skip:
            bm.skip(func, func._skip)
        else:
            bm.run(func, items)

##
## output example
##
# $ python bench_pycode.py -n 10000 -c 5 -X 1 -q
# ## benchmarker:       release 0.0.0 (for python)
# ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5659)]
# ## python version:    2.5.5
# ## python executable: /usr/local/python/2.5.5/bin/python
#
# ## Average of 5 (=7-2*1)             user       sys     total      real
# append (line)                      2.0940    0.0020    2.0960    2.1002
# append (multilines)                1.5160    0.0000    1.5160    1.5203
# extend (unbound)                   0.9700    0.0000    0.9700    0.9717
# extend (bound)                     0.8620    0.0000    0.8620    0.8653
# extend + str                       1.2580    0.0000    1.2580    1.2621
# extend + _str=str                  1.2000    0.0000    1.2000    1.1988
# extend + format                    1.1540    0.0020    1.1560    1.1555
# append + format                    1.1100    0.0040    1.1140    1.1113
# extend + to_str                    1.7060    0.0000    1.7060    1.7115
# extend + _to_str=to_str            1.6480    0.0000    1.6480    1.6477
# escape_html + str                  4.3160    0.0020    4.3180    4.3270
# escape_html + to_str               4.7440    0.0020    4.7460    4.7502
# webext.escape_html & to_str        1.6640    0.0020    1.6660    1.6683
# webext.escape_html                 1.2560    0.0000    1.2560    1.2614
#
# ## Ranking                           real
# extend (bound)                     0.8653 (100.0%) *************************
# extend (unbound)                   0.9717 ( 89.0%) **********************
# append + format                    1.1113 ( 77.9%) *******************
# extend + format                    1.1555 ( 74.9%) *******************
# extend + _str=str                  1.1988 ( 72.2%) ******************
# webext.escape_html                 1.2614 ( 68.6%) *****************
# extend + str                       1.2621 ( 68.6%) *****************
# append (multilines)                1.5203 ( 56.9%) **************
# extend + _to_str=to_str            1.6477 ( 52.5%) *************
# webext.escape_html & to_str        1.6683 ( 51.9%) *************
# extend + to_str                    1.7115 ( 50.6%) *************
# append (line)                      2.1002 ( 41.2%) **********
# escape_html + str                  4.3270 ( 20.0%) *****
# escape_html + to_str               4.7502 ( 18.2%) *****
#
# ## Ratio Matrix                      real    [01]    [02]    [03]    [04]    [05]    [06]    [07]    [08]    [09]    [10]    [11]    [12]    [13]    [14]
# [01] extend (bound)                0.8653  100.0%  112.3%  128.4%  133.5%  138.5%  145.8%  145.9%  175.7%  190.4%  192.8%  197.8%  242.7%  500.1%  549.0%
# [02] extend (unbound)              0.9717   89.0%  100.0%  114.4%  118.9%  123.4%  129.8%  129.9%  156.5%  169.6%  171.7%  176.1%  216.1%  445.3%  488.9%
# [03] append + format               1.1113   77.9%   87.4%  100.0%  104.0%  107.9%  113.5%  113.6%  136.8%  148.3%  150.1%  154.0%  189.0%  389.4%  427.4%
# [04] extend + format               1.1555   74.9%   84.1%   96.2%  100.0%  103.7%  109.2%  109.2%  131.6%  142.6%  144.4%  148.1%  181.7%  374.5%  411.1%
# [05] extend + _str=str             1.1988   72.2%   81.1%   92.7%   96.4%  100.0%  105.2%  105.3%  126.8%  137.4%  139.2%  142.8%  175.2%  361.0%  396.3%
# [06] webext.escape_html            1.2614   68.6%   77.0%   88.1%   91.6%   95.0%  100.0%  100.1%  120.5%  130.6%  132.3%  135.7%  166.5%  343.0%  376.6%
# [07] extend + str                  1.2621   68.6%   77.0%   88.1%   91.6%   95.0%   99.9%  100.0%  120.5%  130.6%  132.2%  135.6%  166.4%  342.8%  376.4%
# [08] append (multilines)           1.5203   56.9%   63.9%   73.1%   76.0%   78.9%   83.0%   83.0%  100.0%  108.4%  109.7%  112.6%  138.1%  284.6%  312.5%
# [09] extend + _to_str=to_str       1.6477   52.5%   59.0%   67.4%   70.1%   72.8%   76.6%   76.6%   92.3%  100.0%  101.3%  103.9%  127.5%  262.6%  288.3%
# [10] webext.escape_html & to_str   1.6683   51.9%   58.2%   66.6%   69.3%   71.9%   75.6%   75.7%   91.1%   98.8%  100.0%  102.6%  125.9%  259.4%  284.7%
# [11] extend + to_str               1.7115   50.6%   56.8%   64.9%   67.5%   70.0%   73.7%   73.7%   88.8%   96.3%   97.5%  100.0%  122.7%  252.8%  277.6%
# [12] append (line)                 2.1002   41.2%   46.3%   52.9%   55.0%   57.1%   60.1%   60.1%   72.4%   78.5%   79.4%   81.5%  100.0%  206.0%  226.2%
# [13] escape_html + str             4.3270   20.0%   22.5%   25.7%   26.7%   27.7%   29.2%   29.2%   35.1%   38.1%   38.6%   39.6%   48.5%  100.0%  109.8%
# [14] escape_html + to_str          4.7502   18.2%   20.5%   23.4%   24.3%   25.2%   26.6%   26.6%   32.0%   34.7%   35.1%   36.0%   44.2%   91.1%  100.0%
