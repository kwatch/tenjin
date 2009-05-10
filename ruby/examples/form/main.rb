## create Engine object
require 'tenjin'
engine = Tenjin::Engine.new(:postfix=>'.rbhtml', :layout=>'layout.rbhtml')

## render template with context data
params = { :name=>'Foo', :gender=>'M' }
context = { :params=>params }
output = engine.render(:update, context)   # :update == 'update'+postfix
puts output
