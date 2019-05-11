======
README
======

:Release:	$Release$
:Copyright:	$Copyright: copyright(c) 2007-2012 kuwata-lab.com all rights reserved. $
:URL:		http://www.kuwata-lab.com/tenjin/


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


License
-------

$Lincense: MIT License $
