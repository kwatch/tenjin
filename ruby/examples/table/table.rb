## create Engine object
require 'tenjin'
engine = Tenjin::Engine.new()

## render template with context data
context = { :title => 'Bordered Table Example',
            :items => [ '<AAA>', 'B&B', '"CCC"' ] }
output = engine.render('table.rbhtml', context)
puts output
