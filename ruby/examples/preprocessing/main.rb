require 'helper'

## create engine
require 'tenjin'
engine = Tenjin::Engine.new(:postfix=>'.rbhtml', :preprocess=>true)

## render template with context data
params = { :id=>1234, :name=>'Foo', :lang=>'ch' }
context = { :params => params }
output = engine.render(:select, context)
puts output
