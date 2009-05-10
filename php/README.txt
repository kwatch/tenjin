======
README
======

Release: $Release$
$Copyright$


About
-----

phpTenjin is a very fast and full-featured template engine based on PHP.
You can embed PHP statements and expressions into your text file.
phpTenjin converts it into PHP program and evaluate it.


Features
--------

* Very fast (three times faster than Cheetah, nine times faster than Djano).
* Lightweight (only one file which contains about 1000 lines)
* Not break HTML design because it uses XML Processing
  Instructions (PI) as embedded notation for PHP statements.
* Secure because it supports escaping expression value by default.
* Auto caching of converted PHP code.
* Nestable layout template
* Inlucde other templates
* Capture part of template
* Load YAML file as context data
* Preprocessing support

See 'doc/*.html' for details.


Install
-------

1. Copy 'lib/Tenjin.php' to your proper directory (ex. /usr/local/lib/php)
2. Copy 'bin/phptenjin' to your proper directory (ex. /usr/local/bin)


Attention
---------

phpTenjin is alpha released. It means that API or specification may change
in the future.


License
-------

MIT License.
