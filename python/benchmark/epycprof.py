#!/usr/bin/env python

import sys, os, profile, getopt
import epyc
from epyc.html import *

## parse options
command = os.path.basename(sys.argv[0])
try:
    optlist, filenames = getopt.getopt(sys.argv[1:], "hxdp:f:n:l:")
except Exception, ex:
    sys.stderr.write("%s: %s\n" % (command, str(ex)))
    sys.exit(1)
options = {}
for key, val in optlist:
    options[key[1:]] = val == '' and True or val

## help
if options.has_key('h'):
    print """\
usage: %s [-hxd] [-f datafile] [-p logfile] [-n N] [-l layout] file...
   -h         : help
   -x         : use _evaluate_with_layout() instead of evaluate_with_layout()
   -d         : print output, no profiling
   -p logfile : log filename of profiling
   -n N       : repeat N times
   -l layout  : layout template
""" % command
    sys.exit(0)

## context
context = {}
datafile = options.get('f')
if datafile:
    if datafile.endswith('.py'):
        exec(open(datafile).read(), globals(), context)
    elif datafile.endswith('.yaml') or datafile.endswith('.yml'):
        import yaml
        context = yaml.load(open(datafile))

## variables
layout = options.get('l')
ntimes = int(options.get('n', 1))
manager = epyc.Manager(prefix="user_", postfix=".pyhtml", layout=layout)

if layout == 'user_layout2.pyhtml':
    options['x'] = True


def do_test():
    for filename in filenames:
        if not layout:
            for i in xrange(0, ntimes):
                manager = epyc.Manager(prefix="user_", postfix=".pyhtml", layout=layout)
                output = manager.evaluate(filename, context, layout=False)
        #elif not options.get('x'):
        #    for i in xrange(0, ntimes):
        #        manager = epyc.Manager(prefix="user_", postfix=".pyhtml", layout=layout)
        #        output = manager.evaluate(filename, context, _buf=_buf)
        else:
            sys.stderr.write("*** debug: options.get('x')=%s\n" % (repr(options.get('x'))))
            for i in xrange(0, ntimes):
                manager = epyc.Manager(prefix="user_", postfix=".pyhtml", layout=layout)
                _buf = []
                _buf = output = manager.evaluate(filename, context)
                output = ''.join(_buf)
        if options.get('d'):
            print output,

if options.get('d'):
    do_test()
elif options.get('p'):
    logfile = options['p']
    import re
    dumpfile = re.sub(r'\.\w+$', '', logfile) + '.dump'
    #sys.stderr.write("*** debug: options['p']=%s\n" % (repr(options['p'])))
    profile.run('do_test()', dumpfile)
    import pstats
    p = pstats.Stats(dumpfile)
    sys.stdout = open(logfile, 'w')
    p.strip_dirs()
    p.sort_stats(-1)
    p.sort_stats('time')   # or 'cumulative'
    p.print_stats()
    sys.stdout.close()
    #open(logfile, 'w').write(s)
else:
    profile.run('do_test()')
