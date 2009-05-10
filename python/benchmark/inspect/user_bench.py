#!/usr/bin/env python

import sys, os, re, time, getopt

import epyc
from epyc.html import *

ntimes = 1000

## parse command-line options
command = os.path.basename(sys.argv[0])
try:
    optlist, filenames = getopt.getopt(sys.argv[1:], 'hf:l:n:p', [])
except Exception, ex:
    sys.stderr.write("%s: %s\n" (command, str(ex)))
    sys.exit(0)
options = dict([(key[1:], val=='' and True or val) for key, val in optlist])
if options.has_key('n'):
    if not re.match(r'\d+', options.get('n')):
        sys.stderr.write("%s: -n: integer required.\n" (command))
        sys.exit(0)

## help
if options.has_key('h'):
    print """\
Usage:  %s [-h] [-f datafile] [-n N] file1.epyc [file2.epyc ...]
  -h             :  show help
  -f datafile    :  context data file (*.py)
  -l layout      :  layout file
  -n N           :  N times to repeat in benchmark (default %d)
  -p             :  print output of evaluation
""" % (command, ntimes),
    sys.exit(0)


## context data
context = {}
datafile = options.get('f')
if datafile:
    s = open(datafile).read()
    exec(s, globals(), context)

## print output
layout = options.get('l', None)
if options.get('p'):
    for filename in filenames:
        manager = epyc.Manager(layout=layout)
        if not layout:
            output = manager.evaluate(filename, context)
        elif layout == 'user_layout1.pyhtml':
            output = manager.evaluate_with_layout(filename, context)
        elif layout == 'user_layout2.pyhtml':
            _buf = [];
            #_buf = manager._evaluate_with_layout(filename, _buf, context)
            _buf = manager.evaluate_with_layout(filename, context)
            output = ''.join(_buf)
        else:
            assert(False) # unreachable
        print output,
    sys.exit(0)

## do benchmark
n = int(options.get('n', ntimes))
for filename in filenames:
    manager = epyc.Manager(layout=layout)
    start_t = time.time()
    t1 = os.times()
    if not layout:
        for i in xrange(0, n):
            output = manager.evaluate(filename, context)
    elif layout == 'user_layout1.pyhtml':
        for i in xrange(0, n):
            output = manager.evaluate_with_layout(filename, context)
    elif layout == 'user_layout2.pyhtml':
        for i in xrange(0, n):
            _buf = [];
            #_buf = manager._evaluate_with_layout(filename, _buf, context)
            _buf = manager.evaluate_with_layout(filename, context)
            output = ''.join(_buf)
    else:
        assert(False)  # unreachable
    t2 = os.times()
    end_t = time.time()

    print '$', " ".join(sys.argv[:-len(filenames)]), filename
    utime = t2[0] - t1[0]
    stime = t2[1] - t1[1]
    total = t2[4] - t1[4]
    real  = end_t - start_t
    print "%10.5f %10.5f %10.5f %10.5f" % (utime, stime, total, real)
