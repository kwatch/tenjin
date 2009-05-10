from __future__ import with_statement

import os, re
from glob import glob
from kook.utils import read_file, write_file

release = prop('release', '0.6.2')
#package = prop('package', 'pyTenjin')
package = prop('package', 'Tenjin')


copyright       = "copyright(c) 2007-2009 kuwata-lab.com all rights reserved."
license         = "MIT License"
python_basepath = "/Library/Frameworks/Python.framework/Versions/2.4"
python_basepath = "/usr/local/lib/python2.5"
#site_packages_path = "%s/lib/python2.4/site-packages" % python_basepath
site_packages_path = "%s/site-packages" % python_basepath
script_file     = "pytenjin"
library_files   = [ "tenjin.py" ]


@product("package")
@ingreds("examples")
def task_package(c):
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
        with chdir(dir) as d2:
            system("python setup.py egg_info --egg-base .")
            rm("*.pyc")
        mv(pkg, c%"$(pkg).bkup")
        #tar_czf(c%"$(dir).tar.gz", dir)
        system(c%"tar -cf $(dir).tar $(dir)")
        system(c%"gzip -f9 $(dir).tar")
        ## create *.egg file
        with chdir(dir) as d3:
            system("python setup.py bdist_egg")
            mv("dist/*.egg", "..")
            rm_rf("build", "dist")


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
    rm_r("examples")
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


def task_uninstall(c):
    #script_file    = "$python_basepath/bin/" + script_file;
    #library_files  = [ os.path.join(site_packages_path, item) for item in library_files ]
    #compiled_files = [ item + '.c' for item in library_files ]
    script_file = "/usr/local/bin/pytenjin"
    dir = "/usr/local/lib/python2.5/site-packages"
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


def task_test(c):
    with chdir('test'):
        system("pykook test")


def task_clean(c):
    from glob import glob
    dirs = glob("examples/*");
    for dir in dirs:
        if os.path.isdir(dir):
            with chdir(dir) as d:
                system("make clean")
    rm_f("test/test.log", "test/kook.log")
