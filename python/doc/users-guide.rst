======================================================================
                         Epyc User's Guide
======================================================================

:update:      $Date$
:release:     $Release: 0.0.0 $


.. contents:: Table of Contents



Introduction
====================



Overview
--------------------

Epyc is a converter of embedded Python text file into Python script.
It is similar to ePerl (embedded Perl) or eRuby (embedded Ruby).
You can embed Python code into your text file and convert it into
Python script with '``epyc``' command.

The following is an example of Epyc.

File 'ex.html'::

	<ul>
	{{*<?py for item in items: ?>*}}
	 <li>{{*${item}*}}</li>
	{{*<?py #end ?>*}}
	</ul>

Here is the notation:

* ``<?py ... ?>`` represents embedded Python statements.
* ``#{...}`` represents embedded Python expression.
* ``${...}`` represents embedded escaped (sanitized) Python expression.

Result of covertion into Python script::

	$ epyc ex.html
	_buf = []; _buf.append('''<ul>\n'''); 
	{{*for item in items:*}}
	    _buf.append(''' <li>'''); _buf.append({{*escape(to_str(item))*}}); _buf.append('''</li>\n'''); 
	{{*#end*}}
	_buf.append('''</ul>\n'''); 
	print ''.join(_buf)

Output of execution with context data::

	$ epyc -xc "items=['<foo>','&bar','\"baz\"'];" ex.html
	<ul>
	 <li>&lt;foo&gt;</li>
	 <li>&amp;bar</li>
	 <li>&quot;baz&quot;</li>
	</ul>


Features
--------------------

Epyc has the following features:

* Epyc runs very fast. It works about twice as fast as any other solution.
* Epyc doesn't break HTML design because it uses XML Processing
  Instructions (PI) as embedded notation for Python statements.
* Epyc is secure because it supports escaping expression value by default.
* Epyc is small and lightweight. It is very easy to include Epyc
  into your application.
* Epyc supports auto caching of converted Python code.
* Epyc supports partial template and layout template.
  These are very useful especially for web application.
* Epyc can load YAML file as context data. Using Epyc, it is able to
  separate template file and data file.



Comparison with other solutions
-------------------------------

Epyc has advantages compared with other solutions:

* **Easy to design** --
  JSP, ePerl, or eRuby breaks HTML design because they use
  '``<% ... %>``' as embedded notation which is not valid in HTML.
  Epyc doesn't break HTML desgin at all because it uses Processing
  Instructions (PI) as embedded notation which is valid in HTML.
* **Easy to write** --
  In PHP, it is a little bother to write embedded expression
  because the notation '``<?php echo $value; ?>``' is a little long,
  and very bother to embed escaped expression because
  '``<?php echo htmlspecialchars($value); ?>``' is very long.
  In Epyc, these are very easy to write because embedded expression
  notations ('``#{value}``' and '``${value}``') are very short.
* **Easy to learn** --
  Zope DTML, PageTemplate, Django Template, and other template templates
  are hard to learn because they are large, highly functinal, and
  based on non-Python syntax.
  Epyc is very easy to learn if you already know Python language because
  it is very small and  you can embed any Python code into HTML template.




Installation
====================

Epyc works on CPython (2.3 or higher) and Jython (2.2).

* CPython

  1. Download Epyc-X.X.X.tar.gz and extract it.
  2. Just type 'python setup.py install' with administrator or root user.
  3. (Optional) Install `PyYAML <http://pyyaml.org>`_.

* Jython

  1. Download Epyc-X.X.X.tar.gz and extract it.
  2. Copy 'lib/epyc.py' and 'lib/epyc_cmdapp.py' to proper directory.
  3. Edit 'bin/epyc' according to the following::

	{{*#!/usr/bin/env jython*}}

	{{*epyclibdir = '/home/yourname/epyc-X.X.X/lib'*}}
	{{*import sys*}}
	{{*sys.path.append(epyclibdir)*}}

	import epyc.cmdapp
	epyc.cmdapp.CommandApplication.main()




Designer's Guide
====================

This section shows how to use Epyc for designer.



Basic Example
--------------------

The following is the notation of Epyc.

* '``<?py ... ?>``' represents embedded Python statement.
* '``#{...}``' represents embedded Python expression.
* '``${...}``' represents embedded Python expression which is to be escaped (for example, '``& < > "``' is escaped to '``&amp; &lt; &gt; &quot;``').

File 'example1.pyhtml'::

	<html>
	 <body>
	  <ul>
	{{*<?py i = 0 ?>*}}
	{{*<?py for item in ['<foo>', 'bar&bar', '"baz"']: ?>*}}
	{{*<?py     i += 1 ?>*}}
	   <li>{{*#{item}*}}
	       {{*${item}*}}</li>
	{{*<?py #end ?>*}}
	  </ul>
	 </body>
	</html>

Notice that it is required to add '``<?py #end ?>``' line because Python doesn't have block-end mark.
Block-end mark line tells epyc command the position of end of block.
It is able to use '``#endfor``', '``#``', '``pass``', and so on as block-end mark.

The following is the result of convertion into Python code.

Result::

	$ epyc example1.pyhtml
	_buf = []; _buf.append('''<html>
	 <body>
	  <ul>\n'''); 
	{{*i = 0*}}
	{{*for item in ['<foo>', 'bar&bar', '"baz"']:*}}
	    {{*i += 1*}}
	    _buf.append('''   <li>'''); {{*_buf.append(to_str(item));*}} _buf.append('''
	       '''); {{*_buf.append(escape(to_str(item)));*}} _buf.append('''</li>\n'''); 
	{{*#end*}}
	_buf.append('''  </ul>
	 </body>
	</html>\n'''); 
	print ''.join(_buf)

* Variable ``_buf`` is a list.
  If command-line option ``-b`` is specified, epyc command removes '``_buf = [];``' and '``print ''.join(_buf)``' from python source code.
* Function ``to_str()`` (= ``epyc.to_str()``) convert value into string [#]_.
  Command-line option ``--tostrfunc=func`` makes epyc to use ``func()`` instead of ``to_str()``.
* Function ``escape()`` (= ``epyc.escape()``) escapes ``'& < > "'`` into ``'&amp; &lt; &gt; &quot;'`` [#]_.
  Command-line option ``--escapefunc=func`` makes epyc to use ``func()`` instead of ``escape()``.
* Newline character ("\\n" or "\\r\\n") is automatically detected by Epyc.

.. [#] ``to_str()`` function converts ``None`` into ``""`` (empty string),
       ``True`` into ``"true"``, ``False`` into ``"false"``.
       The other convertion is the same as ``str()`` built-in function.
.. [#] Difference between ``escape()`` and ``cgi.escape()`` is that the former escapes
       double-quotation mark into '``&quot;``' and the latter doesn't.

It is able to execute converted Python code with command-line option '-x'.

Result::

	$ epyc {{*-x*}} example1.pyhtml
	<html>
	 <body>
	  <ul>
	   <li>{{*<foo>*}}
	       {{*&lt;foo&gt;*}}</li>
	   <li>{{*bar&bar*}}
	       {{*bar&amp;bar*}}</li>
	   <li>{{*"baz"*}}
	       {{*&quot;baz&quot;*}}</li>
	  </ul>
	 </body>
	</html>



Embedded Statement Styles
------------------------------

Two styles of embedded statement are available.
The first style is shown in the previous section.
In this style, it is able to put indent spaces before '``<?py``' like the following:

File 'example1a.pyhtml'::

	<html>
	 <body>
	  <ul>
	<?py i = 0 ?>
	<?py for item in ['<foo>', 'bar&bar', '"baz"']: ?>
	    {{*<?py i += 1 ?>*}}
	   <li>#{item}
	       ${item}</li>
	<?py #end ?>
	  </ul>
	 </body>
	</html>

The second style is shown in the following.
This style is convenient for a lot of statements.

File 'example1b.pyhtml'::

	<html>
	 <body>
	  <ul>
	{{*<?py*}}
	{{*i = 0*}}
	{{*for item in ['<foo>', 'bar&bar', '"baz"']:*}}
	{{*    i += 1*}}
	{{*?>*}}
	   <li>#{item}
	       ${item}</li>
	{{*<?py*}}
	{{*#end*}}
	{{*?>*}}
	  </ul>
	 </body>
	</html>

Result::

	$ epyc example1b.pyhtml
	_buf = []; _buf.append('''<html>
	 <body>
	  <ul>\n'''); 
	
	{{*i = 0*}}
	{{*for item in ['<foo>', 'bar&bar', '"baz"']:*}}
	    {{*i += 1*}}
	
	    _buf.append('''   <li>'''); _buf.append(to_str(item)); _buf.append('''
	       '''); _buf.append(escape(to_str(item))); _buf.append('''</li>\n'''); 
	
	{{*#end*}}
	
	_buf.append('''  </ul>
	 </body>
	</html>\n'''); 
	print ''.join(_buf)


It is able to mix two styles in a file.
If you want not to print out newline character, the following technique is what you want.

File 'example2.pyhtml'::

	<?py for user in users: ?>
	<?py     if user.email: ?>
	<li><a href="mailto:${user.email}">${user.name}</a></li>
	<?py     else: ?>
	<li>${user.name}</li>
	<?py     #endif ?>
	<?py #endfor ?>
	
	<?py for user in users: ?>
	<li>{{*<?py*}}
	    if user.email:
	{{*?>*}}<a href="mailto:${user.email}">${user.name}</a>{{*<?py*}}
	    else:
	{{*?>*}}${user.name}{{*<?py*}}
	    #endif
	{{*?>*}}</li>
	<?py #endfor ?>

Here is the result of convertion to Python code.
Notice that ``'''  <li>'''`` and ``'''</a>'''`` don't contain ``'\n'``.

Result::

	$ epyc example2.pyhtml
	_buf = []
	for user in users:
	    if user.email:
	        _buf.append('''<li><a href="mailto:'''); _buf.append(escape(to_str(user.email))); _buf.append('''">'''); _buf.append(escape(to_str(user.name))); _buf.append('''</a></li>\n'''); 
	    else:
	        _buf.append('''<li>'''); _buf.append(escape(to_str(user.name))); _buf.append('''</li>\n'''); 
	    #endif
	#endfor
	_buf.append('''\n'''); 
	for user in users:
	    _buf.append({{*'''<li>'''*}}); 
	    if user.email:
	        _buf.append('''<a href="mailto:'''); _buf.append(escape(to_str(user.email))); _buf.append('''">'''); _buf.append(escape(to_str(user.name))); _buf.append({{*'''</a>'''*}}); 
	    else:
	        _buf.append(escape(to_str(user.name))); 
	    #endif
	    _buf.append('''</li>\n'''); 
	#endfor
	print ''.join(_buf)

The following styles are *not* available.

Invalid example #1::

	<ul>
	{{*<?py i = 0*}}
	{{*     for item in ['<foo>', 'bar&bar', '"baz"']:*}}
	{{*     i += 1 ?>*}}
	 <li>#{item}
	     ${item}</li>
	<?py #end ?>
	</ul>

Invalid example #2::

	<ul>
	{{*<?py*}}
	{{*    i = 0*}}
	{{*    for item in ['<foo>', 'bar&bar', '"baz"']:*}}
	{{*        i += 1*}}
	{{*?>*}}
	 <li>#{item}
	     ${item}</li>
	{{*<?py*}}
	    {{*#end*}}
	{{*?>*}}
	</ul>



Helper Functions
--------------------

Epyc provides the following helper functions for HTML.

**to_str(value)**

    Nearly equal to '``str(value)``' except that ``to_str(value)`` returns empty string (``""``)
    if value is None, ``"true"`` if True, and ``"false"`` if False.

**escape(str)**

    Convert '``& < > "``' into '``&amp &lt; &gt; &quot;``'.

**checked(bool),  C(bool)**

    Return ``' checked="checked"'`` if True else return empty string.

**selected(bool),  S(bool)**

    Return ``' selected="selected"'`` if True else return empty string.

**disabled(bool),  D(bool)**

    Return ``' disabled="disabled"'`` if True else return empty string.



Syntax Checking
------------------------------

Command-line option '``-l``' checks syntax error in embedded Python code.


File example3.pyhtml::

	<ul>
	<?py for item in items: ?>
	 <li>${item}</li>
	<?py   {{*#end*}} ?>
	</ul>

Result::

	$ epyc {{*-l*}} example3.pyhtml
	example3.pyhtml:4:3: unindent does not match any outer indentation level
	  4:   #end
	       ^

Error message is the same format as gcc compiler or java compiler.
Error jump in Emacs or other editor is available.



Context Data File
--------------------

Epyc allows you to specify context data by YAML file or Python script.

File 'example4.pyhtml'::

	<p>
	  ${text}
	  #{num}
	  #{flag}
	</p>
	
	<?py for item in items: ?>
	<p>${item}</p>
	<?py #end ?>
	
	<?py for key, value in hash.iteritems(): ?>
	<p>#{key} = ${value}</p>
	<?py #end ?>


File 'datafile.yaml'::

	text:   foo
	num:    3.14
	flag:   yes
	items:
	  - foo
	  - bar
	  - baz
	hash:
	  x: 1
	  y: 2


.. result=example4_yaml.result

Result::

	$ epyc -x {{*-f datafile.yaml*}} example4.pyhtml
	<p>
	  foo
	  3.14
	  true
	</p>
	
	<p>foo</p>
	<p>bar</p>
	<p>baz</p>
	
	<p>y = 2</p>
	<p>x = 1</p>


File 'datafile.py'::

	text  = "foo"
	num   = 3.14
	flag  = True
	items = ["foo", "bar", "baz"]
	hash  = {"x":1, "y":2}


.. result=example4_py.result

Result::

	$ epyc -x {{*-f datafile.py*}} example4.pyhtml
	<p>
	  foo
	  3.14
	  true
	</p>
	
	<p>foo</p>
	<p>bar</p>
	<p>baz</p>
	
	<p>y = 2</p>
	<p>x = 1</p>


You must install `PyYAML <http://pyyaml.org>`_ if you want to use YAML-format context data file.



Command-line Context Data
------------------------------

Command-line option '``-c``' specifies context data in YAML format or Python code.

File 'example5.pyhtml'::

	text:  #{text}
	items:
	<?py for item in items: ?>
	  - #{item}
	<?py #end ?>
	hash:
	<?py for key, val in hash.iteritems(): ?>
	  #{key}: #{val}
	<?py #end ?>


.. result=example5_py.result

Result of context data in python code::

	$ epyc -x {{*-c 'text="foo"; items=["a","b","c"]; hash={"x":1,"y":2}'*}} example5.pyhtml
	text:  foo
	items:
	  - a
	  - b
	  - c
	hash:
	  y: 2
	  x: 1


.. result=example5_yaml.result

Result of context data in yaml format::

	$ epyc -x {{*-c '{text: foo, items: [a, b, c], hash: {x: 1, y: 2}}'*}} example5.pyhtml
	text:  foo
	items:
	  - a
	  - b
	  - c
	hash:
	  y: 2
	  x: 1


You must install `PyYAML <http://pyyaml.org>`_ at first if you want to specify context data in YAML format.



Nested Template
--------------------

Template can include other templates.
Included templates can also include other templates.

The following functions are available to include other templates.

**include(str template_name, bool append_to_buf=True)**
    Include other template.
    If second argument is True then included template is appended into ``_buf``
    (ex. ``<?py include(template_name) ?>``),
    else return it as string (ex. ``#{include(template_name, False)}`` or
    ``<?py var = include(template_name, False)``).
    

File 'main.pyhtml'::

	<html>
	  <body>
	
	    <div id="sidemenu">
	{{*<?py include('sidemenu.pyhtml') ?>*}}
	    </div>
	
	    <div id="maincontent">
	<?py for item in items: ?>
	      <p>${item}</p>
	<?py #end ?>
	    </div>
	
	    <div id="footer">
	{{*#{include('footer.pyhtml', False)}*}}
	    </div>
	
	  </body>
	</table>

File 'sidemenu.pyhtml'::

	<ul>
	<?py for item in menu: ?>
	  <li><a href="${item['url']}">${item['name']}</a></li>
	<?py #end ?>
	</ul>

File 'footer.pyhtml'::

	<hr />
	<address>
	  <a href="mailto:${webmaster_email}">${webmaster_email}</a>
	</address>

File 'contextdata.py'::

	items = [ '<FOO>', '&BAR', '"BAZ"' ]
	webmaster_email = 'webmaster@example.com'
	menu  = [
	    {'name': 'Top',      'url': '/' },
	    {'name': 'Products', 'url': '/prod' },
	    {'name': 'Support',  'url': '/support' },
	]

Result::

	$ epyc -xf contextdata.py main.pyhtml
	<html>
	  <body>
	
	    <div id="sidemenu">
	{{*<ul>*}}
	  {{*<li><a href="/">Top</a></li>*}}
	  {{*<li><a href="/prod">Products</a></li>*}}
	  {{*<li><a href="/support">Support</a></li>*}}
	{{*</ul>*}}
	    </div>
	
	    <div id="maincontent">
	      <p>&lt;FOO&gt;</p>
	      <p>&amp;BAR</p>
	      <p>&quot;BAZ&quot;</p>
	    </div>
	
	    <div id="footer">
	{{*<hr />*}}
	{{*<address>*}}
	{{*  <a href="mailto:webmaster@example.com">webmaster@example.com</a>*}}
	{{*</address>*}}
	
	    </div>
	
	  </body>
	</table>


Function '``include()``' can take template filename
(ex. 'templates/main.pyhtml') or template short name (ex. ':main').
Template short name represents a template in short notation. It starts with colon (':').

To make template short name available, command-line option '``--prefix``' and
'``--postfix``' are required.
For example, '``include("templates/main.pyhtml")``' can be described as '``include(":main")``'
when '``--prefix="templates/"``' and '``--postfix=".pyhtml"``' are specified in command-line.



Layout Template
--------------------

Command-line option '``--layout=filename``' specifies layout template filename.

For example, 'main.pyhtml' template in the previous section can be divided
into layout file 'layout.pyhtml' and content file 'main2.pyhtml'.
Variable '``_content``' represents the result of content file in layout template.

File 'layout.pyhtml'::

	<html>
	  <body>
	
	    <div id="sidemenu">
	<?py include('sidemenu.pyhtml') ?>
	    </div>
	
	    <div id="maincontent">
	{{*#{_content}*}}
	    </div>
	
	    <div id="footer">
	#{include('footer.pyhtml', False)}
	    </div>
	
	  </body>
	</table>

File 'main2.pyhtml'::

	<?py for item in items: ?>
	  <p>${item}</p>
	<?py #end ?>

Result::

	$ epyc -xf contextdata.py {{*--layout=layout.pyhtml*}} main2.pyhtml
	<html>
	  <body>
	
	    <div id="sidemenu">
	<ul>
	  <li><a href="/">Top</a></li>
	  <li><a href="/prod">Products</a></li>
	  <li><a href="/support">Support</a></li>
	</ul>
	    </div>
	
	    <div id="maincontent">
	{{*  <p>&lt;FOO&gt;</p>*}}
	{{*  <p>&amp;BAR</p>*}}
	{{*  <p>&quot;BAZ&quot;</p>*}}
	{{**}}
	    </div>
	
	    <div id="footer">
	<hr />
	<address>
	  <a href="mailto:webmaster@example.com">webmaster@example.com</a>
	</address>
	
	    </div>
	
	  </body>
	</table>


Target temlate and layout template shares the same context object.
If you set some variables in target template, they are available in layout template.

File 'layout3.pyhtml'::

	...
	<h1>{{*${title}*}}</h1>
	
	<div id="maincontent">
	#{_content}
	<div>
	
	<a href="{{*${url}*}}">Next page</a>
	...

File 'main3.pyhtml'::

	{{*<?py title = 'Document Title' ?>*}}
	{{*<?py url = '/next/page' ?>*}}
	<table>
	  ...content...
	</table>

Result::

	$ epyc -x --layout=layout3.pyhtml main3.pyhtml
	...
	<h1>{{*Document Title*}}</h1>
	
	<div id="maincontent">
	<table>
	  ...content...
	</table>
	
	<div>
	
	<a href="{{*/next/page*}}">Next page</a>
	...



Other Options
--------------------

* Command-line option '``-i N``' or '``--indent=N``' changes indent depth to ``N`` (default 4).

* Command-line option '``-m mod1,mod2,mod3``' loads modules mod1, mod2, and mod3.
  This option is equivarent to Python code '``import mod1, mod2, mod3``'.

* Command-line option '``--escapefunc=func1``' changes ``escape()`` function name to ``func1``
  and '``--tostrfunc=func2``' changes ``to_str()`` function name to ``func2``.


File 'example6.pyhtml'::

	<?py for item in ['<foo>', '&bar', '"baz"', None, True, False]: ?>
	  <p>${item}</p>
	<?py #end ?>


.. result=example6_code.result

Result of convertion to Python code::

	$ epyc {{*-i2 --escapefunc=cgi.escape --tostrfunc=str*}} example6.pyhtml
	_buf = []
	for item in ['<foo>', '&bar', '"baz"', None, True, False]:
	  _buf.append('''  <p>'''); _buf.append({{*cgi.escape*}}({{*str*}}(item))); _buf.append('''</p>\n'''); 
	#end
	print ''.join(_buf)


.. result=example6_eval.result

Result of execution::

	$ epyc -x {{*-m cgi --escapefunc=cgi.escape --tostrfunc=str*}} example6.pyhtml
	  <p>&lt;foo&gt;</p>
	  <p>&amp;bar</p>
	  <p>"baz"</p>
	  <p>None</p>
	  <p>True</p>
	  <p>False</p>




Developer's Guide
==============================

This section shows how to use Epyc in your Python script.



Classes and Functions in Epyc
------------------------------

Epyc has two classes.

**epyc.Template**
    This class represents a template file.
    An object of epyc.Template correspond to a template file.

**epyc.Manager**
    This class represents some template objects.
    It can handle nested template and layout template.
    Using epyc.Manager class, you can use Epyc as a template engine for web application.

Epyc has the following utility functions.
These are imported by '``from epyc.html import *``'.

**to_str(value)**
    Convert value into string.
    Return empty string if value is None, return ``"true"`` if true,
    return ``"false"`` if false, return the result of '``str(value)``' if else.

**escape(str value)**
    Escape '``& < > "``' in string value into '``&amp; &lt; &gt; &quot;``'.

**checked(bool expr)**
    Return ``' checked="checked"'`` if expr is true.

**selected(bool expr)**
    Return ``' selected="selected"'`` if expr is true.

**disabled(bool expr)**
    Return ``' disabled="disabled"'`` if expr is true.

**C(bool expr)**
    Alias of checked(expr).

**S(bool expr)**
    Alias of selected(expr).

**D(bool expr)**
    Alias of disabled(expr).



Class epyc.Template
------------------------------

epyc.Template class represents a template file.
An object of epyc.Template correspond to a template file.
It doesn't support nested template nor layout template (use epyc.Manager class instead).

This class has the following methods and attributes.

**epyc.Template(str filename=None, str escapefunc='escape', str tostrfunc='to_str', int indent=4)**
    Create template object. If filename is given, read and convert it to Python code.

**epyc.Template.convert(str input, str filename=None)**
    Convert input text into Python code and return it.

**epyc.Template.convert_file(str filename)**
    Convert file into Python code and return it.
    This is equivarent to ``epyc.Template.convert(open(filename).read(), filename)``

**epyc.Template.evaluate(dict context=None, list _buf=None)**
    Compile Python code and evaluate it with context data.
    If ``_buf`` is None then new dict is created as ``_buf`` and returns the result
    of it as string.
    If ``_buf`` is not None then the result of evaluation is appended into ``_buf``
    and returns None.

**epyc.Template.pycode**
    Converted Python code

**epyc.Template.bytecode**
    Compiled Python code


The followings are examples to use Epyc in Python script.

File 'example7.pyhtml'::

	<h1>#{title}</h1>
	<ul>
	<?py for item in items: ?>
	 <li>${item}</li>
	<?py #end ?>
	</ul>


File 'example7.py'::

	## embedded python file
	filename = 'example7.pyhtml'
	
	## convert into python code
	import epyc
	from epyc.html import *     # import 'escape', 'to_str', and so on
	template = {{*epyc.Template(filename)*}}
	## or
	# template = epyc.Template()
	# pycode = {{*template.convert_file(filename)*}}
	## or
	# template = epyc.Template()
	# input = open(filename).read()
	# pycode = {{*template.convert(input, filename)*}}  # filename is optional
	
	## show converted python code
	print {{*template.pycode*}}
	
	## evaluate python code
	context = {'title': 'Epyc Example', 'items': ['<foo>','&bar','"baz"']}
	output = {{*template.evaluate(context)*}}
	print output,

Result::

	$ python example7.py
	_buf.append('''<h1>'''); _buf.append(to_str(title)); _buf.append('''</h1>
	<ul>\n'''); 
	for item in items:
	    _buf.append(''' <li>'''); _buf.append(escape(to_str(item))); _buf.append('''</li>\n'''); 
	#end
	_buf.append('''</ul>\n'''); 
	
	<h1>Epyc Example</h1>
	<ul>
	 <li>&lt;foo&gt;</li>
	 <li>&amp;bar</li>
	 <li>&quot;baz&quot;</li>
	</ul>



Class epyc.Manager
------------------------------

epyc.Manager class contains some template objects.
It can handle nested template and layout template.
Using epyc.Manager class, you can use Epyc as a template engine for web application.

This class has the following methods.

**epyc.Manager(str prefix='', str postfix='', str layout=None, cache=True, **init_opts_for_template)**
    Create Manager object. Arguments ``init_opts_for_template`` are passed to epyc.Template() internally.
**epyc.Manager.include(str template_name, bool append_to_buf=True)**
    Include and evaluate other template.
    if second argument is True then result of it is appended into ``_buf``,
    else returns result as string.
**epyc.Manager.evaluate(str template_name, dict context=None, dict globals=None, bool layout=True, _buf=None)**
    Convert template into Python code, evaluate it with context data, and return the result of it.
    If ``layout`` is True then layout template name specified with constructor option is
    used as layout template, else if False then layout template is not used,
    else if string then it is regarded as layout template name.

Argument {{,template_name,}} in evaluate() methods is filename or short name of template.
Template short name is a string starting with colon (':').
For example, '``evaluate(":list", context)``' is equivarent to '``evaluate("templates/list.pyhtml", contet)``' if prefix option is '``templates/``' and postfix option is '``.pyhtml``'.

In template file, the followings are available.

**_content**
    This variable represents the result of evaluation of other template.
    This is available only in layout template file.
**include(str template_name, append_to_buf=True)**
    This is an alias of epyc.Manager.include().
    See the above description.


The followings are example of epyc.Manger class.


File 'user_form.pyhtml'::

	<p>
	  Name:  <input type="text" name="name"  value="${params['name']}" /><br />
	  Email: <input type="text" name="email" value="${params['email']}" /><br />
	  Gender:
	<?py gender = params['gender'] ?>
	  <input type="radio" name="gender" value="m" #{checked(gender=='m')} />Male
	  <input type="radio" name="gender" value="f" #{checked(gender=='f')} />Female
	</p>

File 'user_create.pyhtml'::

	<form action="user_app.cgi" method="post">
	  <input type="hidden" name="action" value="create" />
	{{*<?py include(':form') ?>*}}
	  <input type="submit" value="Create" />
	</form>

File 'user_edit.pyhtml'::

	<form action="user_app.cgi" method="post">
	  <input type="hidden" name="action" value="edit" />
	  <input type="hidden" name="id" value="${params['id']}" />
	{{*<?py include(':form') ?>*}}
	  <input type="submit" value="Edit" />
	</form>

File 'user_layout.pyhtml'::

	<html>
	  <body>
	
	    <h1>${title}</h1>
	
	    <div id="maincontent">
	{{*#{_content}*}}
	    </div>
	
	    <div id="footer">
	{{*<?py include('footer.html') ?>*}}
	    </div>
	
	  </body>
	</table>

File 'footer.html'::

	<hr />
	<address>
	  <a href="mailto:webmaster@example.com">webmaster@example.com</a>
	</address>

File 'user_app.cgi'::

	## set action ('create' or 'edit')
	import sys, os, cgi
	action = None
	form = None
	if os.getenv('REQUEST_PATH'):
	    form = cgi.FieldStorage()
	    action = form.getFirst('action')
	elif len(sys.argv) >= 2:
	    action = sys.argv[1]
	if not action:
	    action = 'create'
	
	## set context data
	if action == 'create':
	    title = 'Create User'
	    params = {'name': None, 'email': None, 'gender': None}
	else:
	    title = 'Edit User'
	    params = {'name': 'Margalette',
	              'email': 'meg@example.com',
		      'gender': 'f',
		      'id': 123 }
	context = {'title': title, 'params': params}
	
	## create manager object
	{{*import epyc*}}
	{{*from epyc.html import **}}    # import 'escape', 'to_str', and so on
	layout = 'user_layout.pyhtml'  # or ':layout'
	{{*manager = epyc.Manager(prefix='user_', postfix='.pyhtml', layout=layout)*}}
	
	## evaluate template
	template_name = ':' + action   # ':create' or ':edit'
	{{*output = manager.evaluate(template_name, context)*}}
	if form:
	    print "Content-Type: text/html\r\n\r\n",
	print output,


Result::

	$ python user_app.cgi create
	<html>
	  <body>
	
	    <h1>Create User</h1>
	
	    <div id="maincontent">
	{{*<form action="user_app.cgi" method="post">*}}
	{{*  <input type="hidden" name="action" value="create" />*}}
	{{*<p>*}}
	{{*  Name:  <input type="text" name="name"  value="" /><br />*}}
	{{*  Email: <input type="text" name="email" value="" /><br />*}}
	{{*  Gender:*}}
	{{*  <input type="radio" name="gender" value="m"  />Male*}}
	{{*  <input type="radio" name="gender" value="f"  />Female*}}
	{{*</p>*}}
	{{*  <input type="submit" value="Create" />*}}
	{{*</form>*}}
	{{**}}
	    </div>
	
	    <div id="footer">
	{{*<hr />*}}
	{{*<address>*}}
	{{*  <a href="mailto:webmaster@example.com">webmaster@example.com</a>*}}
	{{*</address>*}}
	    </div>
	
	  </body>
	</table>



Template Initialize Options
------------------------------

epyc.Template() can take the follwoing options.

* '``escapefunc``' (string) specifies function name to escape string.
  Default is '``escape``' (= ``epyc.escape``).

* '``tostrfunc``' (string) specifies function name to convert value into string.
  Default is '``to_str``' (= ``epyc.to_str``).

* '``indent``' (integer) specifies width of indentation.
  Default is 4.

epyc.Manager() can also take the same options as above.
These options given to epyc.Manger() are passed to epyc.Template() internally.


File 'example8.py'::

	filename = 'example7.pyhtml'
	import epyc
	from epyc.html import *   # import 'escape', 'to_str' and so on
	template = epyc.Template(filename, {{*escapefunc='cgi.escape'*}}, {{*tostrfunc='str'*}})
	print template.pycode
	
	import cgi
	title = 'Epyc Example'
	items = ['<foo>', '&bar', '"baz"', None, True, False]
	output = template.evaluate({'title':title, 'items':items})
	print output,


Result::

	$ python example8.py
	_buf.append('''<h1>'''); _buf.append({{*str*}}(title)); _buf.append('''</h1>
	<ul>\n'''); 
	for item in items:
	    _buf.append(''' <li>'''); _buf.append({{*cgi.escape*}}({{*str*}}(item))); _buf.append('''</li>\n'''); 
	#end
	_buf.append('''</ul>\n'''); 
	
	<h1>Epyc Example</h1>
	<ul>
	 <li>&lt;foo&gt;</li>
	 <li>&amp;bar</li>
	 <li>"baz"</li>
	 <li>None</li>
	 <li>True</li>
	 <li>False</li>
	</ul>



Other Topics
--------------------

* epyc.Template detects newline character ("\\n" or "\\r\\n") automatically.
  If input file contains "\\r\\n", epyc generates output which contains "\\r\\n".

* epyc.Template.evaluate() can be called many times.
  If you create a epyc.Template object, you can call evaluate() method many times.

* epyc.Template.convert() also can be called many times.
  If you create a epyc.Template object, you can call convert() (and also evaluate()) method many times.

.. .# * epyc.Template object is not thread-safe. It is not able to share Template objects with several threads.
