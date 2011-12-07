###
### $Release: $
### $Copyright: copyright(c) 2007-2011 kuwata-lab.com all rights reserved. $
###

import sys, os, re, time
from glob import glob
from oktest import ok, not_ok, run, test
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
        ok (pp(input, "foobar.rhtml", context)) == expected


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
        ok (pp(input, None, None)) == expected

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
        ok (pp(input, None, None)) == expected


if __name__ == '__main__':
    run()
