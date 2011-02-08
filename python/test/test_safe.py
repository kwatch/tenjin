###
### $Release:$
### $Copyright$
###

from oktest import ok, not_ok, run
import sys, os, re

import tenjin
from tenjin.helpers import *

python3 = sys.version_info[0] == 3


class SafeStrTest(object):

    def test___init__(self):
        if "arg is a string then keeps it to 'value' attr":
            s = '<foo>'
            ok (SafeStr(s).value).is_(s)
        if "arg is not a basestring then raises error":
            def f(): SafeStr(123)
            ok (f).raises(TypeError, "123 is not a string.")
            def f(): SafeStr(None)
            ok (f).raises(TypeError, "None is not a string.")

    def test___str__(self):
        if "called then returns itself":
            hs = SafeStr('foo')
            ok (hs.__str__()).is_(hs)
            ok (str(hs)).is_(hs)

    def test___unicode__(str):
        if python3:
            return
        if "called then returns itself":
            hs = SafeStr('foo')
            ok (hs.__unicode__()).is_(hs)
            #ok (unicode(hs)) == u'foo'
            ok (unicode(hs)) == 'foo'.decode('utf-8')


class SafeTemplateTest(object):

    input = ( "<?py for item in items: ?>\n"
              "<p>${item}</p>\n"
              "<?py #end ?>\n" )
    context = { 'items': [ '<>&"', SafeStr('<>&"') ] }
    expected = ( "<p>&lt;&gt;&amp;&quot;</p>\n"
                 "<p><>&\"</p>\n" )

    def test_get_expr_and_escapeflag(self):
        t = tenjin.SafeTemplate()
        if "matched expression is '${}' then returns expr string and True":
            m = t.expr_pattern().search("<p>${item}</p>")
            ret = t.get_expr_and_escapeflag(m)
            ok (ret) == ('item', True)
        if "matched expression is '#{}' then raises error":
            m = t.expr_pattern().search("<p>#{item}</p>")
            def f(): t.get_expr_and_escapeflag(m)
            ok (f).raises(tenjin.TemplateSyntaxError,
                          "'#{item}': '#{}' is not available in SafeTemplate.")
        if "expr is 'SafeStr(x)' then returns 'x' instead of expr":
            m = t.expr_pattern().search("<p>${SafeStr(foo())}</p>")
            ret = t.get_expr_and_escapeflag(m)
            ok (ret) == ('foo()', False)

    def test_FUNCTEST_of_convert(self):
        if "input contains '#{}' then raises error":
            def f(): tenjin.SafeTemplate(input=self.input.replace('$', '#'))
            ok (f).raises(tenjin.TemplateSyntaxError,
                          "'#{item}': '#{}' is not available in SafeTemplate.")
        if "converted then use 'safe_escape()' instead of 'escape()'":
            t = tenjin.SafeTemplate(input="<p>${item}</p>")
            ok (t.script) == "_extend(('''<p>''', _escape(_to_str(item)), '''</p>''', ));"
        if "${SafeStr(...)} exists then skips to escape by safe_escape()":
            t = tenjin.SafeTemplate(input="<p>${SafeStr(foo())}</p>")
            ok (t.script) == "_extend(('''<p>''', _to_str(foo()), '''</p>''', ));"

    def test_FUNCTEST_of_render(self):
        if "rendered then avoid escape of SafeStr object":
            t = tenjin.SafeTemplate(input=self.input)
            context = self.context.copy()
            ok (t.render(context)) == self.expected

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
              "<h1>${{i}}</h1>\n"
              "<?py for item in items: ?>\n"
              "<p>${item}</p>\n"
              "<?py #end ?>\n"
              "<?PY #end ?>\n" )
    context = { 'items': [ '<>&"', SafeStr('<>&"') ] }
    expected = ( "<h1>1</h1>\n"
                 "<?py for item in items: ?>\n"
                 "<p>${item}</p>\n"
                 "<?py #end ?>\n"
                 "<h1>2</h1>\n"
                 "<?py for item in items: ?>\n"
                 "<p>${item}</p>\n"
                 "<?py #end ?>\n" )
    expected_script = r"""
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
        if "matched expression is '${{}}' then returns expr string and True":
            m = t.expr_pattern().search("<p>${{item}}</p>")
            ret = t.get_expr_and_escapeflag(m)
            ok (ret) == ('item', True)
        if "matched expression is '#{{}}' then raises error":
            m = t.expr_pattern().search("<p>#{{item}}</p>")
            def f(): t.get_expr_and_escapeflag(m)
            ok (f).raises(tenjin.TemplateSyntaxError,
                          "'#{{item}}': '#{{}}' is not available in SafePreprocessor.")

    def test_FUNCTEST_with_engine(self):
        fname = 'test_safe_preprocessor.pyhtml'
        self._unlink = [fname, fname + '.cache']
        try:
            _backup = tenjin.Engine.templateclass
            tenjin.Engine.templateclass = tenjin.SafeTemplate
            open(fname, 'w').write(self.input)
            engine = tenjin.Engine(preprocess=tenjin.SafePreprocessor)
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

    def test_FUNCTEST_convert(self):
        fname = 'test_safe_engine_convert.pyhtml'
        input = r"""Hello #{name}!"""
        @_with_template(fname, input)
        def f():
            engine = tenjin.SafeEngine()
            def f(): engine.render(fname, {'name': 'World'})
            ok (f).raises(tenjin.TemplateSyntaxError, "'#{name}': '#{}' is not available in SafeTemplate.")
        f()

    def test_FUNCTEST_render(self):
        fname = 'test_safe_engine_render.pyhtml'
        input = r"""
<p>v1=${v1}</p>
<p>v2=${v2}</p>
<p>SafeStr(v1)=${SafeStr(v1)}</p>
<p>SafeStr(v2)=${SafeStr(v2)}</p>
"""[1:]
        expected = r"""
<p>v1=&lt;&amp;&gt;</p>
<p>v2=<&></p>
<p>SafeStr(v1)=<&></p>
<p>SafeStr(v2)=<&></p>
"""[1:]
        @_with_template(fname, input)
        def f():
            engine = tenjin.SafeEngine()
            context = { 'v1': '<&>', 'v2': SafeStr('<&>'), }
            output = engine.render(fname, context)
            ok (output) == expected
        f()

    def test_FUNCTEST_preprocessing1(self):
        fname = 'test_safe_engine_preprocessing1.pyhtml'
        input = r"""Hello #{{name}}!"""
        @_with_template(fname, input)
        def f():
            engine = tenjin.SafeEngine(preprocess=True)
            def f(): engine.get_template(fname, {'name': 'World'})
            ok (f).raises(tenjin.TemplateSyntaxError,
                          "'#{{name}}': '#{{}}' is not available in SafePreprocessor.")
        f()

    def test_FUNCTEST_preprocessing2(self):
        fname = 'test_safe_engine_preprocessing2.pyhtml'
        input = r'''
  <h1>${title}</h1>
  <ul>
  <?PY for wday in WDAYS: ?>
    <li>${{wday}}</li>
  <?PY #endfor ?>
  <ul>
  <div>${{COPYRIGHT}}</div>
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
        expected_script = r"""
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
