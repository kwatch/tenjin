###
### $Rev$
### $Release:$
### $Copyright$
###

import unittest
import sys, os, re

from testcase_helper import *
import tenjin
from tenjin.helpers import escape, to_str


class HtmlHelperTest(unittest.TestCase, TestCaseHelper):

    def test_attr(self):
        actual = tenjin.helpers.html.tagattr('size', 20)
        expected = ' size="20"'
        self.assertEqual(expected, actual)
        #
        actual = tenjin.helpers.html.tagattr('size', 0)
        expected = ''
        self.assertEqual(expected, actual)
        #
        actual = tenjin.helpers.html.tagattr('checked', True, 'checked')
        expected = ' checked="checked"'
        self.assertEqual(expected, actual)
        #
        actual = tenjin.helpers.html.tagattr('checked', False, 'checked')
        expected = ''
        self.assertEqual(expected, actual)

    def test_checked(self):
        actual = tenjin.helpers.html.checked(1==1)
        expected = ' checked="checked"'
        self.assertEqual(expected, actual)
        #
        actual = tenjin.helpers.html.checked(1==0)
        expected = ''
        self.assertEqual(expected, actual)

    def test_selected(self):
        actual = tenjin.helpers.html.selected(1==1)
        expected = ' selected="selected"'
        self.assertEqual(expected, actual)
        #
        actual = tenjin.helpers.html.selected(1==0)
        expected = ''
        self.assertEqual(expected, actual)

    def test_disabled(self):
        actual = tenjin.helpers.html.disabled(1==1)
        expected = ' disabled="disabled"'
        self.assertEqual(expected, actual)
        #
        actual = tenjin.helpers.html.disabled(1==0)
        expected = ''
        self.assertEqual(expected, actual)

    def test_nl2br(self):
        s = """foo\nbar\nbaz\n"""
        actual = tenjin.helpers.html.nl2br(s)
        expected = "foo<br />\nbar<br />\nbaz<br />\n"
        self.assertEqual(expected, actual)

    def test_text2html(self):
        s = """foo\n    bar\nba     z\n"""
        actual = tenjin.helpers.html.text2html(s)
        expected = "foo<br />\n &nbsp; &nbsp;bar<br />\nba &nbsp; &nbsp; z<br />\n"
        self.assertEqual(expected, actual)


if __name__ == '__main__':
    unittest.main()
