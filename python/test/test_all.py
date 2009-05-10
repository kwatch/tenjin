###
### $Rev$
### $Release:$
### $Copyright$
###



import sys, os
os.system('python test_template.py')
os.system('python test_engine.py')
os.system('python test_main.py')
os.system('python test_users_guide.py')
os.system('python test_faq.py')
os.system('python test_htmlhelper.py')
sys.exit(0)

import unittest

#import test_template, test_engine, test_cmdapp


#suite = unittest.TestSuite()
#suite.addTest(test_template.TemplateTest)
#suite.addTest(test_engine.Engineest)
#suite.addTest(test_cmdapp.CommandApplicationTest)

#unittest.TextTestRunner(verbosity=2).run(suite)
#unittest.TextTestRunner(verbosity=2).run(test_template.TemplateTest)

#from test import test_support
#test_support.run_unittest(suite)

#unittest.main()
