###
### $Release: 0.9.0 $
### copyright(c) 2007-2010 kuwata-lab.com all rights reserved.
###


import sys, re, os
arg1 = len(sys.argv) > 1 and sys.argv[1] or None
#if arg1 == 'egg_info':
#    from ez_setup import use_setuptools
#    use_setuptools()
if arg1 == 'bdist_egg':
    from setuptools import setup
else:
    from distutils.core import setup

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3


def _kwargs():

    name          = '$Package$'
    version       = '$Release$'
    author        = 'makoto kuwata'
    author_email  = 'kwa@kuwata-lab.com'
    maintainer    = author
    maintainer_email = author_email
    description   = 'a fast and full-featured template engine based on embedded Python'
    url           = 'http://www.kuwata-lab.com/tenjin/'
    download_url  = 'http://downloads.sourceforge.net/tenjin/$Package$-$Release$.tar.gz'
    #download_url = 'http://jaist.dl.sourceforge.net/sourceforge/tenjin/$Package$-$Release$.tar.gz'
    license       = '$License$'
    platforms     = 'any'
    py_modules    = ['tenjin']
    package_dir   = {'': python2 and 'lib2' or 'lib3'}
    scripts       = ['bin/pytenjin']
    #packages     = ['tenjin']
    #zip_safe     = False
    #
    long_description = r"""
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
    #tenjin.set_template_encoding('utf-8')  # optional (defualt 'utf-8')
    from tenjin.helpers import *
    from tenjin.html import *
    #import tenjin.gae; tenjin.gae.init()   # for Google App Engine
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
    #
    classifiers = [
        'Development Status :: 4 - Beta',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: $License$',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Programming Language :: Python :: 2.4',
        'Programming Language :: Python :: 2.5',
        'Programming Language :: Python :: 2.6',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.0',
        'Programming Language :: Python :: 3.1',
        'Programming Language :: Python :: 3.2',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'Topic :: Internet :: WWW/HTTP :: Dynamic Content :: CGI Tools/Libraries',
    ]
    #
    return locals()


setup(**_kwargs())
