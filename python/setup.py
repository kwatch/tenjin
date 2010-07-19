###
### $Release: 0.9.0 $
### copyright(c) 2007-2010 kuwata-lab.com all rights reserved.
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
version  = '0.9.0'
author   = 'makoto kuwata'
email    = 'kwa@kuwata-lab.com'
maintainer = author
maintainer_email = email
url      = 'http://www.kuwata-lab.com/tenjin/'
desc     = 'a fast and full-featured template engine based on embedded Python'
detail   = r"""
About
-----

pyTenjin is a very fast and full-featured template engine.
You can embed Python statements and expressions into your template file.
pyTenjin converts it into Python script and evaluate it.

!!ATTENTION!!

pyTenjin is enough stable, but it is under beta release.
It means that API or specification may change in the future.


Features
--------

* Very fast

  - About x10 faster than Django, x4 than Cheetah, x2 than Mako
  - In addition loading tenjin.py is very lightweight (important for CGI)

* Full featured

  - Nestable layout template
  - Partial template
  - Fragment cache
  - Capturing
  - Preprocessing

* Easy to learn

  - You don't have to learn template-specific language

* Supports Google App Engine


See `User's Guide`_ for details.

.. _`User's Guide`:  http://www.kuwata-lab.com/tenjin/pytenjin-users-guide.html


Install
-------

::

    $ sudo easy_install Tenjin

Or::

    $ tar xzf Tenjin-X.X.X.tar.gz
    $ cd Tenjin-X.X.X
    $ sudo python setup.py install

Or just copy 'lib/tenjin.py' and 'bin/pytenjin' into proper directory.

(Optional) Install `PyYAML <http://pyyaml.org>`_.


Example
-------

example.pyhtml::

    <?py # -*- coding: utf-8 -*- ?>
    <?py #@ARGS items ?>
    <table>
    <?py cycle = new_cycle('odd', 'even') ?>
    <?py for item in items: ?>
      <tr class="#{cycle()}">
        <td>${item}</td>
      </tr>
    <?py #endfor ?>
    </table>

example.py::

    import tenjin
    from tenjin.helpers import *
    from tenjin.helpers.html import *
    #import tenjin.gae; tenjin.gae.init()  # for Google App Engine
    engine = tenjin.Engine()
    context = { 'items': ['<AAA>', 'B&B', '"CCC"'] }
    html = engine.render('example.pyhtml', context)
    print(html)

Output::

    $ python example.py
    <table>
      <tr class="odd">
        <td>&lt;AAA&gt;</td>
      </tr>
      <tr class="even">
        <td>B&amp;B</td>
      </tr>
      <tr class="odd">
        <td>&quot;CCC&quot;</td>
      </tr>
    </table>


See `other examples`_ .

.. _`other examples`: http://www.kuwata-lab.com/tenjin/pytenjin-examles.html
"""[1:]
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
    'Programming Language :: Python :: 2.3',
    'Programming Language :: Python :: 2.4',
    'Programming Language :: Python :: 2.5',
    'Programming Language :: Python :: 2.6',
    'Programming Language :: Python :: 2.7',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.0',
    'Programming Language :: Python :: 3.1',
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
    #zip_safe = False,
)
