from __future__ import with_statement

import os, re, glob

#def to_strong(s):
#    s = re.sub(r'\{\{\*', '<strong>', s)
#    s = re.sub(r'\*\}\}', '</strong>', s)
#    return s
#
#def to_unstrong(str):
#    s = re.sub(r'\{\{\*', '', s)
#    s = re.sub(r'\*\}\}', '', s)
#    return s
#
#def pre_to_console(s):
#    s = re.sub('<pre class="literal-block">\n\\$', '<pre class="console">\n$', s)
#    return s
#
#def pre_to_file(s):
#    s = re.sub('<pre class="literal-block">\n', '<pre class="file">\n', s)
#    return s


tagfile  = prop('tagfile', 'html-css')

#dir = 'data'
testdir  = '../test'
datadir  = testdir + '/data'
#title   = "Tenjin User's Guide"
#stylesheet = 'html4css1.css'
stylesheet = 'docstyle.css'
#rstdir   = '/Library/Frameworks/Python.framework/Versions/2.4/bin'
#rst2html = rstdir+'/rst2html.py'
#rst2html_opts = 'rst2html_opts', '--link-stylesheet --no-xml-declaration --no-source-link --no-toc-backlinks --language=en --stylesheet="%s" --title="%s"' % (stylesheet, title)  #--strip-comments
tidy_opts = 'tidy_opts', '-q -i -wrap 9999 --hide-comments yes'

#users_guide_eruby = 'users-guide.eruby'
original_docdir = '../../common/doc/'
users_guide_eruby = original_docdir + 'users-guide.eruby'
faq_eruby         = original_docdir + 'faq.eruby'
examples_eruby    = original_docdir + 'examples.eruby'
kook_default_product = 'all'
testfiles = ['test_users_guide.py', 'test_faq.py']
basenames = ['users-guide', 'faq', 'examples']
textfiles = [ x+'.txt' for x in basenames]
htmlfiles = [ x+'.html' for x in basenames]


@ingreds('doc', 'test')
def task_all(c):
    pass


@ingreds(htmlfiles, stylesheet)
def task_doc(c):
    """generate *.html"""
    pass


@product(stylesheet)
@ingreds(original_docdir + stylesheet)
def file_css(c):
    cp(c.ingred, c.product)


#@product('users-guide.html')
#@ingreds('users-guide.txt', 'retrieve')
#@byprods('users-guide.toc.html')
#def file_users_guide_html(c):
#    system(c%'kwaser -t $(tagfile) -T $(ingred) > $(byprod)')
#    system(c%'kwaser -t $(tagfile)    $(ingred) > $(product)')
#    rm(c.byproducts)


#@product('users-guide.html')
#@ingreds('users-guide.rst')
#@byprods('users-guide.tmp')
#def file_users_guide_html(c):
#    system_f(c%'$(rst2html) $(rst2html_opts) $(ingreds) 2>&1 > $(byprod)')
#    s = open(c.byprod).read()
#    s = to_string(s)
#    s = pre_to_console(s)
#    s = pre_to_file(s)
#    open(c.byprod, 'w').write(s)
#    system_f(c%'tidy $(tidy_opts) $(byprod) > $(product)')
#    rm(c.byprod)


@product('*.html')
@ingreds('$(1).txt')
@byprods('$(1).toc.html')
def file_html(c):
    system(c%'kwaser -t $(tagfile) -T $(ingred) > $(byprod)')
    system(c%'kwaser -t $(tagfile)    $(ingred) > $(product)')
    system_f(c%'tidy -i -w 9999 -utf8 -m -q $(product)')
    f = (
      (re.compile(r'^  <meta name="generator" content="HTML Tidy .*?\n', re.M), ''),
      (re.compile(r'^  <meta http-equiv="Content-Type" content="text/html">\n\n?', re.M),
       '  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">\n'),
    )
    edit(c.product, by=f)

@product('*.txt')
@ingreds(original_docdir + '$(1).eruby')
#@ingreds('$(1).eruby', if_exists(original_docdir + '/$(1).eruby')
def file_txt(c):
    """create *.txt from *.eruby and retrieve testdata from *.txt"""
    #if os.path.exists(c.ingreds[1]):
    #    cp(c.ingreds[1], c.ingred)
    system(c%"erubis -E PercentLine -c '@lang=%q|python|' -p '\\[% %\\]' $(ingred) > $(product)");
    #
    name = re.sub(r'\.txt$', '', c.product.replace('-', '_'))
    datadir = testdir + '/data/' + name
    if os.path.exists(datadir):
        rm_rf(datadir + '/*')
    else:
        mkdir(datadir)
    system(c%"which retrieve");
    system(c%"retrieve -Fd $(datadir) $(product)");
    pat = datadir + '/*.result2'
    filenames = glob.glob(datadir + '/*.result2')
    for filename in filenames:
        content = open(filename).read()
        os.unlink(filename)
        rexp = re.compile(r'^\$ ', re.M)
        contents = rexp.split(content)
        i = 0
        for cont in contents:
            if not cont: continue
            i += 1
            fname = re.sub(r'\.result2$', '%s.result' % i, filename)
            open(fname, 'w').write('$ ' + cont)


@ingreds(testdir + '/test_users_guide.py',
         testdir + '/test_faq.py',
         testdir + '/test_examples.py')
def task_create_test(c):
    """create test script"""
    pass


#@ingreds('users-guide.txt', 'faq.txt', 'examples.txt')
#def task_retrieve(c):
#    pass


def task_clean(c):
    rm_rf('*.toc.html', 'test.log', '*.pyc')


@ingreds('test_users_guide', 'test_faq', 'test_examples')
def task_test(c):
    pass


@ingreds(testdir+'/test_users_guide.py', 'users-guide.txt')
def task_test_users_guide(c):
    name = re.sub(r'^test_', '', c.product)
    with chdir(testdir) as d:
        system(c%'python $(ingred)')


@ingreds(testdir+'/test_faq.py', 'faq.txt')
def task_test_faq(c):
    task_test_users_guide(c)


@ingreds(testdir+'/test_examples.py', 'examples.txt')
def task_test_examples(c):
    task_test_users_guide(c)


@product(testdir + '/test_users_guide.py')
@ingreds(testdir + '/test_users-guide.py')
def task_test_users_guide_py(c):
    mv(c.ingred, c.product)
    #mv("data/users-guide", "data/users_guide")


@product(testdir+'/test_*.py')
def task_test_py(c):
    ## base name
    #base = c[1]
    m = re.search(r'test_(.*)\.py$', c.product)
    base = m.group(1)
    name = base.replace('-', '_')
    ## class name
    classname = ''.join([x.capitalize() for x in re.split(r'[-_]', base)]) + 'Test'
    ## header
    buf = []
    buf.append(c%"""
#
# auto generated
#

import unittest, os, re

from testcase_helper import *

class $(classname)(unittest.TestCase, TestCaseHelper):

    basedir = '$(datadir)/$(name)'
    DIR = (os.path.dirname(__file__) or '.') + '/' + basedir
    CWD = os.getcwd()

    def setUp(self):
        os.chdir(self.__class__.DIR)

    def tearDown(self):
        os.chdir(self.__class__.CWD)

    def _test(self):
        filename = self.filename;
        dirname = os.path.dirname(filename)
        pwd = os.getcwd()
        if dirname:
            os.chdir(dirname)
            filename = os.path.basename(filename)
        s = open(filename).read()
        pat = r'\\A\\$ (.*?)\\n'
        m = re.match(pat, s)
        command = m.group(1)
        expected = re.sub(pat, '', s)
        result = os.popen(command).read()
        self.assertTextEqual(expected, result)

""")

    ## body
    buf.append("""

    from glob import glob
    import os
    filenames = []
    filenames.extend(glob('%s/*.result' % basedir))
    filenames.extend(glob('%s/*/*.result' % basedir))
    filenames.extend(glob('%s/*.source' % basedir))
    filenames.extend(glob('%s/*/*.source' % basedir))
    for filename in filenames:
        #name = os.path.basename(filename).replace('.result', '')
        name = filename.replace(basedir+'/', '')
        s = "\\n".join((
             "def test_%s(self):" % re.sub('[^\w]', '_', name),
             "    self.filename = '%s'" % name,
             "    self._test()",
             ))
        exec(s)

""")

    files = glob.glob(datadir + '/*.result')
    for file in files:
        name = re.sub(r'\.result$', '', os.path.basename(file))
        buf.append(c%"""
    def test_$(name)(self):
        self.name = '$(name)'
        self._test()

""")

    ## footer
    buf.append(c%"""

remove_unmatched_test_methods($(classname))


if __name__ == '__main__':
    unittest.main()
""")

    s = ''.join(buf)
    open(c.product, 'w').write(''.join(buf))
    print(c%"** '$(product)' created.")
    #cp(c.product, c%"../test/$(product)")
