###
### $Release: $
### $Copyright: copyright(c) 2007-2011 kuwata-lab.com all rights reserved. $
###

from oktest import ok, not_ok, run, spec
from oktest.tracer import Tracer
import sys, os, re

from testcase_helper import *
import tenjin
from tenjin.helpers import *


class TemplateTest(object):

    code = TestCaseHelper.generate_testcode(__file__)
    exec(code)


    def before(self):
        pass

    def after(self):
        pass

    def _test(self):
        input     = getattr(self, 'input', None)
        source    = getattr(self, 'source', None)
        expected  = getattr(self, 'expected', None)
        exception = getattr(self, 'exception', None)
        errormsg  = getattr(self, 'errormsg', None)
        options   = getattr(self, 'options', {})
        filename  = getattr(self, 'filename', None)
        context   = getattr(self, 'context', {})
        testopts  = getattr(self, 'testopts', None)
        disabled  = getattr(self, 'disabled', None)
        templateclass = getattr(self, 'templateclass', None)
        encoding  = None
        #
        if disabled:
            return
        #
        if testopts:
            if 'crchar' in testopts:
                ch = testopts['crchar']
                if input:     input    = input.replace(ch, "\r")
                if source:    source   = source.replace(ch, "\r")
                if expected:  expected = expected.replace(ch, "\r")
            if testopts.get('escapefunc') == 'cgi.escape':
                #import cgi
                #context['escape'] = cgi.escape
                pass
            if testopts.get('tostrfunc') == 'str':
                #context['to_str'] = str
                pass
            if 'encoding' in testopts:
                encoding = testopts.get('encoding')
            if 'templateclass' in testopts:
                templateclass = testopts.get('templateclass')
        #
        if python3:
            input  = input.replace('urllib.quote', 'urllib.parse.quote')
            source = source.replace('urllib.quote', 'urllib.parse.quote')
            if encoding:
                if source:
                    source = source.replace("u'''", "'''").replace("u'", "'")
                    input  = input.replace("u'", "'")
        #
        if exception:
            try:
                template = tenjin.Template(**options)
                template.convert(input, filename)
                template.render(context)
                self.fail('%s is expected but not raised.' % exception)
            except Exception:
                ex = sys.exc_info()[1]
                ok (ex.__class__) == exception
                #ok (ex).is_a(exception)
                if errormsg:
                    ## SyntaxError has 'msg' attribute instead of 'message'. Why?
                    #ok (ex.message or ex.msg) == errormsg # failed in python2.3
                    ok (ex.args[0]) == errormsg
                if filename:
                    ok (ex.filename) == filename
        else:
            if templateclass:
                templateclass = eval(templateclass)
                template = templateclass(**options)
            else:
                template = tenjin.Template(**options)
            script = template.convert(input, filename)
            ok (script) == source         # encoding=encoding
            if expected:
                output = template.render(context)
                ok (output) == expected   # encoding=encoding



#    def test_render1(self):   # Tenjin#render(context) == Tenjin#render(**context)
#        input = """<ul>
#<?py for item in items: ?>
#<li>#{item}</li>
#<?py #endfor ?>
#</ul>
#"""
#        template = tenjin.Template()
#        template.convert(input)
#        items = ['foo', 'bar', 'baz']
#        context = {'items': items}
#        output1 = template.render(context)
#        output2 = template.render(items=items)
#        ok (output2) == output1


    def test_filename1(self):
        input = """<ul>
<?py for i in range(0,3): ?>
<li>#{i}</li>
<?py #endfor ?>
</ul>
"""
        filename = 'test_filename1.tenjin'
        try:
            write_file(filename, input)
            template1 = tenjin.Template(filename)
            template2 = tenjin.Template()
            ok (template2.convert(input)) == template1.script
            ok (template2.render()) == template1.render()
        finally:
            try:
                os.remove(filename)
            except:
                pass


    def test_import_module1(self):
        import base64
        if python2:
            input = "#{base64.encodestring('tenjin')}"
        elif python3:
            if hasattr(base64, 'encodebytes'):             # python 3.1 or later
                input = "#{base64.encodebytes(b'tenjin')}"
            else:                                          # python 3.0
                input = "#{base64.encodestring(b'tenjin')}"
        template = tenjin.Template()
        template.convert(input)
        def f1():
            template.render()
        ok (f1).raises(NameError)
        #tenjin.import_module('base64')
        globals()['base64'] = base64
        #ok (f1).not_raise()
        f1()


    def test_import_module2(self):
        if python2:
            import rfc822
            input = "#{rfc822.formatdate()}"
        elif python3:
            import email.utils
            input = "#{email.utils.formatdate()}"
        template = tenjin.Template()
        template.convert(input)
        def f1():
            template.render()
        ok (f1).raises(NameError)
        if python2:
            #tenjin.import_module(rfc822)
            globals()['rfc822'] = rfc822
        elif python3:
            globals()['email'] = email
        #ok (f1).not_raise()
        f1()


    def test_invalid_template_args(self):
        def f():
            input = "<?py #@ARGS 1x ?>"
            template = tenjin.Template()
            template.convert(input)
        ok (f).raises(ValueError)


#    def test_dummy_if_stmt(self):     ## NEVER!
#        input = r"""
#<html>
#  <body>
#    <ul>
#      <?py if items: ?>
#      <?py   for item in items: ?>
#      <li>#{item}</li>
#      <?py   #endfor ?>
#      <?py #endif ?>
#    </ul>
#  </body>
#</html>
#"""[1:]
#        expected = r"""
#_extend(('''<html>
#  <body>
#    <ul>\n''', ));
#if True: ## dummy
#      if items:
#        for item in items:
#            _extend(('''      <li>''', _to_str(item), '''</li>\n''', ));
#        #endfor
#      #endif
#      _extend(('''    </ul>
#  </body>
#</html>\n''', ));
#"""[1:]
#        t = tenjin.Template()
#        actual = t.convert(input)
#        ok (actual) == expected

    lvars = "_extend=_buf.extend;_to_str=to_str;_escape=escape; "

    def test_input(self):
        input = r"""<!DOCTYPE>
<ul>
<?py for item in items: ?>
  <li>#{item}</li>
<?py #endfor ?>
</ul>
"""
        script = self.lvars + r"""_extend(('''<!DOCTYPE>
<ul>\n''', ));
for item in items:
    _extend(('''  <li>''', _to_str(item), '''</li>\n''', ));
#endfor
_extend(('''</ul>\n''', ));
"""
        t = tenjin.Template("test.foobar.pyhtml", input=input)
        if "input argument is specified then regard it as template content":
            ok (t.script) == script
        if "input argument is specified then timestamp is set to False":
            ok (t.timestamp) == False


    def test_trace(self):
        if "trace is on then prints template filename as HTML comments":
            filename = "test.trace.pyhtml"
            input = "<p>hello #{name}!</p>\n"
            expected = ( "<!-- ***** begin: %s ***** -->\n"
                         "<p>hello world!</p>\n"
                         "<!-- ***** end: %s ***** -->\n" ) % (filename, filename)
            t = tenjin.Template(filename, input=input, trace=True)
            output = t.render({'name':'world'})
            ok (output) == expected

    def test_option_tostrfunc(self):
        input = "<p>Hello #{name}!</p>"
        if "passed tostrfunc option then use it":
            globals()['my_str'] = lambda s: s.upper()
            t = tenjin.Template(None, input=input, tostrfunc='my_str')
            output = t.render({'name': 'Haruhi'})
            ok (output) == "<p>Hello HARUHI!</p>"
            ok (t.script) == self.lvars.replace('=to_str', '=my_str') + \
                             "_extend(('''<p>Hello ''', _to_str(name), '''!</p>''', ));"
            globals().pop('my_str')
            #
            t = tenjin.Template(None, input=input, tostrfunc='str')
            output = t.render({'name': None})
            ok (output) == "<p>Hello None!</p>"
            #
            t = tenjin.Template(None, input=input, tostrfunc='str.upper')
            output = t.render({'name': 'sos'})
            ok (output) == "<p>Hello SOS!</p>"
        if "passed False as tostrfunc option then no function is used":
            t = tenjin.Template(None, input=input, tostrfunc=False)
            output = t.render({'name': 'Haruhi'})
            ok (output) == "<p>Hello Haruhi!</p>"
            ok (t.script) == self.lvars.replace('=to_str', '=False') + \
                             "_extend(('''<p>Hello ''', (name), '''!</p>''', ));"
            #
            def f(): t.render({'name': 123})
            if python2:
                ok (f).raises(TypeError, 'sequence item 1: expected string, int found')
            elif python3:
                ok (f).raises(TypeError, 'sequence item 1: expected str instance, int found')
        if "passed wrong function name as tostrfunc option then raises error":
            t = tenjin.Template(None, input=input, tostrfunc='johnsmith')
            def f(): t.render({'name': 'Haruhi'})
            #ok (f).raises(TypeError, "'NoneType' object is not callable")
            ok (f).raises(NameError, "name 'johnsmith' is not defined")

    def test_option_escapefunc(self):
        input = "<p>Hello ${name}!</p>"
        if "passed escapefunc option then use it":
            globals()['my_escape'] = lambda s: s.lower()
            t = tenjin.Template(None, input=input, escapefunc='my_escape')
            output = t.render({'name': 'Haruhi'})
            ok (output) == "<p>Hello haruhi!</p>"
            ok (t.script) == self.lvars.replace('=escape', '=my_escape') + \
                             "_extend(('''<p>Hello ''', _escape(_to_str(name)), '''!</p>''', ));"
            globals().pop('my_escape')
            #
            global cgi
            import cgi
            t = tenjin.Template(None, input=input, escapefunc='cgi.escape')
            output = t.render({'name': '&<>"'})
            ok (output) == "<p>Hello &amp;&lt;&gt;\"!</p>"
        if "passed False as escapefunc option then no function is used":
            t = tenjin.Template(None, input=input, escapefunc=False)
            output = t.render({'name': 'Haru&Kyon'})
            ok (output) == "<p>Hello Haru&Kyon!</p>"
            ok (t.script) == self.lvars.replace('=escape', '=False') + \
                             "_extend(('''<p>Hello ''', _to_str(name), '''!</p>''', ));"
        if "passed wrong function name as tostrfunc option then raises error":
            t = tenjin.Template(None, input=input, escapefunc='kyonsmith')
            def f(): t.render({'name': 'Haruhi'})
            #ok (f).raises(TypeError, "'NoneType' object is not callable")
            ok (f).raises(NameError, "name 'kyonsmith' is not defined")


    def test_localvars_assignments_without_args_declaration(self):
        def _convert(input):
            return tenjin.Template(input=input).script
        if spec("add local vars assignments before text only once."):
            input = r"""
<p>
  <?py x = 10 ?>
</p>
"""[1:]
            expected = r"""
_extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''<p>\n''', ));
x = 10
_extend(('''</p>\n''', ));
"""[1:]
            ok (_convert(input)) == expected
        if spec("skips comments at the first lines."):
            input = r"""
<?py # coding: utf-8 ?>
<?py      ### comment ?>
<p>
  <?py x = 10 ?>
</p>
"""[1:]
            expected = r"""
# coding: utf-8
### comment
_extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''<p>\n''', ));
x = 10
_extend(('''</p>\n''', ));
"""[1:]
            ok (_convert(input)) == expected
        if spec("adds local vars assignments before statements."):
            input = r"""
<?py for item in items: ?>
  <?py x = 10 ?>
<?py #endfor ?>
</p>
"""[1:]
            expected = r"""
_extend=_buf.extend;_to_str=to_str;_escape=escape; 
for item in items:
    x = 10
#endfor
_extend(('''</p>\n''', ));
"""[1:]
            ok (_convert(input)) == expected

    def test_localvars_assignments_with_args_declaration(self):
        def _convert(input):
            return tenjin.Template(input=input).script
        if spec("args declaration exists before text then local vars assignments apprears at the same line with text."):
            input = r"""
<?py # coding: utf-8 ?>
<?py #@ARGS items ?>
<p>
  <?py x = 10 ?>
</p>
"""[1:]
            expected = r"""
# coding: utf-8
items = _context.get('items'); 
_extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''<p>\n''', ));
x = 10
_extend(('''</p>\n''', ));
"""[1:]
            ok (_convert(input)) == expected
        if spec("args declaration exists before statement then local vars assignments apprears at the same line with args declaration."):
            input = r"""
<?py # coding: utf-8 ?>
<?py #@ARGS items ?>
  <?py x = 10 ?>
"""[1:]
            expected = r"""
# coding: utf-8
_extend=_buf.extend;_to_str=to_str;_escape=escape; items = _context.get('items'); 
x = 10
"""[1:]
            ok (_convert(input)) == expected
        if spec("'from __future__' statement exists then skip it."):
            input = r"""
<?py from __future__ import with_statement ?>
<?py # coding: utf-8 ?>
<?py #@ARGS item ?>
item=${item}
"""[1:]
            expected = r"""
from __future__ import with_statement
# coding: utf-8
item = _context.get('item'); 
_extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''item=''', _escape(_to_str(item)), '''\n''', ));
"""[1:]
            ok (_convert(input)) == expected
            input = r"""
<?py from __future__ import with_statement ?>
<?py for item in items: ?>
  <p>${item}</p>
<?py #endfor ?>
"""[1:]
            expected = r"""
from __future__ import with_statement
_extend=_buf.extend;_to_str=to_str;_escape=escape; 
for item in items:
    _extend(('''  <p>''', _escape(_to_str(item)), '''</p>\n''', ));
#endfor
"""[1:]
            ok (_convert(input)) == expected

    def test_new_notation(self):
        input = r"""
a=${a}
b=#{b}
c={=c=}
d={==d==}
"""
        expected = r"""_extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''
a=''', _escape(_to_str(a)), '''
b=''', _to_str(b), '''
c=''', _escape(_to_str(c)), '''
d=''', _to_str(d), '''\n''', ));
"""
        t = tenjin.Template()
        ok (t.convert(input)) == expected


    def test_add_expr(self):
        input = r"""
not escape: #{var}
escape: ${var}
"""
        if spec("nothing is specified then both _to_str() and _escape() are used."):
            t = tenjin.Template()
            script = t.convert(input)
            expected = r"""_extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''
not escape: ''', _to_str(var), '''
escape: ''', _escape(_to_str(var)), '''\n''', ));
"""
            ok (script) == expected
        if spec("when tostrfunc is False then skips _to_str()."):
            expected = r"""_extend=_buf.extend;_to_str=False;_escape=escape; _extend(('''
not escape: ''', (var), '''
escape: ''', _escape(var), '''\n''', ));
"""
            t = tenjin.Template(tostrfunc=False)
            ok (t.convert(input)) == expected
        if spec("escapefunc is False then skips _escape()."):
            expected = r"""_extend=_buf.extend;_to_str=to_str;_escape=False; _extend(('''
not escape: ''', _to_str(var), '''
escape: ''', _to_str(var), '''\n''', ));
"""
            t = tenjin.Template(escapefunc=False)
            ok (t.convert(input)) == expected
        if spec("both tostr and escapefunc are False then skips _to_str() and _escape()."):
            expected = r"""_extend=_buf.extend;_to_str=False;_escape=False; _extend(('''
not escape: ''', (var), '''
escape: ''', (var), '''\n''', ));
"""
            t = tenjin.Template(tostrfunc=False, escapefunc=False)
            ok (t.convert(input)) == expected
        if spec("get_expr_and_flags() returns flag_tostr=False then ignores _escape()."):
            tr = Tracer()
            def fn(orig, *args):
                expr, (flag_escape, flag_tostr) = orig(*args)
                return expr, (flag_escape, False)
            expected = r"""_extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''
not escape: ''', (var), '''
escape: ''', _escape(var), '''\n''', ));
"""
            t = tenjin.Template()
            tr.fake_method(t, get_expr_and_flags=fn)
            ok (t.convert(input)) == expected
        if spec("get_expr_and_flags() returns flag_escape=False then ignores _escape()."):
            tr = Tracer()
            def fn(orig, *args):
                expr, (flag_escape, flag_tostr) = orig(*args)
                return expr, (False, flag_tostr)
            expected = r"""_extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''
not escape: ''', _to_str(var), '''
escape: ''', _to_str(var), '''\n''', ));
"""
            t = tenjin.Template()
            tr.fake_method(t, get_expr_and_flags=fn)
            ok (t.convert(input)) == expected
        if spec("get_expr_and_flags() returns both flags False then ignores both _to_str() and _escape()."):
            tr = Tracer()
            def fn(orig, *args):
                expr, (flag_escape, flag_tostr) = orig(*args)
                return expr, (False, False)
            expected = r"""_extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''
not escape: ''', (var), '''
escape: ''', (var), '''\n''', ));
"""
            t = tenjin.Template()
            tr.fake_method(t, get_expr_and_flags=fn)
            ok (t.convert(input)) == expected

    def test_new_cycle(self):
        cycle = tenjin.helpers.new_cycle('odd', 'even')
        ok (cycle())  == 'odd'
        ok (cycle())  == 'even'
        ok (cycle())  == 'odd'
        ok (cycle())  == 'even'
        #
        cycle = tenjin.helpers.new_cycle('A', 'B', 'C')
        ok (cycle()) == 'A'
        ok (cycle()) == 'B'
        ok (cycle()) == 'C'
        ok (cycle()) == 'A'
        ok (cycle()) == 'B'
        ok (cycle()) == 'C'
        #
        #ok (cycle()).is_a(EscapedStr)
        #ok (cycle()).is_a(EscapedStr)




if __name__ == '__main__':
    run()
