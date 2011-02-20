###
### $Release: $
### $Copyright: copyright(c) 2007-2011 kuwata-lab.com all rights reserved. $
###

from oktest import ok, not_ok, run, spec
from oktest.tracer import Tracer
import sys, os, re

import tenjin
from tenjin.helpers import *
from tenjin.escaped import *

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3

lvars = "_extend=_buf.extend;_to_str=to_str;_escape=to_escaped; "


if python2:
    from tenjin.escaped import Escaped, EscapedStr, EscapedUnicode
    def u(s):
        return s.decode('utf-8')
    def b(s):
        return s
else:
    from tenjin.escaped import Escaped, EscapedStr, EscapedBytes
    def u(s):
        return s
    def b(s):
        return s.encode('utf-8')


class EscapedStrTest(object):

    def test_is_escaped(self):
        if "arg is an instance of Escaped class then return True.":
            ok (is_escaped(EscapedStr("sos"))) == True
            if python2:
                ok (is_escaped(EscapedUnicode(u("sos")))) == True
            elif python3:
                ok (is_escaped(EscapedBytes(b("sos")))) == True
            #end
        if "arg is not an instance of Escaped class then return False.":
            ok (is_escaped("sos")) == False
            if python2:
                ok (is_escaped(u("sos"))) == False
            elif python3:
                ok (is_escaped(b("sos"))) == False
            #end

    def test_as_escaped(self):
        if "arg is a str then returns EscapedStr object.":
            ok (as_escaped("<foo>")).is_a(EscapedStr)
        if python2:
            if "arg is a unicode then returns EscapedUnicode object.":
                ok (as_escaped(u("<foo>"))).is_a(EscapedUnicode)
        elif python3:
            if "arg is a bytes then returns EscapedBytes object.":
                ok (as_escaped(b("<foo>"))).is_a(EscapedBytes)
        if "arg is not a basestring then returns TypeError.":
            def f(): as_escaped(123)
            if python2:
                ok (f).raises(TypeError, "as_escaped(123): expected str or unicode.")
            elif python3:
                ok (f).raises(TypeError, "as_escaped(123): expected str or bytes.")
        if "arg is never escaped.":
            ok (as_escaped("<foo>")) == "<foo>"
            ok (as_escaped(u("<foo>"))) == u("<foo>")

    def test_to_escaped(self):
        if "arg is escaped then returns it as-is.":
            obj = EscapedStr("<foo>")
            #ok (to_escaped(obj)).is_(obj)
            ok (to_escaped(obj)) == obj
            if python2:
                obj = EscapedUnicode(u("<foo>"))
                #ok (to_escaped(obj)).is_(obj)
                ok (to_escaped(obj)) == obj
            elif python3:
                obj = EscapedBytes(b("<foo>"))
                #ok (to_escaped(obj)).is_(obj)
                ok (to_escaped(obj)) == EscapedStr("<foo>")
        if "arg is not escaped then escapes it and returns escaped object.":
            ret = to_escaped("<foo>")
            ok (ret) == "&lt;foo&gt;"
            ok (ret).is_a(EscapedStr)
            #
            if python2:
                ret = to_escaped(u("<foo>"))
                ok (ret) == u("&lt;foo&gt;")
                ok (ret).is_a(EscapedStr)     # not EscapedUnicode!
            elif python3:
                #ret = to_escaped(b("<foo>"))
                #ok (ret) == b("&lt;foo&gt;")
                #ok (ret).is_a(EscapedBytes)
                ret = to_escaped(to_str(b("<foo>")))
                ok (ret) == "&lt;foo&gt;"
                ok (ret).is_a(EscapedStr)
        if "arg is not a basestring then calls to_str() and escape(), and returns EscapedStr":
            ret = to_escaped(None)
            ok (ret) == ""
            ok (ret).is_a(EscapedStr)
            ret = to_escaped(123)
            ok (ret) == "123"
            ok (ret).is_a(EscapedStr)
        if "arg has __html__() method then calls it.":
            tr = Tracer()
            obj = tr.fake_obj(__html__="<b>OK</b>")
            ret = to_escaped(obj)
            ok (ret) == "&lt;b&gt;OK&lt;/b&gt;"
            ok (ret).is_a(EscapedStr)
            ok (tr[-1].name) == '__html__'
            #
            obj = tr.fake_obj(__html__=as_escaped("<b>WaWaWa</b>"))
            ret = to_escaped(obj)
            ok (ret) == "<b>WaWaWa</b>"
            ok (ret).is_a(EscapedStr)
            ok (tr[-1].name) == '__html__'


class SafeTemplateTest(object):

    input = ( "<?py for item in items: ?>\n"
              "<p>{=item=}</p>\n"
              "<?py #end ?>\n" )
    context = { 'items': [ '<>&"', as_escaped('<>&"') ] }
    expected = ( "<p>&lt;&gt;&amp;&quot;</p>\n"
                 "<p><>&\"</p>\n" )

    def test_get_expr_and_flags(self):
        t = tenjin.SafeTemplate()
        if "matched expression is '${...}' then returns expr string and True":
            m = t.expr_pattern().search("<p>${item}</p>")
            ret = t.get_expr_and_flags(m)
            ok (ret) == ('item', (True, False))
        if "matched expression is '#{...}' then raises error":
            m = t.expr_pattern().search("<p>#{item}</p>")
            def f(): t.get_expr_and_flags(m)
            ok (f).raises(tenjin.TemplateSyntaxError,
                          "#{item}: '#{}' is not allowed with SafeTemplate.")
        if "matched expression is '{=...=}' then returns expr string and True":
            m = t.expr_pattern().search("<p>{=item=}</p>")
            ret = t.get_expr_and_flags(m)
            ok (ret) == ('item', (True, False))
        if "matched expression is '{==...==}' then returns expr string and False":
            m = t.expr_pattern().search("<p>{==item==}</p>")
            ret = t.get_expr_and_flags(m)
            ok (ret) == ('item', (False, True))

    def test_FUNCTEST_of_convert(self):
        if "converted then use 'to_escaped()' instead of 'escape()'":
            t = tenjin.SafeTemplate(input="<p>{=item=}</p>")
            ok (t.script) == lvars + "_extend(('''<p>''', _escape(item), '''</p>''', ));"
        if "{==...==} exists then skips to escape by to_escaped()":
            t = tenjin.SafeTemplate(input="<p>{==foo()==}</p>")
            ok (t.script) == lvars + "_extend(('''<p>''', _to_str(foo()), '''</p>''', ));"

    def test_FUNCTEST_of_render(self):
        if "rendered then avoid escaping of escaped object":
            input    = "var1: {=var1=}, var2: {=var2=}\n"
            context  = {'var1': '<>&"', 'var2': as_escaped('<>&"')}
            expected = "var1: &lt;&gt;&amp;&quot;, var2: <>&\"\n"
            t = tenjin.SafeTemplate(input=input)
            ok (t.render(context)) == expected
            #
            if python2:
                u = unicode
                input    = "var1: {=var1=}, var2: {=var2=}\n"
                context  = {'var1': u('<>&"'), 'var2': as_escaped(u('<>&"'))}
                expected = "var1: &lt;&gt;&amp;&quot;, var2: <>&\"\n"
                t = tenjin.SafeTemplate(input=input)
                ok (t.render(context)) == expected

    def test_FUNCTEST_with_engine(self):
        fname = 'test_safe_template.pyhtml'
        try:
            _tclass = tenjin.Engine.templateclass
            tenjin.Engine.templateclass = tenjin.SafeTemplate
            open(fname, 'w').write(self.input)
            engine = tenjin.Engine()
            output = engine.render(fname, self.context.copy())
            ok (output) == self.expected
        finally:
            tenjin.Engine.templateclass = _tclass
            for x in [fname, fname+'.cache']:
                os.path.isfile(x) and os.unlink(x)


class SafePreprocessorTest(object):

    input = ( "<?PY for i in range(2): ?>\n"
              "<h1>{#=i=#}</h1>\n"
              "<?py for item in items: ?>\n"
              "<p>{=item=}</p>\n"
              "<?py #end ?>\n"
              "<?PY #end ?>\n" )
    context = { 'items': [ '<>&"', as_escaped('<>&"') ] }
    expected = ( "<h1>1</h1>\n"
                 "<?py for item in items: ?>\n"
                 "<p>{=item=}</p>\n"
                 "<?py #end ?>\n"
                 "<h1>2</h1>\n"
                 "<?py for item in items: ?>\n"
                 "<p>{=item=}</p>\n"
                 "<?py #end ?>\n" )
    expected_script = lvars + r"""
_extend(('''<h1>0</h1>\n''', ));
for item in items:
    _extend(('''<p>''', _escape(item), '''</p>\n''', ));
#end
_extend(('''<h1>1</h1>\n''', ));
for item in items:
    _extend(('''<p>''', _escape(item), '''</p>\n''', ));
#end
"""[1:]

    def test_get_expr_and_flags(self):
        t = tenjin.SafePreprocessor()
        if "matched expression is '${{...}}' then returns expr string and True":
            m = t.expr_pattern().search("<p>${{item}}</p>")
            ret = t.get_expr_and_flags(m)
            ok (ret) == ('item', (True, False))
        if "matched expression is '#{{...}}' then raises error":
            m = t.expr_pattern().search("<p>#{{item}}</p>")
            def f(): t.get_expr_and_flags(m)
            ok (f).raises(tenjin.TemplateSyntaxError,
                          "#{{item}}: '#{{}}' is not allowed with SafePreprocessor.")
        if "matched expression is '{#=...=#}' then returns expr string and True":
            m = t.expr_pattern().search("<p>{#=item=#}</p>")
            ret = t.get_expr_and_flags(m)
            ok (ret) == ('item', (True, False))
        if "matched expression is '{#==...==#}' then returns expr string and False":
            m = t.expr_pattern().search("<p>{#==item==#}</p>")
            ret = t.get_expr_and_flags(m)
            ok (ret) == ('item', (False, True))

    def test_FUNCTEST_with_engine(self):
        fname = 'test_safe_preprocessor.pyhtml'
        self._unlink = [fname, fname + '.cache']
        try:
            _backup = tenjin.Engine.templateclass
            tenjin.Engine.templateclass = tenjin.SafeTemplate
            open(fname, 'w').write(self.input)
            engine = tenjin.Engine(preprocess=True, preprocessorclass=tenjin.SafePreprocessor)
            t = engine.get_template(fname)
            ok (t.script) == self.expected_script
        finally:
            tenjin.Engine.templateclass = _backup
            for x in [fname, fname+'.cache']:
                os.path.isfile(x) and os.unlink(x)


def _with_template(fname, content):
    def deco(func):
        def newfunc(*args):
            try:
                f = open(fname, 'w')
                f.write(content)
                f.close()
                func()
            finally:
                for x in [fname, fname+'.cache']:
                    if os.path.isfile(x):
                        os.unlink(x)
        return newfunc
    return deco


class SafeEngineTest(object):

    def test_FUNCTEST_render(self):
        fname = 'test_safe_engine_render.pyhtml'
        input = r"""
<p>v1={=v1=}</p>
<p>v2={=v2=}</p>
<p>v1={==v1==}</p>
<p>v2={==v2==}</p>
"""[1:]
        expected = r"""
<p>v1=&lt;&amp;&gt;</p>
<p>v2=<&></p>
<p>v1=<&></p>
<p>v2=<&></p>
"""[1:]
        @_with_template(fname, input)
        def f():
            engine = tenjin.SafeEngine()
            context = { 'v1': '<&>', 'v2': as_escaped('<&>'), }
            output = engine.render(fname, context)
            ok (output) == expected
        f()

    def test_FUNCTEST_preprocessing2(self):
        fname = 'test_safe_engine_preprocessing2.pyhtml'
        input = r'''
  <h1>{=title=}</h1>
  <ul>
  <?PY for wday in WDAYS: ?>
    <li>{#=wday=#}</li>
  <?PY #endfor ?>
  <ul>
  <div>{#=COPYRIGHT=#}</div>
'''[1:]
        expected_output = r'''
  <h1>SafeEngine Example</h1>
  <ul>
    <li>Su</li>
    <li>M</li>
    <li>Tu</li>
    <li>W</li>
    <li>Th</li>
    <li>F</li>
    <li>Sa</li>
  <ul>
  <div>copyright(c)2010 kuwata-lab.com</div>
'''[1:]
        expected_script = lvars + r"""
_extend(('''  <h1>''', _escape(title), '''</h1>
  <ul>
    <li>Su</li>
    <li>M</li>
    <li>Tu</li>
    <li>W</li>
    <li>Th</li>
    <li>F</li>
    <li>Sa</li>
  <ul>
  <div>copyright(c)2010 kuwata-lab.com</div>\n''', ));
"""[1:]
        @_with_template(fname, input)
        def f():
            f = open(fname, 'w')
            f.write(input)
            f.close()
            engine = tenjin.SafeEngine(preprocess=True)
            context = {
                'title': 'SafeEngine Example',
                'WDAYS': ['Su', 'M', 'Tu', 'W', 'Th','F', 'Sa'],
                'COPYRIGHT': 'copyright(c)2010 kuwata-lab.com',
            }
            output = engine.render(fname, context)
            ok (output) == expected_output
            ok (engine.get_template(fname).script) == expected_script
        f()


if __name__ == '__main__':
    run()
