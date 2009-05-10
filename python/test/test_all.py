###
### $Rev$
### $Release:$
### $Copyright$
###


def main(verbose):

    basenames = (
        "test_template",
        "test_engine",
        "test_preprocess",
        "test_htmlhelper",
        "test_main",
        "test_users_guide",
        "test_faq",
        "test_examples",
        )

    if verbose:

        import os
        for basename in basenames:
            print('')
            print("************************************************* " + basename)
            os.system("python %s.py" % basename)

    else:

        import unittest
        suite = unittest.TestSuite()
        for basename in basenames:
            test_module = __import__(basename)
            suite.addTest(unittest.findTestCases(test_module))

        unittest.TextTestRunner(verbosity=1).run(suite)
        #unittest.TextTestRunner(verbosity=2).run(test_template.TemplateTest)



if __name__ == '__main__':

    import sys
    verbose = len(sys.argv) > 1 and sys.argv[1] == '-v'
    main(verbose)
    sys.exit(0)
