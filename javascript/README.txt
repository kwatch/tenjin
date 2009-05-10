======
README
======

Release: $Release$
$Copyright$


About
-----

jsTenjin is a very fast and full-featured template engine based on embedded JavaScript.
You can embed JavaScript statements and expressions into your text file.
jsTenjin converts it into JavaScript program and evaluate it.

Notice that this is alpha release.


Features
--------

* Very fast.
* Lightweight (only one file which contains about 1000 lines)
* Not break HTML design because it uses XML Processing
  Instructions (PI) as embedded notation for JavaScript statements.
* Secure because it supports escaping expression value by default.
* Auto caching of converted JavaScript code.
* Nestable layout template
* Inlucde other templates
* Capture part of template
* Load JSON file as context data
* Preprocessing support

See 'doc/*.html' for details.


Install
-------

1. Install Rhino and JDK.
      $ wget ftp://ftp.mozilla.org/pub/mozilla.org/js/rhino1_6R5.zip
      $ jar xf rhino1_6R5.zip
      $ sudo mkdir -p /usr/local/java
      $ cp rhino1_6R5/js.jar /usr/local/java
      $ java -jar /usr/local/java/js.jar -e 'print(typeof(java))'
      object

   Or install SpiderMonkey with File object enabled.
      $ wget ftp://ftp.ossp.org/pkg/lib/js/js-1.6.20070208.tar.gz
      $ tar xzf js-1.6.20070208.tar.gz
      $ cd js-1.6.*/
      $ ./configure --prefix=/usr/local --with-utf8 --with-editline
      $ make JS_THREADSAFE=1 JS_HAS_FILE_OBJECT=1
      $ sudo make install
      $ js -e 'print(typeof(File))'
      function

2. Copy 'lib/tenjin.js' to proper directory.
      $ mkdir -p $HOME/lib/js
      $ cp lib/tenjin.js $HOME/lib/js
   
3. Set $TENJIN_JS environment variable or edit 'bin/jstenjin' and set TENJIN_JS.
      $ export TENJIN_JS=$HOME/lib/js/tenjin.js   # or vi bin/jstenjin

4. Edit 'bin/jstenjin' command script and set command path
      #!/usr/local/bin/java -jar /usr/local/java/js.jar -strict   # for Rhino
      #!/usr/local/bin/js -s                               # for Spidermonkey

5. Copy 'bin/jstenjin' to proper directory.
      $ mkdir $HOME/bin
      $ export PATH=$PATH:$HOME/bin
      $ cp bin/jstenjin $HOME/bin
      $ chmod 755 $HOME/bin/jstenjin


Attention
---------

jsTenjin is alpha released. It means that API or specification may change
in the future.


License
-------

MIT License.
