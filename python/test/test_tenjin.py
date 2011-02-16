###
### $Release: $
### $Copyright: copyright(c) 2007-2011 kuwata-lab.com all rights reserved. $
###
from oktest import ok, not_ok, run, spec
from oktest.helper import dummy_file
import sys, os, re

import tenjin
from tenjin.helpers import *


class TenjinTest(object):

    input_old = """
escaped: ${x}, ${{x}}
not escaped: #{x}, #{{x}}
"""
    input_new = """
escaped: {=x=}, {#=x=#}
not escaped: {==x==}, {#==x==#}
"""
    script = r"""_extend=_buf.extend;_to_str=to_str;_escape=escape; _extend(('''
escaped: ''', _escape(_to_str(x)), ''', &lt;&amp;&gt;
not escaped: ''', _to_str(x), ''', <&>\n''', ));
"""
    output = r"""
escaped: &lt;&amp;&gt;, &lt;&amp;&gt;
not escaped: <&>, <&>
"""

    def before(self):
        self.filename = ".test_use_new_option.pyhtml"

    def after(self):
        for fname in [self.filename, self.filename + '.cache']:
            if os.path.exists(fname):
                os.unlink(fname)

    def test_use_new_option(self):
        def func(input):
            def f():
                engine = tenjin.Engine(preprocess=True, cache=None)
                if engine.cache: engine.cache.clear()
                context = {'x': '<&>'}
                output = engine.render(self.filename, context)
                script = engine.get_template(self.filename, context).script
                return output, script
            return dummy_file(self.filename, input)(f)
        if "True passed then switches embedded expression notations to new one.":
            output, script = func(self.input_new)
            ok (script) != self.script
            ok (output) != self.output
            #
            tenjin.use_new_notation()
            output, script = func(self.input_new)
            ok (script) == self.script
            ok (output) == self.output
        if "False passed then swithes to old patterns.":
            output, script = func(self.input_old)
            ok (script) != self.script
            ok (output) != self.output
            #
            tenjin.use_new_notation(False)
            output, script = func(self.input_old)
            ok (script) == self.script
            ok (output) == self.output


if __name__ == '__main__':
    run()
