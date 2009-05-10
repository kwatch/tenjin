= README

release::	$Release$
copyright::	$Copyright$


== About

rbTenjin is a very fast and full-featured template engine.
You can embed Ruby statements and expressions into your text file.
rbTenjin converts it into Ruby program and evaluate it.


== Features

* Very fast (twice faster than eruby and three times faster than ERB)
* Lightweight (only a file which contains about 1000 lines)
* Not break HTML design because it uses XML Processing
  Instructions (PI) as embedded notation for Python statements.
* Secure because it supports escaping expression value by default.
* Auto caching of converted Python code.
* Nestable layout template
* Inlucde other templates
* Capture part of template
* Load YAML file as context data
* Preprocessing support

See doc/*.html for details.


== Installation

* If you have installed RubyGems, just type <tt>gem install tenjin</tt>.

    $ sudo gem install tenjin

* Else download rbtenjin-$Release$.tar.bz2 and just copy 'lib/tenjin.rb' and
  'bin/rbtenjin' into proper directory.

    $ tar xjf rbtenjin-$Release$.tar.bz2
    $ cd rbtenjin-$Release$/
    $ sudo copy lib/tenjin.rb /usr/local/lib/ruby/1.8/site_ruby/1.8/
    $ sudo copy bin/rbtenjin /usr/local/bin/

rbTenjin is tested with Ruby 1.8.6 and Rubinius.


== Attention

rbTenjin is beta released. It means that API or specification may change
in the future.


== License

MIT License
