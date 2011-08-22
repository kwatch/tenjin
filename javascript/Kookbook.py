from __future__ import with_statement

import sys, os, re

project = 'jstenjin'
release = prop('release', '0.0.0')

kookbook.default = "test"


@recipe
def test(c):
    #with chdir('doc'):
    #    system("kk test")
    with chdir('test'):
        system("oktest.js *_test.js")


copyright  = 'Copyright(c) 2007-2011 kuwata-lab.com all rights reserved'
distdir    = 'dist-' + release
textfiles  = ['README.txt', 'MIT-LICENSE', 'CHANGES.txt']
docfiles   = ['doc/users-guide.html', 'doc/faq.html', 'doc/examples.html', 'doc/docstyle.css']
testfiles  = ['test/test_*.rb', 'test/assert*.rb', 'test/data/**/*']
benchfiles = [ 'benchmark/' + x for x in
                  ('Makefile', 'bench.js', 'bench_context.json', 'templates/*') ]

@recipe
@ingreds('doc', 'dist', 'website')
def task_all(c):
    """do all"""
    pass


@recipe
def doc(c):
    """create documents"""
    with chdir('doc'):
        system(c%"kk doc")


@recipe
def website(c):
    """create website"""
    with chdir('website'):
        system(c%"kk all")


kookbook.load('@kook/books/clean.py')
CLEAN.append(distdir)
SWEEP.append('dist-*')


@recipe
def dist(c):
	"""create distribution files"""
	## build directory
	dir = distdir
	os.path.exists(dir) and rm_rf(dir)
	mkdir_p(dir)

	## copy files
	store(textfiles, dir)
	store('bin/*', 'lib/*.js', dir)
	rm_f('test/data/**/*.cache')
	store(testfiles, dir)
	store(docfiles, dir)
	store(benchfiles, dir)
	rm_f(c%"$(dir)/test/test_tenjin.rb")
	cp('lib/shotenjin.js', c%"$(dir)/doc")

	## edit files
	replacer = [
	    (r'\$Release:.*?\$',   '$Release: %s $'   % release),
	    (r'\$Copyright:.*?\$', '$Copyright: %s $' % copyright),
	    (r'\$License:.*?\$',   '$License: %s $'   % license),
	    (r'\$Release\$',   release),
	    (r'\$Copyright\$', copyright),
	    (r'\$License\$',   license),
	]
	edit(c%"$(dir)/**/*", by=replacer)
