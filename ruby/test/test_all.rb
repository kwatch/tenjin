###
### $Rev$
### $Release: 0.0.0 $
### $Copyright$
###

basedir = File.dirname(File.dirname(File.expand_path(__FILE__)))
libdir  = File.join(basedir, 'lib')
testdir = File.join(basedir, 'test')
$:.unshift testdir
$:.unshift libdir
ENV['PATH'] = File.join(basedir, "bin") + File::PATH_SEPARATOR + ENV['PATH']

#require 'test/unit'
#require 'testutil'
require 'oktest'
require 'testcase-helper'
#require 'testunit-assertions'
require 'tenjin'

if __FILE__ == $0
  Dir.chdir testdir
  load 'test_template.rb'
  load 'test_engine.rb'
  load 'test_main.rb'
  load 'test_htmlhelper.rb'
  load 'test_store.rb'
  load 'test_users_guide.rb'
  load 'test_faq.rb'
  load 'test_examples.rb'
end
