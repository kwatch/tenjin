
##
## cookbook for pykook -- you must install pykook at first.
## pykook is a build tool like Rake. you can define your task in Python.
## http://pypi.python.org/pypi/Kook/0.0.1
## http://www.kuwata-lab.com/kook/pykook-users-guide.html
##

from __future__ import with_statement

import os, re
from glob import glob
from kook.utils import read_file, write_file

release = prop('release', '0.9.0')
#package = prop('package', 'pyTenjin')
package = prop('package', 'Tenjin')
copyright = prop('copyright', "copyright(c) 2007-2010 kuwata-lab.com all rights reserved.")

license         = "MIT License"
#python_basepath = "/Library/Frameworks/Python.framework/Versions/2.4"
#site_packages_path = "%s/lib/python2.4/site-packages" % python_basepath
python_basepath = "/usr/local/lib/python2.5"
site_packages_path = "%s/site-packages" % python_basepath
script_file     = "pytenjin"
library_files   = [ "tenjin.py" ]

kook_default_product = 'test'

python_bins = [
    '/opt/local/bin/python2.4',
    '/usr/local/python/2.5.5/bin/python',
    '/usr/local/python/2.6.5/bin/python',
    '/usr/local/python/2.7.0/bin/python',
    '/usr/local/python/3.0.1/bin/python',
    '/usr/local/python/3.1/bin/python',
]


@recipe
@ingreds("examples")
@spices("-A: create all egg files for each version of python")
def task_package(c, *args, **kwargs):
    """create package"""
    ## remove files
    pattern = c%"dist/$(package)-$(release)*"
    if glob(pattern):
        rm_rf(pattern)
    ## edit files
    repl = (
        (r'\$Release\$', release),
        (r'\$Release:.*?\$', '$Release: %s $' % release),
        (r'\$Copyright\$', copyright),
        (r'\$Package\$', package),
        (r'\$License\$', license),
    )
    cp('setup.py.txt', 'setup.py')
    edit('setup.py', by=repl)
    ## setup
    system('python setup.py sdist')
    #system('python setup.py sdist --keep-temp')
    with chdir('dist') as d:
        #pkgs = kook.util.glob2(c%"$(package)-$(release).tar.gz");
        #pkg = pkgs[0]
        pkg = c%"$(package)-$(release).tar.gz"
        echo(c%"pkg=$(pkg)")
        #tar_xzf(pkg)
        system(c%"tar xzf $(pkg)")
        dir = re.sub(r'\.tar\.gz$', '', pkg)
        #echo("*** debug: pkg=%s, dir=%s" % (pkg, dir))
        edit(c%"$(dir)/**/*", by=repl)
        #with chdir(dir):
        #    system("python setup.py egg_info --egg-base .")
        #    rm("*.pyc")
        mv(pkg, c%"$(pkg).bkup")
        #tar_czf(c%"$(dir).tar.gz", dir)
        system(c%"tar -cf $(dir).tar $(dir)")
        system(c%"gzip -f9 $(dir).tar")
        ## create *.egg file
        def bdist_egg(bin):
            system("%s setup.py bdist_egg" % bin)
            mv("dist/*.egg", "..")
            rm_rf("build", "dist")
        with chdir(dir):
            if kwargs.get('A'):
                bins = [ x for x in python_bins if re.search(r'2\.[567]', x) ]
                for bin in bins:
                    bdist_egg(bin)
            else:
                bdist_egg('python')


@recipe
#@ingreds("doc/examples.txt")
def task_examples(c):
    """create examples"""
    ## get filenames
    txtfile = "doc/examples.txt";
    tmpfile = "tmp.examples.txt";
    system(c%"retrieve -l $(txtfile) > $(tmpfile)");
    result = read_file(tmpfile)
    rm(tmpfile)
    ## get dirnames
    dirs = {}   # hash
    for filename in re.split(r'\n', result):
        d = os.path.dirname(filename)
        if d: dirs[d] = d
    #print "*** debug: dirs=%s" % dirs
    ## create directories
    rm_rf("examples")
    mkdir("examples")
    for d in dirs:
        mkdir("examples/" + d)
    ## retrieve files
    system(c%"retrieve -d examples $(txtfile)")
    rm_rf("examples/**/*.result")
    ## create Makefile
    for d in dirs:
        plfile = ''
        if os.path.exists(c%"examples/$(d)/main.pl"):
           plfile = 'main.pl'
        elif os.path.exists(c%"examples/$(d)/table.pl"):
           plfile = 'table.pl'
        f = open(c%"examples/$(d)/Makefile", "w")
        f.write("all:\n")
        f.write(c%"\tpltenjin $(plfile)\n")
        f.write("\n")
        f.write("clean:\n")
        f.write("\trm -f *.cache\n")
        f.close()


@recipe
def task_uninstall(c):
    #script_file    = "$python_basepath/bin/" + script_file;
    #library_files  = [ os.path.join(site_packages_path, item) for item in library_files ]
    #compiled_files = [ item + '.c' for item in library_files ]
    script_file = "/usr/local/bin/pytenjin"
    dir = site_packages_dir
    library_files = "$dir/$(package)*"
    rm(script_file, library_files)
    filename = "$dir/easy-install.pth"
    if os.path.exists(filename):
        s = read_file(filename)
        pattern = r'/^\.\/$(package)-.*\n/m'
        if re.match(pattern, s):
            s = re.sub(pattern, s)
        write_file(filename, s)
        repl = ((pattern, ''), )
        edit(filename, by=repl)


@recipe
@spices('-A: do test with all version of python')
def task_test(c, *args, **kwargs):
    if kwargs.get('A'):
        with chdir('test'):
            for bin in python_bins:
                print('******************** ' + bin)
                system("%s test_all.py" % bin)
    else:
        with chdir('test'):
            system("pykook test")


@recipe
def task_clean(c):
    from glob import glob
    dirs = glob("examples/*");
    for dir in dirs:
        if os.path.isdir(dir):
            with chdir(dir) as d:
                system("make clean")
    rm_f("test/test.log", "test/kook.log")
