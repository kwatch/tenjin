###
### $Release:$
### $Copyright$
###

from oktest import ok, not_ok, run, spec
import sys, os, re

import tenjin
from tenjin.helpers import *

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3

lvars = "_extend=_buf.extend;_to_str=to_str;_escape=safe_escape; "


class EscapedStrTest(object):

    def test_mark_as_escaped(self):
        if "arg is a str then returns EscapedStr object.":
            ok (mark_as_escaped("<foo>")).is_a(EscapedStr)
        if "arg is a unicode then returns EscapedUnicode object.":
            ok (mark_as_escaped(u"<foo>")).is_a(EscapedUnicode)
        if "arg is not a basestring then returns TypeError.":
            def f(): mark_as_escaped(123)
            ok (f).raises(TypeError, "mark_as_escaped(123): expected str or unicode.")
        if "arg is never escaped.":
            ok (mark_as_escaped("<foo>")) == "<foo>"
            ok (mark_as_escaped(u"<foo>")) == u"<foo>"

    def test_safe_escape(self):
        if "arg is escaped then returns it as-is.":
            obj = EscapedStr("<foo>")
            ok (safe_escape(obj)).is_(obj)
            obj = EscapedUnicode(u"<foo>")
            ok (safe_escape(obj)).is_(obj)
        if "arg is not escaped then escapes it and returns escaped object.":
            ret = safe_escape("<foo>")
            ok (ret) == "&lt;foo&gt;"
            ok (ret).is_a(EscapedStr)
            #
            ret = safe_escape(u"<foo>")
            ok (ret) == u"&lt;foo&gt;"
            ok (ret).is_a(EscapedUnicode)
        if "arg is not a basestring then calls to_str() and escape(), and returns EscapedStr":
            ret = safe_escape(None)
            ok (ret) == ""
            ok (ret).is_a(EscapedStr)
            ret = safe_escape(123)
            ok (ret) == "123"
            ok (ret).is_a(EscapedStr)


class SafeTemplateTest(object):

    input = ( "<?py for item in items: ?>\n"
              "<p>{=item=}</p>\n"
              "<?py #end ?>\n" )
    context = { 'items': [ '<>&"', mark_as_escaped('<>&"') ] }
    expected = ( "<p>&lt;&gt;&amp;&quot;</p>\n"
                 "<p><>&\"</p>\n" )

    def test_get_expr_and_escapeflag(self):
        t = tenjin.SafeTemplate()
        if "matched expression is '{=...=}' then returns expr string and True":
            m = t.expr_pattern().search("<p>{=item=}</p>")
            ret = t.get_expr_and_escapeflag(m)
            ok (ret) == ('item', True)
        if "matched expression is '{==...==}' then returns expr string and False":
            m = t.expr_pattern().search("<p>{==item==}</p>")
            ret = t.get_expr_and_escapeflag(m)
            ok (ret) == ('item', False)

    def test_FUNCTEST_of_convert(self):
        if "converted then use 'safe_escape()' instead of 'escape()'":
            t = tenjin.SafeTemplate(input="<p>{=item=}</p>")
            ok (t.script) == lvars + "_extend(('''<p>''', _escape(_to_str(item)), '''</p>''', ));"
        if "{==...==} exists then skips to escape by safe_escape()":
            t = tenjin.SafeTemplate(input="<p>{==foo()==}</p>")
            ok (t.script) == lvars + "_extend(('''<p>''', _to_str(foo()), '''</p>''', ));"

    def test_FUNCTEST_of_render(self):
        if "rendered then avoid escaping of escaped object":
            input    = "var1: {=var1=}, var2: {=var2=}\n"
            context  = {'var1': '<>&"', 'var2': mark_as_escaped('<>&"')}
            expected = "var1: &lt;&gt;&amp;&quot;, var2: <>&\"\n"
            t = tenjin.SafeTemplate(input=input)
            ok (t.render(context)) == expected
            #
            if python2:
                u = unicode
                input    = "var1: {=var1=}, var2: {=var2=}\n"
                context  = {'var1': u('<>&"'), 'var2': mark_as_escaped(u('<>&"'))}
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
              "<h1>{|=i=|}</h1>\n"
              "<?py for item in items: ?>\n"
              "<p>{=item=}</p>\n"
              "<?py #end ?>\n"
              "<?PY #end ?>\n" )
    context = { 'items': [ '<>&"', mark_as_escaped('<>&"') ] }
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
    _extend(('''<p>''', _escape(_to_str(item)), '''</p>\n''', ));
#end
_extend(('''<h1>1</h1>\n''', ));
for item in items:
    _extend(('''<p>''', _escape(_to_str(item)), '''</p>\n''', ));
#end
"""[1:]

    def test_get_expr_and_escapeflag(self):
        t = tenjin.SafePreprocessor()
        if "matched expression is '{|=...=|}' then returns expr string and True":
            m = t.expr_pattern().search("<p>{|=item=|}</p>")
            ret = t.get_expr_and_escapeflag(m)
            ok (ret) == ('item', True)
        if "matched expression is '{|==...==|}' then returns expr string and False":
            m = t.expr_pattern().search("<p>{|==item==|}</p>")
            ret = t.get_expr_and_escapeflag(m)
            ok (ret) == ('item', False)

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
            context = { 'v1': '<&>', 'v2': mark_as_escaped('<&>'), }
            output = engine.render(fname, context)
            ok (output) == expected
        f()

    def test_FUNCTEST_preprocessing2(self):
        fname = 'test_safe_engine_preprocessing2.pyhtml'
        input = r'''
  <h1>{=title=}</h1>
  <ul>
  <?PY for wday in WDAYS: ?>
    <li>{|=wday=|}</li>
  <?PY #endfor ?>
  <ul>
  <div>{|=COPYRIGHT=|}</div>
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
_extend(('''  <h1>''', _escape(_to_str(title)), '''</h1>
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
