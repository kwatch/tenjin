
###
### auto generated by ../doc/Kookbook.py
###

import sys, os, re
from glob import glob
from oktest import ok, run

python3 = sys.version_info[0] == 3

try:    # Python 2.6 or later
    from subprocess import Popen, PIPE
    def _popen(command):
        sout = Popen(command, shell=True, stdout=PIPE).stdout
        return sout
except ImportError:
    def _popen(command):
        return os.popen(command)


class ExamplesTest(object):

    DIR = os.path.dirname(os.path.abspath(__file__)) + '/data/examples'
    CWD = os.getcwd()

    def before(self):
        sys.stdout.write('\n** test_%s: (' % self.__name__)
        os.chdir(self.DIR + '/' + self.__name__)
        for x in glob('views/*.cache'):
            os.unlink(x)

    def after(self):
        os.chdir(self.CWD)

    def _test(self):
        for fname in glob('*.result'):
            sys.stdout.write(' %s' % fname)
            result = open(fname).read()
            command, expected = re.split(r'\n', result, 1)
            command = re.sub('^\$ ', '', command)
            actual = _popen(command).read()
            if python3:
                actual = actual.decode('utf-8')
            ok (actual) == expected
        sys.stdout.write(' )')

    def test_form(self):
        self._test()

    def test_gae(self):
        self._test()

    def test_preprocessing(self):
        self._test()

    def test_table(self):
        self._test()

if __name__ == '__main__':
    run()
