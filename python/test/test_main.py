# -*- coding: utf-8 -*-
###
### $Release: $
### $Copyright: copyright(c) 2007-2011 kuwata-lab.com all rights reserved. $
###

from oktest import ok, not_ok, run
import os, traceback
import yaml

from testcase_helper import *
import tenjin
from tenjin.helpers import escape, to_str

filename = None
for filename in ['../bin/pytenjin', 'bin/pytenjin']:
    if os.path.exists(filename):
        break

_name_orig = __name__
__name__ = 'dummy'
exec(tenjin._read_binary_file(filename).decode('utf-8'))
__name__ = _name_orig

def to_list(value):
    if isinstance(value, list):
        return value
    return [value]


import sys
python_version = sys.version.split(' ')[0]


INPUT = r"""<ul>
<?py for item in ['<a&b>', '["c",'+"'d']"]: ?>
  <li>#{item}
      ${item}</li>
<?py #end ?>
</ul>
"""
INPUT2 = """<ul>\r\n\
<?py for item in ['<a&b>', '["c",'+"'d']"]: ?>\r\n\
  <li>#{item}\r\n\
      ${item}</li>\r\n\
<?py #end ?>\r\n\
</ul>\r\n\
"""
INPUT3 = r"""<?py
#title = _context['title']
#items = _context.items
?>
<h1>#{title}</h1>
<ul>
<?py for item in items: ?>
  <li>#{item}</li>
<?py #endfor ?>
</ul>
"""

SOURCE = r"""_buf = []; _extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''<ul>\n''', ));
for item in ['<a&b>', '["c",'+"'d']"]:
    _extend(('''  <li>''', _to_str(item), '''
      ''', _escape(_to_str(item)), '''</li>\n''', ));
#end
_extend(('''</ul>\n''', ));
print(''.join(_buf))
"""
SOURCE2 = """_buf = []; _extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''<ul>\\r\\n''', ));\n\
for item in ['<a&b>', '["c",'+"'d']"]:\n\
    _extend(('''  <li>''', _to_str(item), '''\r\n\
      ''', _escape(_to_str(item)), '''</li>\\r\\n''', ));\n\
#end\n\
_extend(('''</ul>\\r\\n''', ));\n\
print(''.join(_buf))
"""
SOURCE_N = r"""    1:  _buf = []; _extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''<ul>\n''', ));
    2:  for item in ['<a&b>', '["c",'+"'d']"]:
    3:      _extend(('''  <li>''', _to_str(item), '''
    4:        ''', _escape(_to_str(item)), '''</li>\n''', ));
    5:  #end
    6:  _extend(('''</ul>\n''', ));
    7:  print(''.join(_buf))
"""

EXECUTED = r"""<ul>
  <li><a&b>
      &lt;a&amp;b&gt;</li>
  <li>["c",'d']
      [&quot;c&quot;,'d']</li>
</ul>
"""
EXECUTED2 = """<ul>\r\n\
  <li><a&b>\r\n\
      &lt;a&amp;b&gt;</li>\r\n\
  <li>["c",'d']\r\n\
      [&quot;c&quot;,'d']</li>\r\n\
</ul>\r\n\
"""
EXECUTED3 = r"""<h1>tenjin example</h1>
<ul>
  <li>aaa</li>
  <li>bbb</li>
  <li>ccc</li>
</ul>
"""

CONTEXT1 = r"""
title: tenjin example
items:
	- aaa
	- bbb
	- ccc
"""
CONTEXT2 = r"""
title = 'tenjin example'
items = ['aaa', 'bbb', 'ccc']
"""


class MainTest(object):

    def before(self):
        pass

    def after(self):
        pass

    def _test(self):
        input     = getattr(self, 'input', '')
        source    = getattr(self, 'source', None)
        expected  = getattr(self, 'expected', None)
        exception = getattr(self, 'exception', None)
        errormsg  = getattr(self, 'errormsg', None)
        options   = getattr(self, 'options', '')
        filename  = getattr(self, 'filename', None)
        context_file = getattr(self, 'context_file', None)
        context_data = getattr(self, 'context_data', None)
        encoding  = getattr(self, 'encoding', None)
        #
        if python_version < '2.5':
            if expected:
                expected = expected.replace(': unexpected indent', ': invalid syntax')
        #
        if filename is not False:
            if filename is None:
                filename = '.test.pyhtml'
            #write_file(filename, input)
            for fname, s in zip(to_list(filename), to_list(input)):
                if encoding and isinstance(s, _unicode):
                    s = s.encode(encoding)
                write_file(fname, s)
        #
        if isinstance(options, list):
            argv = options
        elif isinstance(options, str):
            argv = [item for item in options.split(' ') if item]
        argv.insert(0, 'tenjin')
        if filename:
            #argv.append(filename)
            argv.extend(to_list(filename))
        #print "*** debug: argv=%s" % repr(argv)
        #
        if context_file:
            s = context_data
            if encoding and instance(s, _unicode):
                s = s.encode(encoding)
            write_file(context_file, s)
        #
        try:
            app = Main(argv)
            if exception:
                lst = [None]
                def f1():
                    try:
                        output = app.execute()
                    except Exception:
                        ex = sys.exc_info()[1]
                        lst[0] = ex
                        raise ex
                ok (f1).raises(exception)
                if errormsg:
                    ex = lst[0]
                    ok (str(ex)) == errormsg
            else:
                output = app.execute()
                #print "*** expected=%s" % expected
                #print "*** output=%s" % output
                if python2:
                    if encoding and isinstance(output, unicode):
                        output = output.encode(encoding)
                ok (output) == expected
        finally:
            try:
                if filename:
                    #os.remove(filename)
                    for fname in to_list(filename):
                        os.unlink(fname)
                if context_file:
                    os.remove(context_file)
            except:
                pass

    code = TestCaseHelper.generate_testcode(__file__)
    exec(code)



    def test_help(self):  # -h, --help
        self.options  = "-h"
        self.input    = ""
        self.expected = Main(['tenjin']).usage('tenjin')
        self._test()
        #
        self.options  = "--help"
        self._test()

    def test_version(self):  # -v, --version
        self.options  = "-v"
        self.input    = ""
        self.expected = Main(['tenjin']).version() + "\n"
        self._test()
        self.options = '--version'
        self._test()

#    def test_help_and_version(self):  # -hVz
#        self.options  = "-hVc"
#        self.input    = "<?py foo() ?>"
#        app = Main(['tenjin'])
#        self.expected = app.version() + "\n" + app.usage('tenjin')
#        self._test()

    def test_render(self):  # (nothing), -a render
        self.options  = ""
        self.input    = INPUT
        self.expected = EXECUTED
        self._test()
        self.options  = "-a render"
        self._test()

    def test_source(self):  # -s, -a convert
        self.options  = "-s"
        self.input    = INPUT
        self.expected = SOURCE
        self._test()
        self.options = "-a convert"
        self._test()

    def test_source2(self):  # -s, -aconvert
        self.options  = "-s"
        n1 = len("<ul>\n")
        n2 = len("</ul>\n")
        self.input    = INPUT[n1:-n2]
        buf = SOURCE.splitlines(True)[1:-2]
        buf.insert(0, "_buf = []\n_extend=_buf.extend;_to_str=to_str;_escape=escape; \n")
        buf.append("print(''.join(_buf))\n")
        self.expected = ''.join(buf)
        self._test()
        self.options = "-aconvert"
        self._test()

    def test_source3(self):  # -sb, -baconvert
        self.options  = "-sb"
        self.input    = INPUT
        n1 = len("_buf = []; ")
        n2 = len("print(''.join(_buf))\n")
        self.expected = SOURCE[n1:-n2]
        self._test()
        self.options = "-baconvert"
        self._test()

    def test_number1(self):   # -sN
        self.options  = "-sN"
        self.input    = INPUT
        self.expected = SOURCE_N
        self._test()

    def test_number2(self):   # -sbN
        self.options  = "-sbN"
        self.input    = INPUT
        self.expected = re.sub(r'\n    7:.*?\n$', "\n", SOURCE_N).replace('_buf = []; ', '')
        self._test()

    def test_cache1(self):   # -a cache
        self.options  = "-a cache"
        self.input    = (
            '<?py #@ARGS title, items ?>\n'
            '<h1>${title}</h1>\n'
            '<ul>\n'
            '<?py for item in items: ?>\n'
            '  <li>${item}</li>\n'
            '<?py #endfor ?>\n'
            '</ul>\n'
            )
        self.expected = ''
        script = (
            "title = _context.get('title'); items = _context.get('items'); \n"
            "_extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''<h1>''', _escape(_to_str(title)), '''</h1>\n"
            "<ul>\\n''', ));\n"
            "for item in items:\n"
            "    _extend(('''  <li>''', _escape(_to_str(item)), '''</li>\\n''', ));\n"
            "#endfor\n"
            "_extend(('''</ul>\\n''', ));\n"
            )
        self.filename = 'test_cache1.pyhtml'
        cachename = self.filename + '.cache'
        try:
            self._test()
            ok (cachename).exists()
            import marshal
            dct = marshal.load(open(cachename, 'rb'))
            ok (dct.get('args')) == ['title', 'items']
            if   python2:  expected = "<type 'code'>"
            elif python3:  expected = "<class 'code'>"
            ok (str(type(dct.get('bytecode')))) == expected
            ok (dct.get('script')) == script
        finally:
            if os.path.exists(cachename):
                os.unlink(cachename)

    input_for_retrieve = (
        '<div>\n'
        '<?py if list: ?>\n'
        '  <table>\n'
        '    <thead>\n'
        '      <tr>\n'
        '        <th>#</th><th>item</th>\n'
        '      </tr>\n'
        '    </thead>\n'
        '    <?py i = 0 ?>\n'
        '    <?py for item in list: ?>\n'
        '\t<?py i += 1 ?>\n'
        '    <tbody>\n'
        '      <tr bgcolor="#{i % 2 and "#FFCCCC" or "#CCCCFF"}">\n'
        '\t<td>${i}</td>\n'
        '        <td>${item}</td>\n'
        '      </tr>\n'
        '    </tbody>\n'
        '    <?py #end ?>\n'
        '  </table>\n'
        '<?py #end ?>'
        '</div>\n'
        )
    expected_for_retrieve = '\n'.join((
        '_buf = []; _extend=_buf.extend;_to_str=to_str;_escape=escape; ',
        'if list:',
        '',
        '',
        '',
        '',
        '',
        '',
        '    i = 0',
        '    for item in list:',
        '        i += 1',
        '',
        '        _to_str(i % 2 and "#FFCCCC" or "#CCCCFF"); ',
        '        _escape(_to_str(i)); ',
        '        _escape(_to_str(item)); ',
        '',
        '',
        '    #end',
        '',
        '#end',
        '',
        'print(\'\'.join(_buf))',
        ''))

    def test_retrieve1(self):  # -S, -a retrieve
        self.input    = self.input_for_retrieve
        self.expected = self.expected_for_retrieve
        self.options = '-S'
        self._test()
        self.options = '-a retrieve'
        #self._test()

    def test_retrieve2(self):  # -SU, -SNU
        expected = '\n'.join((
            '_buf = []; _extend=_buf.extend;_to_str=to_str;_escape=escape; ',
            'if list:',
            '',
            '    i = 0',
            '    for item in list:',
            '        i += 1',
            '',
            '        _to_str(i % 2 and "#FFCCCC" or "#CCCCFF"); ',
            '        _escape(_to_str(i)); ',
            '        _escape(_to_str(item)); ',
            '',
            '    #end',
            '',
            '#end',
            '',
            'print(\'\'.join(_buf))',
            ''))
        self.input = self.input_for_retrieve
        self.expected = expected
        self.options = '-SU'
        self._test()
        #
        expected = '\n'.join((
            '    1:  _buf = []; _extend=_buf.extend;_to_str=to_str;_escape=escape; ',
            '    2:  if list:',
            '',
            '    9:      i = 0',
            '   10:      for item in list:',
            '   11:          i += 1',
            '',
            '   13:          _to_str(i % 2 and "#FFCCCC" or "#CCCCFF"); ',
            '   14:          _escape(_to_str(i)); ',
            '   15:          _escape(_to_str(item)); ',
            '',
            '   18:      #end',
            '',
            '   20:  #end',
            '',
            '   22:  print(\'\'.join(_buf))',
            ''))
        self.expected = expected
        self.options = '-SNU'
        self._test()

    def test_retrieve3(self):  # -SC, -SNC
        expected = '\n'.join((
            '_buf = []; _extend=_buf.extend;_to_str=to_str;_escape=escape; ',
            'if list:',
            '    i = 0',
            '    for item in list:',
            '        i += 1',
            '        _to_str(i % 2 and "#FFCCCC" or "#CCCCFF"); ',
            '        _escape(_to_str(i)); ',
            '        _escape(_to_str(item)); ',
            '    #end',
            '#end',
            'print(\'\'.join(_buf))',
            ''))
        self.input = self.input_for_retrieve
        self.expected = expected
        self.options = '-SC'
        self._test()
        #
        expected = '\n'.join((
            '    1:  _buf = []; _extend=_buf.extend;_to_str=to_str;_escape=escape; ',
            '    2:  if list:',
            '    9:      i = 0',
            '   10:      for item in list:',
            '   11:          i += 1',
            '   13:          _to_str(i % 2 and "#FFCCCC" or "#CCCCFF"); ',
            '   14:          _escape(_to_str(i)); ',
            '   15:          _escape(_to_str(item)); ',
            '   18:      #end',
            '   20:  #end',
            '   22:  print(\'\'.join(_buf))',
            ''))
        self.expected = expected
        self.options = '-SNC'
        self._test()

    def test_statements(self):  # -X, -a statements
        expected = '\n'.join((
            '_buf = []; _extend=_buf.extend;_to_str=to_str;_escape=escape; ',
            'if list:',
            '',
            '',
            '',
            '',
            '',
            '',
            '    i = 0',
            '    for item in list:',
            '        i += 1',
            '',
            '',
            '',
            '',
            '',
            '',
            '    #end',
            '',
            '#end',
            '',
            'print(\'\'.join(_buf))',
            ''))
        self.input = self.input_for_retrieve
        self.expected = expected
        self.options = '-X'
        self._test()
        self.options = '-a statements'
        self._test()

    def test_dump(self):  # -d, -a dump
        # create cache file
        filename = '_test_dump.pyhtml'
        cachename = filename + '.cache'
        self.filename = filename
        self.input = INPUT
        self.expected = EXECUTED
        self.options = '-a render --cache=true'
        self._test()
        ok (cachename).exists()
        # dump test
        try:
            self.filename = False
            self.input    = False
            self.expected = SOURCE[len('_buf = []; '):-len("print(''.join(_buf))\n")]
            #self.options = '-d %s' % cachename
            #self._test()
            self.options = '-a dump %s' % cachename
            self._test()
        finally:
            os.unlink(cachename)

    def test_indent(self):  # -i2
        self.options  = "-si2"
        self.input    = INPUT
        pat = re.compile(r'^    _extend', re.M)
        self.expected = pat.sub(r'  _extend',  SOURCE)
        self._test()

    def test_quiet(self):  # -q, -qasyntax
        self.options  = "-z"
        input = INPUT
        self.input    = [input, input, input]
        basename = ".test_quiet%d.pyhtml"
        self.filename = [basename % i for i in range(0,3)]
        self.expected = ''.join([(basename+" - ok.\n") % i for i in range(0,3)])
        self._test()
        #
        self.options  = "-zq"
        self.expected = ""
        self._test()
        self.options = "-qasyntax"
        self._test()

    def test_invalid_options(self):  # -Y, -i, -f, -c, -i foo
        self.input    = INPUT
        self.expected = ""
        self.exception = CommandOptionError
        #
        self.options  = "-hY"
        self.errormsg = "-Y: unknown option."
        self._test()
        #
        self.options  = "-i"
        self.filename = False
        #self.errormsg = "-i: indent width required."
        self.errormsg = "-i: argument required."
        self._test()
        #
        self.options  = "-f"
        self.filename = False
        #self.errormsg = "-f: context data filename required."
        self.errormsg = "-f: argument required."
        self._test()
        #
        self.options  = "-c"
        self.filename = False
        #self.errormsg = "-c: context data string required."
        self.errormsg = "-c: argument required."
        self._test()
        #
        self.options  = "-i foo"
        self.errormsg = "-i: integer value required."
        self._test()
        #

    def test_newline(self):
        self.options  = "-s"
        self.input    = INPUT2
        self.expected = SOURCE2
        self._test()
        self.options  = ""
        self.expected = EXECUTED2
        self._test()

    def test_datafile_yaml(self): # -f datafile.yaml
        context_filename = 'test.datafile.yaml'
        self.options  = "-f " + context_filename
        self.input    = INPUT3
        self.expected = EXECUTED3
        self.context_file = context_filename
        self.context_data = CONTEXT1
        self._test()

    def test_datafile_py(self): # -f datafile.py
        context_filename = 'test.datafile.py'
        self.options  = "-f " + context_filename
        self.input    = INPUT3
        self.expected = EXECUTED3
        self.context_file = context_filename
        self.context_data = CONTEXT2
        self._test()

    def test_datafile_error(self):  # -f file.txt, not-a-mapping context data
        context_filename = 'test.datafile.txt'
        self.options = "-f " + context_filename
        self.exception = CommandOptionError
        self.errormsg = "-f %s: file not found." % context_filename
        self._test()
        #
        self.context_file = context_filename
        self.context_data = "- foo\n- bar\n -baz"
        self.errormsg = "-f %s: unknown file type ('*.yaml' or '*.py' expected)." % context_filename
        self._test()
        #
        context_filename = 'test.datafile.yaml'
        self.options = "-f " + context_filename
        self.errormsg = "%s: not a mapping (dictionary)." % context_filename
        self.context_file = context_filename
        self._test()

    def test_context_yaml(self):  # -c yamlstr
        self.options = ['-c', '{title: tenjin example, items: [aaa, bbb, ccc]}']
        self.input    = INPUT3
        self.expected = EXECUTED3
        self._test()

    def test_context_py(self):  # -c python-code
        self.options = ['-c', 'title="tenjin example";  items=["aaa", "bbb", "ccc"]']
        self.input    = INPUT3
        self.expected = EXECUTED3
        self._test()

    def test_untabify(self):  # -T
        context_filename = 'test.datafile.yaml'
        self.options  = "-Tf " + context_filename
        self.input    = INPUT3
        self.expected = EXECUTED3
        self.context_file = context_filename
        self.context_data = CONTEXT1
        self.exception = yaml.parser.ScannerError
        self._test()

    def test_modules(self):  # -r modules
        #self.options  = "--escapefunc=cgi.escape"
        #self.input    = INPUT
        #self.expected = EXECUTED.replace('&quot;', '"')
        #self.exception = NameError
        #self.errormsg = "name 'cgi' is not defined"
        #self._test()
        ##
        #self.options  = "-r cgi,os,sys --escapefunc=cgi.escape"
        #self.input    = INPUT
        #self.expected = EXECUTED.replace('&quot;', '"')
        #self.exception = None
        #self.errormsg = None
        #self._test()
        #
        self.input    = "Hello #{cgi.escape('Haru&Kyon')}!"
        self.expected = "Hello Haru&amp;Kyon!"
        #
        globals().pop('cgi', None)
        self.exception = NameError
        self.errormsg = "name 'cgi' is not defined"
        self._test()
        #
        self.options  = "-r cgi,os,sys"
        self.exception = None
        self.errormsg = None
        self._test()

    def test_modules_err(self):  # -r hogeratta
        self.options = '-r hogeratta'
        self.exception = CommandOptionError
        self.errormsg = '-r hogeratta: module not found.'
        self._test()

    def test_escapefunc(self):  # --escapefunc=cgi.escape
        self.options  = "-s --escapefunc=cgi.escape"
        self.input    = INPUT
        self.expected = SOURCE.replace('=escape', '=cgi.escape')
        self._test()

    def test_tostrfunc(self):  # --tostrfunc=str
        self.options  = "-s --tostrfunc=str"
        self.input    = INPUT
        self.expected = SOURCE.replace('=to_str', '=str')
        self._test()

    def test_preamble(self):  # --preamble --postamble
        self.options  = ["-s", "--preamble=_buf=list()", "--postamble=return ''.join(_buf)"]
        self.input    = INPUT
        self.expected = re.sub(r'print\((.*?)\)', r'return \1', SOURCE).replace("_buf = []; ", "_buf=list(); ")
        self._test()

    def test_xencoding1(self):  # --encoding=encoding
        if python2:
            self.input = """\
<?py items=['foo',u'bar',u'日本語'] ?>
ようこそ
<?py for item in items: ?>
* 「${item}」
<?py #end ?>
"""
        elif python3:
            self.input = """\
<?py items=['foo','bar','日本語'] ?>
ようこそ
<?py for item in items: ?>
* 「${item}」
<?py #end ?>
"""
        self.expected = """\
ようこそ
* 「foo」
* 「bar」
* 「日本語」
"""
        #
        self.encoding = 'utf-8'
        self.options  = "--encoding=%s" % self.encoding
        self._test()

    def test_xencoding2(self):  # -k encoding
        if python2:
            self.input = """\
<?py items=['foo',u'bar','日本語'] ?>
ようこそ
<?py for item in items: ?>
* 「${item}」
<?py #end ?>
"""
        elif python3:
            self.input = """\
<?py items=['foo',b'bar','日本語'] ?>
ようこそ
<?py for item in items: ?>
* 「${item}」
<?py #end ?>
"""
        self.expected = """\
ようこそ
* 「foo」
* 「bar」
* 「日本語」
"""
        #
        self.encoding = 'utf-8'
        self.options  = "-k utf-8"
        tostr_func = to_str
        try:
            self._test()
        finally:
            globals()['tostr'] = tostr_func

    def test_template_path(self):  # --path
        layout = r'''<html>
  <body>
#{_content}
<?py include(':footer') ?>
  </body>
</html>
'''
        body = r'''<ul>
<?py for item in 'ABC': ?>
  <li>${item}</li>
<?py #endfor ?>
</ul>
'''
        footer = r'''<hr />
<a href="mailto:webmaster@localhost">webmaser</a>
'''
        expected = r'''<html>
  <body>
<ul>
  <li>A</li>
  <li>B</li>
  <li>C</li>
</ul>

<hr />
<a href="mailto:webmaster@localhost">webmaser</a>
  </body>
</html>
'''
        try:
            os.mkdir("tmpl9")
            os.mkdir("tmpl9/user")
            write_file("tmpl9/layout.pyhtml", layout)
            write_file("tmpl9/body.pyhtml", '')
            write_file("tmpl9/footer.pyhtml", '')
            write_file("tmpl9/user/body.pyhtml", body)
            write_file("tmpl9/user/footer.pyhtml", footer)
            self.options  = "--path=.,tmpl9/user,tmpl9 --postfix=.pyhtml --layout=:layout"
            self.input = "<?py include(':body') ?>"
            self.expected = expected
            self._test()
        finally:
            from glob import glob
            for f in glob('tmpl9/user/*.pyhtml'): os.unlink(f)
            for f in glob('tmpl9/*.pyhtml'): os.unlink(f)
            for d in ['tmpl9/user', 'tmpl9']: os.rmdir(d)

    def test_preprocess1(self):  # -P, -a preprocess, --preprocess
        input = '''\
<?PY states = { "CA": "California", ?>
<?PY            "NY": "New York", ?>
<?PY            "FL": "Florida", } ?>
<?PY # ?>
<?py chk = { params['state']: ' checked="checked"' } ?>
<?PY codes = list(states.keys()) ?>
<?PY codes.sort() ?>
<select name="state">
  <option value="">-</option>
<?PY for code in codes: ?>
  <option value="#{{code}}"#{chk.get(#{{repr(code)}}, '')}>${{states[code]}}</option>
<?PY #endfor ?>
</select>
'''
        script = '''\
<?py chk = { params['state']: ' checked="checked"' } ?>
<select name="state">
  <option value="">-</option>
  <option value="CA"#{chk.get('CA', '')}>California</option>
  <option value="FL"#{chk.get('FL', '')}>Florida</option>
  <option value="NY"#{chk.get('NY', '')}>New York</option>
</select>
'''
        expected = '''\
<select name="state">
  <option value="">-</option>
  <option value="CA" checked="checked">California</option>
  <option value="FL">Florida</option>
  <option value="NY">New York</option>
</select>
'''
        try:
            self.options  = "-P" # "-P --prefix=prep_ --postfix=.pyhtml"
            self.input = input
            self.expected = script
            self._test()
            self.options = "-a preprocess"
            self._test()
            #
            self.options  = ["--preprocess=true", "-c", "{params: {state: CA}}"]
            self.input = input
            self.expected = expected
            self._test()
        finally:
            pass

    def test_safe(self):  # --safe
        _backup = tenjin.Engine.templateclass
        try:
            self.options  = "-s --safe"
            self.input    = INPUT
            self.input    = re.sub(r'#{(.*?)}', r'{==\1==}', self.input)
            self.input    = re.sub(r'\${(.*?)}', r'{=\1=}', self.input)
            self.expected = SOURCE.replace('=escape', '=to_escaped')
            self.expected = re.sub(r'_escape\(_to_str\((.*?)\)\)', r'_escape(\1)', self.expected)
            self._test()
        finally:
            tenjin.Engine.templateclass = _backup


if __name__ == '__main__':
    run()
