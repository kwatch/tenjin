###
### $Rev$
### $Release:$
### $Copyright$
###

#import unittest
import os, difflib, re, traceback, yaml


class TestCaseHelper:

    def testname(self):
        try:
            testname = self._TestCase__testMethodName
        except AttributeError:
            testname = self._testMethodName
        return testname

    def is_target(self, depth=2):
        env_testname = os.environ.get('TEST')
        if not env_testname:
            return True
        return self.testname() == 'test_' + env_testname

    #def is_target(self, depth=2):
    #    testname = os.environ.get('TEST')
    #    if not testname:
    #        return True
    #    stack = traceback.extract_stack()
    #    caller_method = stack[-depth][2]
    #    assert caller_method.startswith("test_")
    #    name = caller_method[len("test_"):]
    #    return testname == name

    def assertTextEqual(self, text1, text2, encoding=None):
        if text1 == text2:
            self.assertEqual(text1, text2)
        else:
            file1, file2 = '.tmp.file1', '.tmp.file2'
            if encoding:
                if isinstance(text1, unicode):
                    text1 = text1.encode(encoding)
                if isinstance(text2, unicode):
                    text2 = text2.encode(encoding)
            open(file1, 'w').write(text1)
            open(file2, 'w').write(text2)
            f = os.popen("diff -u %s %s" % (file1, file2))
            output = f.read()
            f.close()
            os.unlink(file1)
            os.unlink(file2)
            mesg = re.sub(r'.*?\n', '', output, 2)
            self.assertEqual(text1, text2, mesg)

    def load_testdata(filename, untabify=True):
        i = filename.rfind('.')
        if filename[i:] != '.yaml' and filename[i:] != '.yml':
            filename = filename[:i] + '.yaml'
        input = file(filename).read()
        if untabify:
            input = input.expandtabs()
        ydoc = yaml.load(input)
        return ydoc
    load_testdata = staticmethod(load_testdata)

    def generate_testcode(filename, untabify=True, testmethod='_test', lang='python'):
        doclist = TestCaseHelper.load_testdata(filename, untabify)
        #
        testname_pattern = os.getenv('TEST')
        if testname_pattern:
            regexp = re.compile(testname_pattern)
            doclist = [doc for doc in doclist if regexp.match(str(doc.get('name')))]
            #if not doclist:
            #    raise StandardError("*** testname '%s' not found." % testname_pattern)
        #
        table = {}
        buf = []
        for doc in doclist:
            if not doc.has_key('name'):
                raise Exception("'name:' is required.")
            name = doc['name']
            if table.has_key(name):
                raise Exception("'name: %s' is duplicated." % name)
            table[name] = doc
            buf.append(        "def test_%s(self):" % name)
            for key, val in doc.iteritems():
                if key[-1] == '*':
                    key = key[:-1]
                    val = val.get(lang)
                if key == 'exception':
                    buf.append("    self.%s = %s" % (key, val))
                elif isinstance(val, str):
                    buf.append('    self.%s = r"""%s"""' % (key, val))
                else:
                    buf.append("    self.%s = %s" % (key, repr(val)))
            buf.append(        "    self.%s()" % testmethod)
            buf.append(        "#")
        buf.append('')
        code = "\n".join(buf)
        return code
    generate_testcode = staticmethod(generate_testcode)
