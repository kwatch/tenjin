###
### $Release: 0.7.0 $
### copyright(c) 2007-2009 kuwata-lab.com all rights reserved.
###


import sys, re, os
arg1 = len(sys.argv) > 1 and sys.argv[1] or None
if arg1 == 'egg_info':
    from ez_setup import use_setuptools
    use_setuptools()
if arg1 == 'bdist_egg':
    from setuptools import setup
else:
    from distutils.core import setup


name     = 'Tenjin'
version  = '0.7.0'
author   = 'makoto kuwata'
email    = 'kwa@kuwata-lab.com'
maintainer = author
maintainer_email = email
url      = 'http://www.kuwata-lab.com/tenjin/'
desc     = 'a fast and full-featured template engine based on embedded Python'
detail   = (
           'pyTenjin is a very fast and full-featured template engine.\n'
           'You can embed Python statements and expressions into your text file.\n'
           'pyTenjin converts it into Python program and evaluate it.\n'
           'In addition to high-performance, pyTenjin has many useful features\n'
	   'such as layout template, partial template, capturing, preprocessing, and so on.\n'
           )
license  = 'MIT License'
platforms = 'any'
download = 'http://downloads.sourceforge.net/tenjin/%s-%s.tar.gz' % (name, version)
#download = 'http://jaist.dl.sourceforge.net/sourceforge/tenjin/%s-%s.tar.gz' % (name, version)
classifiers = [
    'Development Status :: 4 - Beta',
    'Environment :: Console',
    'Intended Audience :: Developers',
    'License :: OSI Approved :: MIT License',
    'Operating System :: OS Independent',
    'Programming Language :: Python',
    'Topic :: Software Development :: Libraries :: Python Modules',
    'Topic :: Internet :: WWW/HTTP :: Dynamic Content :: CGI Tools/Libraries',
]


setup(
    name=name,
    version=version,
    author=author,  author_email=email,
    maintainer=maintainer, maintainer_email=maintainer_email,
    description=desc,  long_description=detail,
    url=url,  download_url=download,  classifiers=classifiers,
    license=license,
    #platforms=platforms,
    #
    py_modules=['tenjin'],
    package_dir={'': 'lib'},
    scripts=['bin/pytenjin'],
    #packages=['tenjin'],
    zip_safe = False,
)
