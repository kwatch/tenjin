require 'test/unit'
require 'assert-text-equal'
require 'fileutils'


TENJIN_JS = ENV['TENJIN_JS'] || 'tenjin.js'
test(?f, TENJIN_JS) or raise StandardError.new("#{TENJIN_JS}: not found.")

if ENV['JS'] == 'rhino'
  smonkey = false
  rhino   = true
  command = "rhino -strict -f #{TENJIN_JS} "
else
  smonkey = true
  rhino   = false
  command = "js -s -f #{TENJIN_JS} "
end
SMONKEY = smonkey
RHINO   = rhino
COMMAND = command


def File.write(filename, content)
  File.open(filename, 'w') {|f| f.write(content) }
end


class TenjinTest < Test::Unit::TestCase

  def skip_when(cond, reason)
    if cond
      $stderr.puts "*** skip: #{reason}"
    else
      yield
    end
  end


  def assert_file_exist(filename)
    assert(test(?f, filename), "file '#{filename}' expected but not found.")
  end


  def _create_input(filename, input)
    varname = filename.gsub(/[^\w]/, '_')
    quoted = "'" + input.gsub(/(['\\])/, '\\\\\1').gsub(/\n/, "\\n\\\n") + "'"
    s =  "Tenjin.writeFile('#{filename}', #{quoted});\n"
    #s << "var #{varname} = Tenjin.readFile('#{filename}');\n"
    s << "var input = Tenjin.readFile('#{filename}');\n"
    return s
  end


  def _invoke_js(s)
    File.write('tmp.js', s)
    output = `#{COMMAND} tmp.js`
    output.chomp!
    File.unlink('tmp.js')
    return output
  end

  def _remove_files(*filenames)
    filenames = filenames.flatten()
    filenames.each do |filename|
      File.unlink(filename) if test(?f, filename)
    end
  end


  def setup
    _remove_files Dir.glob('*.cache')
  end

  def teardown
  end



  ## ----------------------------------------
  def test_convert_and_evaluate1
    @input = <<'END'
<table>
<?js
  var len = list.length
  for (var i = 0; i < len; i++) {
    var item = list[i];
 ?>
  <tr>
    <td>#{item}</td>
    <td>${item}</td>
  </tr>
<?js } ?>
</table>
END

    @script = <<'END'
var _buf = '';  _buf += '<table>\n';

  var len = list.length
  for (var i = 0; i < len; i++) {
    var item = list[i];

 _buf += '  <tr>\n\
    <td>' + [item].join() + '</td>\n\
    <td>' + escapeXml(item) + '</td>\n\
  </tr>\n';
 }
 _buf += '</table>\n';
_buf
END

    @context = <<END
{ title: 'Tenjin Example', list: ['<AAA>', 'B&B', '"CCC"'] }
END

    @output = <<'END'
<table>
  <tr>
    <td><AAA></td>
    <td>&lt;AAA&gt;</td>
  </tr>
  <tr>
    <td>B&B</td>
    <td>B&amp;B</td>
  </tr>
  <tr>
    <td>"CCC"</td>
    <td>&quot;CCC&quot;</td>
  </tr>
</table>
END
    ## Tenjin.Template#convert()
    s = _create_input('input.jshtml', @input);
    s << <<END
var template = new Tenjin.Template();
var script = template.convert(input);
print(script);
END
    script = _invoke_js(s)
    assert_text_equal(@script, script, '** Tenjin.Template#convert()')
    ## Tenjin.Template#render()
    s = _create_input('input.jshtml', @input)
    s << <<END
var template = new Tenjin.Template();
var script = template.convert(input);
var context = #{@context};
var output = template.render(context);
print(output);
END
    output = _invoke_js(s)
    assert_text_equal(@output, output, '** Tenjin.Template#render()')
    ## Tenjin.render()
    s = _create_input('input.jshtml', @input)
    s << <<END
var context = #{@context};
var output = Tenjin.render(input, context);
print(output);
END
    output = _invoke_js(s)
    assert_text_equal(@output, output, '** Tenjin.render()')
    ##
  ensure
    _remove_files 'input.jshtml'
  end


  ## ----------------------------------------
  def test_layout
    @input_table = <<'END'
<table>
<?js for (var i = 0; i < list.length; i++) {
       var item = list[i];
       var color = i % 2 == 0 ? '#FFCCCC' : '#CCCCFF'; ?>
  <tr bgcolor="#{color}">
    <td>${item}</td>
  </tr>
<?js } ?>
</table>
END
    @input_layout = <<'END'
<html>
  <body>
    <h1>${title}</h1>
#{_content}
  </body>
</html>
END
    @script_table = <<'END'
var _buf = '';  _buf += '<table>\n';
 for (var i = 0; i < list.length; i++) {
       var item = list[i];
       var color = i % 2 == 0 ? '#FFCCCC' : '#CCCCFF';
 _buf += '  <tr bgcolor="' + [color].join() + '">\n\
    <td>' + escapeXml(item) + '</td>\n\
  </tr>\n';
 }
 _buf += '</table>\n';
_buf
END
    @script_layout = <<'END'
<html>
  <body>
    <h1>Engine Test</h1>
<table>
  <tr bgcolor="#FFCCCC">
    <td>&lt;AAA&gt;</td>
  </tr>
  <tr bgcolor="#CCCCFF">
    <td>B&amp;B</td>
  </tr>
  <tr bgcolor="#FFCCCC">
    <td>&quot;CCC&quot;</td>
  </tr>
</table>

  </body>
</html>
END
    ## Engine.getTemplate()
    s = ''
    s << _create_input('user_table.jshtml', @input_table)
    s << <<'END'
var engine = new Tenjin.Engine({prefix: 'user_', postfix: '.jshtml'})
var script = engine.getTemplate(':table').script;
print(script);
END
    script = _invoke_js(s)
    assert_text_equal(@script_table, script, '** Engine.getTemplate()')
    ## Engine.render()
    s = ''
    s << _create_input('user_table.jshtml', @input_table)
    s << _create_input('layout.jshtml', @input_layout)
    s << <<'END'
var engine = new Tenjin.Engine({prefix: 'user_', postfix: '.jshtml', layout: 'layout.jshtml'})
var context = { title: 'Engine Test', list: [ '<AAA>', 'B&B', '"CCC"' ] };
var output = engine.render(':table', context);
print(output);
END
    script = _invoke_js(s)
    assert_text_equal(@script_layout, script, '** Engine.render()')
  ensure
    _remove_files 'user_table.jshtml', 'layout.jshtml'
  end


  ## ----------------------------------------
  def test_echo
    @input = <<'END'
<h1><?js echo(title) ?></h1>
<ul>
  <li><?js echo(list[i]); ?></li>
</ul>
END
    @script = <<'END'
var _buf = '';  _buf += '<h1>'; _buf += (title); _buf += '</h1>\n\
<ul>\n\
  <li>'; _buf += (list[i]); _buf += '</li>\n\
</ul>\n';
_buf
END
    ## echo()
    s = _create_input('input.jshtml', @input)
    s << <<'END'
var script = (new Tenjin.Template()).convert(input);
print(script);
END
    script = _invoke_js(s)
    assert_text_equal(@script, script, '** echo()')
  ensure
    _remove_files 'input.jshtml'
  end


  ## ----------------------------------------
  def test_include
    @input_form   = <<'END'
  <p>
    <label for="name">Name</label>:
    <input type="text" id="name" name="name" value="${user.name}" />
  </p>
  <p>
    <label for="email">Email</label>:
    <input type="text" id="email" name="email" value="${user.email}" />
  </p>
END
    @input_create  = <<'END'
<form action="/cgi-bin/edit.cgi" method="post">
  <?js include('form.jshtml'); ?>
  <input type="submit" name="submit" value="Edit"/>
</form>
END
    @input_footer  = <<'END'
<hr />
<address><a href="webmaster@mail.com">webmaster@mail.com</a></address>
END
    @input_layout  = <<'END'
<html>
  <body>
    <h1>${title}</h1>
    <div id="content">
      <?js include('create.jshtml'); ?>
    </div>
    <div id="footer">
      <?js include("footer.jshtml"); ?>
    </div>
  </body>
</html>
END
    @script_layout = <<'END'
var _buf = '';  _buf += '<html>\n\
  <body>\n\
    <h1>' + escapeXml(title) + '</h1>\n\
    <div id="content">\n';
       _buf += _context._engine.render('create.jshtml', _context, false);
 _buf += '    </div>\n\
    <div id="footer">\n';
       _buf += _context._engine.render("footer.jshtml", _context, false);
 _buf += '    </div>\n\
  </body>\n\
</html>\n';
_buf
END
    @context = <<'END'
{ title: 'Edit User', user: { name: 'Foo', email: 'foo@mail.com' } }
END
    @output = <<'END'
<html>
  <body>
    <h1>Edit User</h1>
    <div id="content">
<form action="/cgi-bin/edit.cgi" method="post">
  <p>
    <label for="name">Name</label>:
    <input type="text" id="name" name="name" value="Foo" />
  </p>
  <p>
    <label for="email">Email</label>:
    <input type="text" id="email" name="email" value="foo@mail.com" />
  </p>
  <input type="submit" name="submit" value="Edit"/>
</form>
    </div>
    <div id="footer">
<hr />
<address><a href="webmaster@mail.com">webmaster@mail.com</a></address>
    </div>
  </body>
</html>
END
    ## script
    s = ''
    s << _create_input('layout.jshtml', @input_layout)
    s << <<END
var engine = new Tenjin.Engine();
var template = engine.getTemplate('layout.jshtml');
print(template.script);
END
    output = _invoke_js(s)
    assert_text_equal(@script_layout, output, '** script')
    ## output
    s = ''
    s << _create_input('form.jshtml',   @input_form)
    s << _create_input('create.jshtml', @input_create)
    s << _create_input('footer.jshtml', @input_footer)
    s << _create_input('layout.jshtml', @input_layout)
    s << <<END
var engine = new Tenjin.Engine();
var context = #{@context};
var output = engine.render('layout.jshtml', context);
print(output);
END
    output = _invoke_js(s)
    assert_text_equal(@output, output, '** output')
  ensure
    _remove_files %w[form.jshtml create.jshtml footer.jshtml layout.jshtml]
  end


  ## ----------------------------------------
  def test_capture
    @input   = <<'END'
<html>
  <body>
    <h1><?js startCapture("title"); ?>Start&amp;Stop Capture<?js stopCapture(); ?></h1>
    <div> 
  <?js startCapture("maincontent"); ?>
      <ul>
    <?js for (var i = 0, n = list.length; i < n; i++) { ?>
        <li>${list[i]}</li>
    <?js } ?>
      </ul>
  <?js stopCapture(); ?>
    </div>
  </body>
</html>
END
    @layout  = <<'END'
<html xml:lang="en" lang="en">
  <head>
    <title>#{title}</title>
  </head>
  <body>
    <h1>#{title}</h1>
    <div id="content">
#{maincontent}
    </div>
  </body>
</html>
END
    @script_input = <<'END'
var _buf = '';  _buf += '<html>\n\
  <body>\n\
    <h1>'; var _buf_bkup = _buf; _buf = ''; var _capture_varname = "title"; _buf += 'Start&amp;Stop Capture'; _context[_capture_varname] = _buf; _buf = _buf_bkup; _buf += '</h1>\n\
    <div> \n';
   var _buf_bkup = _buf; _buf = ''; var _capture_varname = "maincontent";
 _buf += '      <ul>\n';
     for (var i = 0, n = list.length; i < n; i++) {
 _buf += '        <li>' + escapeXml(list[i]) + '</li>\n';
     }
 _buf += '      </ul>\n';
   _context[_capture_varname] = _buf; _buf = _buf_bkup;
 _buf += '    </div>\n\
  </body>\n\
</html>\n';
_buf
END
    @script_layout = <<'END'
var _buf = '';  _buf += '<html xml:lang="en" lang="en">\n\
  <head>\n\
    <title>' + [title].join() + '</title>\n\
  </head>\n\
  <body>\n\
    <h1>' + [title].join() + '</h1>\n\
    <div id="content">\n\
' + [maincontent].join() + '\n\
    </div>\n\
  </body>\n\
</html>\n';
_buf
END
    @context = <<END
{ list: ['<AAA>', 'B&B', '"CCC"'] }
END
    @output_without_layout = <<END
<html>
  <body>
    <h1></h1>
    <div> 
    </div>
  </body>
</html>
END
    @output_with_layout = <<END
<html xml:lang="en" lang="en">
  <head>
    <title>Start&amp;Stop Capture</title>
  </head>
  <body>
    <h1>Start&amp;Stop Capture</h1>
    <div id="content">
      <ul>
        <li>&lt;AAA&gt;</li>
        <li>B&amp;B</li>
        <li>&quot;CCC&quot;</li>
      </ul>

    </div>
  </body>
</html>
END
    ## convert input
    s = _create_input('input.jshtml', @input)
    s << <<END
var engine = new Tenjin.Engine();
var template = engine.getTemplate('input.jshtml');
print(template.script);
END
    script = _invoke_js(s)
    assert_text_equal(@script_input, script, '** convert input')
    ## convert layout
    s = _create_input('layout.jshtml', @layout)
    s << <<END
var engine = new Tenjin.Engine();
var template = engine.getTemplate('layout.jshtml');
print(template.script);
END
    script = _invoke_js(s)
    assert_text_equal(@script_layout, script, '** convert layout')
    ## render input without layout
    s = ''
    s << _create_input('input.jshtml', @input)
    s << _create_input('layout.jshtml', @layout)
    s << <<END
var context = #{@context};
var engine = new Tenjin.Engine();
var output = engine.render('input.jshtml', context);
print(output);
END
    output = _invoke_js(s)
    assert_text_equal(@output_without_layout, output, '** render input without layout')
    ## render input with layout
    s = ''
    s << _create_input('input.jshtml', @input)
    s << _create_input('layout.jshtml', @layout)
    s << <<END
var context = #{@context};
var engine = new Tenjin.Engine({layout: 'layout.jshtml'});
var output = engine.render('input.jshtml', context);
print(output);
END
    output = _invoke_js(s)
    assert_text_equal(@output_with_layout || '', output, '** render input with layout')
    ##
  ensure
    _remove_files 'input.pyhtml', 'layout.pyhtml'
  end


  ## ----------------------------------------
  def test_compile
    @input = <<'END'
<?js //@ARGS title, items ?>
<h1>${title}</h1>
<ul>
<?js for (var i = 0, n = items.length; i < n; i++) { ?>
  <li>${items[i]}</li>
<?js } ?>
</ul>
END
    @script = <<'END'
var _buf = '';  var title = _context['title']; var items = _context['items'];
 _buf += '<h1>' + escapeXml(title) + '</h1>\n\
<ul>\n';
 for (var i = 0, n = items.length; i < n; i++) {
 _buf += '  <li>' + escapeXml(items[i]) + '</li>\n';
 }
 _buf += '</ul>\n';
_buf
END
    @compiled = <<'END'
function (_context) {
    var _buf = "";
    var title = _context.title;
    var items = _context.items;
    _buf += "<h1>" + escapeXml(title) + "</h1>\n<ul>\n";
    for (var i = 0, n = items.length; i < n; i++) {
        _buf += "  <li>" + escapeXml(items[i]) + "</li>\n";
    }
    _buf += "</ul>\n";
    return _buf;
}
END
    if RHINO
      @compiled = "\n#{@compiled}\n".gsub(/_context.(title|items)/, '_context["\1"]')
    end
    @compiled.chomp!
    @original = <<'END'
function (_context) {
    this.compile(_context);
    return this.render(_context);
}
END
    if RHINO
      @original = "\n#{@original}\n"
    end
    @original.chomp!
    ## convert input
    s = _create_input('input.jshtml', @input)
    s << <<'END'
var template = new Tenjin.Template();
var script = template.convert(input);
print(script);
END
    script = _invoke_js(s)
    assert_text_equal(@script, script, '** convert input')
    ## compiled function
    s = _create_input('input.jshtml', @input)
    s << <<'END'
var template = new Tenjin.Template();
template.convert(input);
template.compile();
print(template.render);
END
    funcdef = _invoke_js(s)
    assert_text_equal(@compiled, funcdef, '** compiled function')
    ## compiled automatically when this.args is true
    desc = 'compiled automatically'
    s = _create_input('input.jshtml', @input)
    s << <<'END'
var template = new Tenjin.Template();
template.convert(input);
print("** before render()="+template.render);
var output = template.render({'title': 'Compile Test', 'items': [10, 20, 30]});
print("** after render()="+template.render);
template.compile()
print("** after compile()="+template.render);
END
    result = _invoke_js(s)
    expected = "** before render()=#{@original}\n** after render()=#{@compiled}\n** after compile()=#{@compiled}"
    assert_text_equal(expected, result, "** #{desc}")
  end


  ## ----------------------------------------
  def test_cache
    @content = <<'END'
<?js //@ARGS x,y , z ?>
<p>
x = #{x}
y = #{y}
z = #{z}
</p>
END
    @layout = <<'END'
<html>
 <body>
#{_content}
 </body>
</html>
END
    @content_script = <<'END'
var _buf = '';  var x = _context['x']; var y = _context['y']; var z = _context['z'];
 _buf += '<p>\n\
x = ' + [x].join() + '\n\
y = ' + [y].join() + '\n\
z = ' + [z].join() + '\n\
</p>\n';
_buf
END
    @layout_script = <<'END'
var _buf = '';  _buf += '<html>\n\
 <body>\n\
' + [_content].join() + '\n\
 </body>\n\
</html>\n';
_buf
END
    @output = <<END
<html>
 <body>
<p>
x = 10
y = 20
z = 30
</p>

 </body>
</html>
END
    @content_render = <<'END'
function (_context) {
    var _buf = '';
    var x = _context.x;
    var y = _context.y;
    var z = _context.z;
    _buf += "<p>\nx = " + [x].join() + "\ny = " + [y].join() + "\nz = " + [z].join() + "\n</p>\n";
    return _buf;
}
END
    if RHINO
      @content_render = "\n#{@content_render}\n".gsub(/\.([xyz]);/, '["\1"];').sub(/''/, '""')
    end
    @content_render.chomp!
    @layout_render = <<'END'
function (_context) {
    var _content = _context._content;
    var _buf = "";
    _buf += "<html>\n <body>\n" + [_content].join() + "\n </body>\n</html>\n";
    return _buf;
}
END
    if RHINO
      @layout_render = "\n#{@layout_render}\n"
    end
    @layout_render.chomp!
#    @original_render = <<'END'
#function (_context) {
#    if (_context) {
#        eval(Tenjin._setlocalvarscode(_context));
#    } else {
#        _context = {};
#    }
#    return eval(this.script);
#}
#END
    @original_render = <<'END'
function (_context) {
    var x = _context.x;
    var y = _context.y;
    var z = _context.z;
    var _engine = _context._engine;
    var _layout = _context._layout;
    var _content = _context._content;
    var _buf = "";
    _buf += "<html>\n <body>\n" + [_content].join() + "\n </body>\n</html>\n";
    return _buf;
}
END
    if RHINO
      @original_render = "\n#{@original_render}\n"
    end
    @original_render.chomp!

    @compiled_render = <<'END'
function (_context) {
    var x = _context.x;
    var y = _context.y;
    var z = _context.z;
    var _engine = _context._engine;
    var _layout = _context._layout;
    var _buf = "";
    var x = _context.x;
    var y = _context.y;
    var z = _context.z;
    _buf += "<p>\nx = " + [x].join() + "\ny = " + [y].join() + "\nz = " + [z].join() + "\n</p>\n";
    return _buf;
}
END
    if RHINO
      @compiled_render = "\n#{@compiled_render}\n".gsub(/\.([xyz]);/, '["\1"];')
    end
    @compiled_render.chomp!

    @context = "{x:10, y:20, z:30}"
    @content_args = "//@ARGS x,y,z\n"
    @layout_args  = "//@ARGS _content\n"

    ## has file object?
    result = _invoke_js('print(typeof(File));')
    has_file_object = result !~ /undefined/

    ## when no cache file exist
    desc = 'when no cache file exist'
    content = @content
    layout  = @layout
    s = ''
    s << _create_input('test_content.jshtml', content)
    s << _create_input('test_layout.jshtml',  layout)
    s << <<"END"
var engine = new Tenjin.Engine({cache:true, prefix:'test_', postfix:'.jshtml', layout:':layout'});
var context = #{@context};
var output = engine.render(':content', context);
print(output);
print("---");
//// template args
print(Tenjin.readFile('test_content.jshtml.cache'));
print("---");
//// no template args
print(Tenjin.readFile('test_layout.jshtml.cache'));
print("---");
//// render() function
print(engine.getTemplate(':content').render);  // compiled
print("---");
print(engine.getTemplate(':layout').render);  // not compiled
END

    actual = _invoke_js(s)
        #=> TypeError: :content: Cannot access file status for test_content.jshtml.cache
    expected = [@output,@content_args+@content_script,@layout_script,@content_render,@original_render].join("\n---\n")
    skip_when(SMONKEY, "spidermonkey 1.7 raises error when cache is enabled.") {
      assert_text_equal(expected, actual, "** #{desc}")
    }

    ## when cache file exists
    desc = 'when cache file exists'
    content_script = @content_script
    layout_script = @layout_args + "var _content = _context._content;\n" + @layout_script
    s = ''
    if has_file_object
      File.write('test_content.jshtml.cache', content_script)
      File.write('test_layout.jshtml.cache',  layout_script)
    else
      s << _create_input('test_content.jshtml.cache', content_script)
      s << _create_input('test_layout.jshtml.cache',  layout_script)
    end
    s << <<"END"
var engine = new Tenjin.Engine({cache:true, prefix:'test_', postfix:'.jshtml', layout:':layout'});
var context = #{@context};
var output = engine.render(':content', context);
print(output);
print("---");
//// content template has no args
var t = engine.getTemplate(':content');
print(t.args === null ? 'null' : typeof(t.args));
print("---");
//// layout template has an argument
var t = engine.getTemplate(':layout');
print(t.args === null ? 'null' : typeof(t.args));
for (var p in t.args) { print(p + ':' + t.args[p]); }
//// render() function
print("---");
print(engine.getTemplate(':content').render);
print("---");
print(engine.getTemplate(':layout').render);
END
    actual = _invoke_js(s)
    expected = <<END
null
---
object
0:_content
END
    if RHINO
      @compiled_render = @compiled_render.sub('["x"]', '.x').sub('["y"]', '.y').sub('["z"]', '.z')
    end
    #expected = [@output,expected.chomp,@original_render,@layout_render].join("\n---\n")
    expected = [@output,expected.chomp,@compiled_render,@layout_render].join("\n---\n")
    assert_text_equal(expected, actual, "** #{desc}")
  ensure
    _remove_files %w[test_content.jshtml test_content.jshtml.cache
                     test_layout.jshtml  test_layout.jshtml.cache ]
  end



  def test_placeholder # and captureAs
    @content = <<'END'
<html>
  <body>
    <?js startCapture('content_part'); ?>
    <ul>
    <?js for (var i = 0, n = items.length; i < n; i++) { ?>
      <li>${items[i]}</li>
    <?js } ?>
    </ul>
    <?js stopCapture(); ?>
    <?js startCapture('footer_part'); ?>
    <div id="footer">
      <p>copyright(c) 2007 kuwata-lab.com all rights are reserved</p>
    </div>
    <?js stopCapture(); ?>
  </body>
</body>
END
    @layout = <<'END'
<?js _context._buf = _buf; ?>
<html>
  <body>
    <!-- HEADER -->
    <?js startPlaceholder('header_part'); ?>
    <h1>${title}</h1>
    <?js stopPlaceholder(); ?>
    <!-- HEADER -->
    <!-- CONTENT -->
    <?js startPlaceholder('content_part'); ?>
    <?js stopPlaceholder(); ?>
    <!-- /CONTENT -->
    <!-- FOOTER -->
    <?js startPlaceholder('footer_part'); ?>
    <hr />
    <address>webmaster@localhost</address>
    <?js stopPlaceholder(); ?>
    <!-- /FOOTER -->
  </body>
</html>
END
    @output = <<'END'
--- content_part ---
    <ul>
      <li>AAA</li>
      <li>BBB</li>
      <li>CCC</li>
    </ul>

--- footer_part ---
    <div id="footer">
      <p>copyright(c) 2007 kuwata-lab.com all rights are reserved</p>
    </div>
END
    @output2 = <<'END'
<html>
  <body>
    <!-- HEADER -->
    <h1>Example</h1>
    <!-- HEADER -->
    <!-- CONTENT -->
    <ul>
      <li>AAA</li>
      <li>BBB</li>
      <li>CCC</li>
    </ul>
    <!-- /CONTENT -->
    <!-- FOOTER -->
    <div id="footer">
      <p>copyright(c) 2007 kuwata-lab.com all rights are reserved</p>
    </div>
    <!-- /FOOTER -->
  </body>
</html>
END
    ## capture test
    s = ''
    s << _create_input('test_content.jshtml', @content)
    s << <<END
var engine = new Tenjin.Engine();
var context = { title: 'Example', items: ['AAA', 'BBB', 'CCC'] };
var output = engine.render('test_content.jshtml', context);
print('--- content_part ---'); print(context['content_part']);
print('--- footer_part ---'); print(context['footer_part']);
END
    output = _invoke_js(s)
    assert_text_equal(@output, output, '** capture test')
    ## _context.capturedAs()
    s = ''
    s << _create_input('test_content.jshtml', @content)
    s << _create_input('test_layout.jshtml',  @layout)
    s << <<END
var engine = new Tenjin.Engine({prefix:'test_', postfix:'.jshtml', layout:':layout'});
var context = { title: 'Example', items: ['AAA', 'BBB', 'CCC'] };
var output = engine.render(':content', context);
print(output);
END
    output = _invoke_js(s)
    assert_text_equal(@output2, output, '** capturedAs()')
    ## placeholder
    s = ''
    s << _create_input('test_content.jshtml', @content)
    s << _create_input('test_layout.jshtml',  @layout)
    s << <<END
var engine = new Tenjin.Engine({prefix:'test_', postfix:'.jshtml', layout:':layout'});
var context = { title: 'Example', items: ['AAA', 'BBB', 'CCC'] };
var output = engine.render(':content', context);
print(output);
END
    output = _invoke_js(s)
    assert_text_equal(@output2, output, '** placeholder')
  ensure
    _remove_files 'test_content.jshtml', 'test_layout.jshtml'
  end


  def test_path
    @input = <<'END'
<ul>
<?js for (var i = 0, n = items.length; i < n; i++) { ?>
  <li>${i+1}: ${items[i]}</li>
<?js } ?>
</ul>
END
    @output = <<'END'
<ul>
  <li>1: A</li>
  <li>2: B</li>
  <li>3: C</li>
</ul>
END
    ## render with path
    path = 'tmppath'
    FileUtils.mkdir_p(path)
    s = _create_input("#{path}/test_path.jshtml", @input)
    s << <<END
var engine = new Tenjin.Engine({cache:false, path:['#{path}'], postfix:'.jshtml'});
var output = engine.render(':test_path', {items: ['A','B','C']});
print(output);
END
    output = _invoke_js(s)
    assert_text_equal(@output, output, '** path')
  ensure
    #FileUtils.rm_rf(path) if File.directory?(path)
  end


  ## ----------------------------------------
  def test_emptystr
    @input = <<'END'
<p>
null: "#{x}", "${x}"
undefined: "#{y}", "${y}"
</p>
END

    @script1 = <<'END'
var _buf = '';  _buf += '<p>\n\
null: "' + [x].join() + '", "' + escapeXml(x) + '"\n\
undefined: "' + [y].join() + '", "' + escapeXml(y) + '"\n\
</p>\n';
_buf
END

    @script2 = <<'END'
var _buf = '';  _buf += '<p>\n\
null: "' + (x) + '", "' + escapeXml(x) + '"\n\
undefined: "' + (y) + '", "' + escapeXml(y) + '"\n\
</p>\n';
_buf
END

    @context = <<END
{ x: null, y: undefined }
END

    @output1 = <<'END'
<p>
null: "", "null"
undefined: "", "undefined"
</p>
END

    @output2 = <<'END'
<p>
null: "null", "null"
undefined: "undefined", "undefined"
</p>
END
    ## Tenjin.Template#convert()
    fname = 'input.jshtml'
    s = _create_input(fname, @input);
    s << "print((new Tenjin.Template()).convert(input));"
    script = _invoke_js(s)
    assert_text_equal(@script1, script, '** Tenjin.Template#convert()')
    #
    s = _create_input(fname, @input);
    s << "print((new Tenjin.Template({emptystr:false})).convert(input));"
    script = _invoke_js(s)
    assert_text_equal(@script2, script, '** Tenjin.Template#convert()')
    ## Tenjin.Template#render()
    s = _create_input(fname, @input)
    s << <<END
var template = new Tenjin.Template();
var script   = template.convert(input);
var context  = #{@context};
var output   = template.render(context);
print(output);
END
    output = _invoke_js(s)
    assert_text_equal(@output1, output, '** Tenjin.Template#render()')
    #
    s = _create_input(fname, @input)
    s << <<END
var template = new Tenjin.Template({emptystr: false});
var script   = template.convert(input);
var context  = #{@context};
var output   = template.render(context);
print(output);
END
    output = _invoke_js(s)
    assert_text_equal(@output2, output, '** Tenjin.Template#render()')
    ##
  ensure
    _remove_files 'input.jshtml'
  end


  if ENV['TEST']
    target = 'test_' + ENV['TEST']
    test_methods = self.instance_methods.grep(/^test_/)
    test_methods.each {|m| private m unless m == target }
  end


end
