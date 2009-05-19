###
### $Rev: 142 $
### $Release:$
### $Copyright$
###

import unittest
import sys, os, re, time
from glob import glob

from testcase_helper import *
import tenjin
#from tenjin.helpers import escape, to_str
from tenjin.helpers import *


class PreprocessTest(unittest.TestCase, TestCaseHelper):

    def test_preprocessor_class(self):
        input = r"""
	<?PY WEEKDAY = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'] ?>
	<select>
	<?py curr = params.get('wday') ?>
	<?PY for i, wday in enumerate(WEEKDAY): ?>
	  <option value="#{{i}}"#{selected(curr==#{{i}})}>${{wday}}</option>
	<?PY #endfor ?>
	</select>
	"""[1:].replace("\t", "")
        script = r"""
	WEEKDAY = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
	_buf.extend(('''<select>
	<?py curr = params.get(\'wday\') ?>\n''', ));
	for i, wday in enumerate(WEEKDAY):
	    _buf.extend(('''  <option value="''', to_str(_decode_params(i)), '''"#{selected(curr==''', to_str(_decode_params(i)), ''')}>''', escape(to_str(_decode_params(wday))), '''</option>\n''', ));
	#endfor
	_buf.extend(('''</select>\n''', ));
	"""[1:].replace("\t", "")
        preprocessed = r"""
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
        filename = 'test_preprocess1.pyhtml'
        try:
            write_file(filename, input)
            preprocessor = tenjin.Preprocessor(filename)
            self.assertTextEqual(script, preprocessor.script)
            self.assertTextEqual(preprocessed, preprocessor.render())
        finally:
            if os.path.exists(filename):
                os.unlink(filename)


remove_unmatched_test_methods(PreprocessTest)


if __name__ == '__main__':
    unittest.main()
