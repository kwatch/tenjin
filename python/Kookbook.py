
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
def task_edit(c):
    """edit files"""
    filenames = read_file('MANIFEST').splitlines()
    excludes = ('test/data', 'examples',
                'benchmark/templates', 'benchmark/gae/templates',)
    filenames = [ x for x in filenames if not x.startswith(excludes) ]
    filenames.remove('Kookbook.py')
    filenames.remove('test/oktest.py')
    edit(filenames, by=replacer())
    def repl(s):
        pat = r"^([ \t]*\w+\s*=\s*)'.*?'(\s*##\s*\$(?:Package|Release|License): (.*?) \$)"
        return re.compile(pat, re.M).sub(r"\1'\3'\2", s)
    edit('setup.py', by=repl)


def replacer(flag_all=False):
    repl = (
        (r'\$Package:.*?\$',  '$Package: %s $' % package),
        (r'\$Release:.*?\$',  '$Release: %s $' % release),
        (r'\$Coyright:.*?\$', '$Copyright: %s $' % copyright),
        (r'\$License:.*?\$',  '$License: %s $' % license),
    )
    if flag_all:
        repl = (
            (r'\$Package\$',   package),
            (r'\$Release\$',   release),
            (r'\$Copyright\$', copyright),
            (r'\$License\$',   license),
        ) + repl
    return repl


@recipe
@ingreds("examples")
def task_build(c):
    """copy files into build-X.X.X"""
    ## create a directory to store files
    dir = "build-%s" % release
    os.path.isdir(dir) and rm_rf(dir)
    mkdir(dir)
    ## copy files according to MANIFEST.in
    _store_files_accoring_to_manifest(dir)
    ## copy or remove certain files
    store("MANIFEST.in", dir)
    rm_f(c%"$(dir)/MANIFEST", c%"$(dir)/test/test_pytenjin_cgi.py")
    ## edit all files
    edit("%s/**/*" % dir, by=replacer(True))
    ## copy files again which should not be edited
    store("Kookbook.py", "test/oktest.py", dir)


def _store_files_accoring_to_manifest(dir):
    lines = read_file('MANIFEST.in').splitlines()
    for line in lines:
        items = line.split(' ')[1:]
        if line.startswith('include '):
            fnames = items
            store(fnames, dir)
        elif line.startswith('exclude '):
            fnames = [ "%s/%s" % (dir, x) for x in items ]
            rm_rf(fnames)
        elif line.startswith('recursive-include '):
            fnames= [ "%s/**/%s" % (items[0], x) for x in items[1:] ]
            store(fnames, dir)
        elif line.startswith('recursive-exclude '):
            fnames = [ "%s/%s/**/%s" % (dir, items[0], x) for x in items[1:] ]
            rm_rf(fnames)


@recipe
@ingreds("build")
def task_sdist(c):
    """python setup.py sdist"""
    dir = "build-%s" % release
    with chdir(dir):
        system("python setup.py sdist")
    cp(c%"$(dir)/MANIFEST", ".")


@recipe
@ingreds("build", "sdist")
def task_egg(c):
    """python setup.py bdist_egg"""
    dir = "build-%s" % release
    with chdir(dir):
        system("python setup.py bdist_egg")


@recipe
@ingreds("build", "sdist")
def task_eggs(c):
    """python setup.py bdist_egg (for all version)"""
    dir = "build-%s" % release
    with chdir(dir):
        for bin in python_bins:
            system(c%"$(bin) setup.py bdist_egg")


@recipe
@ingreds("examples")
@spices("-A: create all egg files for each version of python")
def task_package(c, *args, **kwargs):
    """create package"""
    ## remove files
    pattern = c%"dist/$(package)-$(release)*"
    if glob(pattern):
        rm_rf(pattern)
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
        edit(c%"$(dir)/**/*", by=replacer(True))
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
    rm_rf("**/*.pyc", "**/*.cache", "**/__cache__")
    rm_f("test/test.log", "test/kook.log")


@recipe
@ingreds('clean')
def task_clear(c):
    from glob import glob
    dirs = glob("examples/*");
    for dir in dirs:
        if os.path.isdir(dir):
            with chdir(dir) as d:
                system("make clean")


@recipe
def oktest(c):
    """copy oktest.py into test directory"""
    original = os.path.expanduser("~/src/oktest/python/lib/oktest.py")
    cp_p(original, 'test')


@recipe
def follow(c):
    system("git co exp-extend")
    system("git rebase python")
    system("git co python")
