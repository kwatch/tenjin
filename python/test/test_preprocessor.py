###
### $Release: $
### $Copyright: copyright(c) 2007-2012 kuwata-lab.com all rights reserved. $
###

import sys, os, re, time
from glob import glob
from oktest import ok, not_ok, run, test, todo
from oktest.dummy import dummy_file

import tenjin
#from tenjin.helpers import escape, to_str
from tenjin.helpers import *

lvars = "_extend=_buf.extend;_to_str=to_str;_escape=escape; "


class PreprocessorTest(object):

    INPUT = r"""
	<?PY WEEKDAY = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'] ?>
	<select>
	<?py curr = params.get('wday') ?>
	<?PY for i, wday in enumerate(WEEKDAY): ?>
	  <option value="#{{i}}"#{selected(curr==#{{i}})}>${{wday}}</option>
	<?PY #endfor ?>
	</select>
	"""[1:].replace("\t", "")
    SCRIPT = lvars + r"""
	WEEKDAY = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
	_extend(('''<select>
	<?py curr = params.get(\'wday\') ?>\n''', ));
	for i, wday in enumerate(WEEKDAY):
	    _extend(('''  <option value="''', _to_str(_decode_params(i)), '''"#{selected(curr==''', _to_str(_decode_params(i)), ''')}>''', _escape(_to_str(_decode_params(wday))), '''</option>\n''', ));
	#endfor
	_extend(('''</select>\n''', ));
	"""[1:].replace("\t", "")
    OUTPUT = r"""
	<select>
	<?py curr = params.get('wday') ?>
	  <option value="0"#{selected(curr==0)}>Sun</option>
	  <option value="1"#{selected(curr==1)}>Mon</option>
	  <option value="2"#{selected(curr==2)}>Tue</option>
	  <option value="3"#{selected(curr==3)}>Wed</option>
	  <option value="4"#{selected(curr==4)}>Thu</option>
	  <option value="5"#{selected(curr==5)}>Fri</option>
	  <option value="6"#{selected(curr==6)}>Sat</option>
	</select>
	"""[1:].replace("\t", "")

    def test_preprocessor_class(self):
        input  = self.INPUT
        script = self.SCRIPT
        output = self.OUTPUT
        filename = 'test_preprocess1.pyhtml'
        @dummy_file(filename, input)
        def _():
            preprocessor = tenjin.Preprocessor(filename)
            ok (preprocessor.script) == script
            ok (preprocessor.render()) == output

    @test("'{}' is available in '${{}}' or '#{}}}', such as '${{foo({'x':1})}}'")
    def _(self):
        input = """
<p>${{f({'a':1})+g({'b':2})}}</p>
<p>#{{f({'c':3})+g({'d':4})}}</p>
"""
        expected = r"""_extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''
<p>''', _escape(_to_str(_decode_params(f({'a':1})+g({'b':2})))), '''</p>
<p>''', _to_str(_decode_params(f({'c':3})+g({'d':4}))), '''</p>\n''', ));
"""
        t = tenjin.Preprocessor()
        script = t.convert(input)
        ok (script) == expected



class TemplatePreprocessorTest(object):

    INPUT = r"""
<div>
  <?PY for item in items: ?>
  <?py for item in items: ?>
    <i>#{item}</i>
    <i>${item}</i>
    <b>#{{item}}</b>
    <b>${{item}}</b>
  <?py #endfor ?>
  <?PY #endfor ?>
</div>
"""[1:]

    EXPECTED = r"""
<div>
  <?py for item in items: ?>
    <i>#{item}</i>
    <i>${item}</i>
    <b><AAA></b>
    <b>&lt;AAA&gt;</b>
  <?py #endfor ?>
  <?py for item in items: ?>
    <i>#{item}</i>
    <i>${item}</i>
    <b>B&B</b>
    <b>B&amp;B</b>
  <?py #endfor ?>
</div>
"""[1:]

    def test_call(self):
        input, expected = self.INPUT, self.EXPECTED
        context = { 'items': ["<AAA>", "B&B"] }
        pp = tenjin.TemplatePreprocessor()
        ok (pp(input, filename="foobar.rhtml", context=context)) == expected

    @test("#__init__(): takes preprocessor class.")
    def _(self):
        pp = tenjin.TemplatePreprocessor(tenjin.SafePreprocessor)
        ok (pp.factory) == tenjin.SafePreprocessor

    @test("#__init__(): default preprocessor class is tenjin.Preprocessor.")
    def _(self):
        pp = tenjin.TemplatePreprocessor()
        ok (pp.factory) == tenjin.Preprocessor

    @test("#__call__(): creates preprocessor object with specified class.")
    def _(self):
        input = self.INPUT
        context = { 'items': ["<AAA>", "B&B"] }
        def fn(): pp(input, filename="foobar.pyhtml", context=context)
        #
        pp = tenjin.TemplatePreprocessor(tenjin.Preprocessor)
        ok (fn).not_raise()
        #
        pp = tenjin.TemplatePreprocessor(tenjin.SafePreprocessor)
        ok (fn).raises(tenjin.TemplateSyntaxError, "#{{item}}: '#{{}}' is not allowed with SafePreprocessor.")


class TrimPreprocessorTest(object):

    INPUT = r"""
<ul>
  <?py i = 0 ?>
  <?py for item in items:
         i += 1 ?>
    <li>${item}</li>
  <?py #endfor ?>
</ul>
"""[1:]

    @test("remove spaces before '<' at beginning of line")
    def _(self):
        expected = r"""
<ul>
<?py i = 0 ?>
<?py for item in items:
         i += 1 ?>
<li>${item}</li>
<?py #endfor ?>
</ul>
"""[1:]
        input = self.INPUT
        pp = tenjin.TrimPreprocessor()
        ok (pp(input)) == expected

    @test("remove all spaces at beginning of line when argument 'all' is true")
    def _(self):
        expected = r"""
<ul>
<?py i = 0 ?>
<?py for item in items:
i += 1 ?>
<li>${item}</li>
<?py #endfor ?>
</ul>
"""[1:]
        input = self.INPUT
        pp = tenjin.TrimPreprocessor(True)
        ok (pp(input)) == expected


class PrefixedLinePreprocessorTest(object):

    @test("converts lines which has prefix (':: ') into '<?py ... ?>'.")
    def _(self):
        input = r"""
<ul>
:: i = 0
:: for item in items:
::     i += 1
  <li>${item}</li>
:: #endfor
</ul>
"""[1:]
        expected = r"""
<ul>
<?py i = 0 ?>
<?py for item in items: ?>
<?py     i += 1 ?>
  <li>${item}</li>
<?py #endfor ?>
</ul>
"""[1:]
        pp = tenjin.PrefixedLinePreprocessor()
        ok (pp(input)) == expected

    @test("able to mix '<?py ... ?>' and ':: '.")
    def _(self):
        input = r"""
<ul>
:: i = 0
<?py for item in items: ?>
  ::  i += 1
  <li>${item}</li>
<?py #endfor ?>
</ul>
"""[1:]
        expected = r"""
<ul>
<?py i = 0 ?>
<?py for item in items: ?>
  <?py  i += 1 ?>
  <li>${item}</li>
<?py #endfor ?>
</ul>
"""[1:]
        pp = tenjin.PrefixedLinePreprocessor()
        ok (pp(input)) == expected


class JavaScriptPreprocessorTest(object):

    INPUT = r"""
<table>
  <!-- #JS: render_table(items) -->
  <tbody>
    <?js for (var i = 0, n = items.length; i < n; i++) { ?>
    <tr>
      <td>#{i+1}</td>
      <td>${items[i]}</td>
    </tr>
    <?js } ?>
  </tbody>
  <!-- #/JS -->
</table>
<!-- #JS: show_user(username) -->
  <div>Hello ${username}!</div>
<!-- #/JS -->
"""[1:]

    OUTPUT = r"""
<table>
  <script>function render_table(items){var _buf='';
_buf+='  <tbody>\n';
     for (var i = 0, n = items.length; i < n; i++) {
_buf+='    <tr>\n\
      <td>'+_S(i+1)+'</td>\n\
      <td>'+_E(items[i])+'</td>\n\
    </tr>\n';
     }
_buf+='  </tbody>\n';
  return _buf;};</script>
</table>
<script>function show_user(username){var _buf='';
_buf+='  <div>Hello '+_E(username)+'!</div>\n';
return _buf;};</script>
"""[1:]

    def provide_pp(self):
        return tenjin.JavaScriptPreprocessor()

    def provide_fname(self):
        return "_test_pp.rbhtml"

    @test("converts embedded javascript template into client-side template function")
    def _(self, pp, fname):
        ok (pp(self.INPUT, filename=fname)) == self.OUTPUT

    @test("raises error when extra '#/JS' found")
    def _(self, pp, fname):
        def fn(): pp("foo\n<!-- #/JS -->\n", filename=fname)
        ok (fn).raises(tenjin.ParseError, "unexpected '<!-- #/JS -->'. (file: _test_pp.rbhtml, line: 2)")

    @test("raises error when '#JS' doesn't contain function name")
    def _(self, pp, fname):
        @todo
        def func():
            def fn(): pp("foo\n<!-- #JS -->\n", filename=fname)
            ok (fn).raises(tenjin.ParseError, "'#JS' found but not function name")
        func()

    @test("raises error when '#JS' is not closed")
    def _(self, pp, fname):
        def fn(): pp("foo\n<!-- #JS: render_table(items) -->\nxxx", filename=fname)
        ok (fn).raises(tenjin.ParseError, "render_table(items) is not closed by '<!-- #/JS -->'. (file: %s, line: 2)" % (fname,))

    @test("raises error when '#JS' is nested")
    def _(self, pp, fname):
        input = r"""
<!-- #JS: outer(items) -->
  <!-- #JS: inner(items) -->
  <!-- #/JS -->
<!-- #/JS -->
"""[1:]
        def fn(): pp(input, filename=fname)
        ok (fn).raises(tenjin.ParseError, "inner(items) is nested in outer(items). (file: %s, line: 2)" % (fname,))

    @test("raises error when func name on '#/JS' is different from that of '#JS")
    def _(self, pp, fname):
        @todo
        def func():
            input = r"""
<!-- #JS: foo(items) -->
<!-- #/JS: bar() -->
"""[1:]
            def fn(): pp(input, filename=fname)
            ok (fn).raises(tenjin.ParseError, "'#/JS: foo()' expected but got '#/JS: bar()'")
        func()

    @test("JS_FUNC: contains JS functions necessary.")
    def _(self):
        ok (tenjin.JS_FUNC).matches('function _E\(.*?\)')
        ok (tenjin.JS_FUNC).matches('function _S\(.*?\)')

    @test("JS_FUNC: is a EscapedStr.")
    def _(self):
        ok (tenjin.JS_FUNC).is_a(tenjin.escaped.EscapedStr)

    @test("#__init__(): can take attrubtes of <script> tag")
    def _(self, pp, fname):
        input = self.INPUT
        expected = self.OUTPUT.replace('<script>', '<script type="text/javascript">')
        pp = tenjin.JavaScriptPreprocessor(type='text/javascript')
        actual = pp(input, filename=fname)
        ok (actual) == expected

    @test("#parse(): converts JS template into JS code.")
    def _(self, pp):
        input = r"""
<div>
  <!-- #JS: render_table(items) -->
  <table>
    <?js for (var i = 0, n = items.length; i < n; i++) {
         var item = items[i]; ?>
    <span><?js
      var klass = i % 2 ? 'odd' : 'even'; ?></span>
    <tr>
      <td>{=item=}</td>
    </tr>
    <?js	} ?>
  </table>
  <!-- #/JS -->
</div>
"""[1:]
        expected = r"""
<div>
  <script>function render_table(items){var _buf='';
_buf+='  <table>\n';
     for (var i = 0, n = items.length; i < n; i++) {
         var item = items[i];
_buf+='    <span>';
      var klass = i % 2 ? 'odd' : 'even';_buf+='</span>\n\
    <tr>\n\
      <td>'+_E(item)+'</td>\n\
    </tr>\n';
    	}
_buf+='  </table>\n';
  return _buf;};</script>
</div>
"""[1:]
        output = pp.parse(input)
        ok (output) == expected

    @test("#parse(): escapes {=expr=} but not {==expr==}.")
    def _(self, pp):
        input = r"""
<!-- #JS: render() -->
<b>{=var1=}</b><b>{==var2==}</b>
<!-- #/JS -->
"""[1:]
        expected = r"""
<script>function render(){var _buf='';
_buf+='<b>'+_E(var1)+'</b><b>'+_S(var2)+'</b>\n';
return _buf;};</script>
"""[1:]
        output = pp.parse(input)
        ok (output) == expected

    @test("#parse(): supports both ${expr} and #{expr} in addition to {= =}.")
    def _(self, pp):
        input = r"""
<!-- #JS: render() -->
<b>${var1}</b><b>#{var2}</b>
<!-- #/JS -->
"""[1:]
        expected = r"""
<script>function render(){var _buf='';
_buf+='<b>'+_E(var1)+'</b><b>'+_S(var2)+'</b>\n';
return _buf;};</script>
"""[1:]
        output = pp.parse(input)
        ok (output) == expected

    @test("#parse(): can parse '${f({x:1})+f({y:2})}'.")
    def _(self, pp):
        input = r"""
<!-- #JS: render() -->
<p>${f({x:1})+f({y:2})}</p>
<!-- #/JS -->
"""[1:]
        expected = r"""
<script>function render(){var _buf='';
_buf+='<p>'+_E(f({x:1})+f({y:2}))+'</p>\n';
return _buf;};</script>
"""[1:]
        output = pp.parse(input)
        ok (output) == expected

    @test("#parse(): switches to function assignment when function name contains symbol.")
    def _(self, pp):
        input = r"""
<!-- #JS: $jQuery.render_title(title) -->
<h1>${title}</h1>
<!-- #/JS -->
"""[1:]
        expected = r"""
<script>$jQuery.render_title=function(title){var _buf='';
_buf+='<h1>'+_E(title)+'</h1>\n';
return _buf;};</script>
"""[1:]
        output = pp.parse(input)
        ok (output) == expected

    @test("#parse(): escapes single quotation and backslash.")
    def _(self, pp):
        input = r"""
<!-- #JS: render() -->
<h1>'Quote' and \Escape\n</h1>
<!-- #/JS -->
"""[1:]
        expected = r"""
<script>function render(){var _buf='';
_buf+='<h1>\'Quote\' and \\Escape\\n</h1>\n';
return _buf;};</script>
"""[1:]
        output = pp.parse(input)
        ok (output) == expected



if __name__ == '__main__':
    run()
