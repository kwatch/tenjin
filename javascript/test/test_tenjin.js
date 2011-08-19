///
/// $Release: $
/// $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
/// $License: MIT License $
///


var fs = require('fs');
    _init = require('./_init');

var oktest = require('oktest');
var topic = oktest.topic,
    spec  = oktest.spec,
    ok    = oktest.ok,
    NG    = oktest.NG,
    precond = oktest.precond;

var Tenjin = require('tenjin');



topic('Tenjin.Template', function(t) {


  topic('#convert()', function(t) {

    spec("converts input string into JS code.", function() {
      var input = (
        ''
        + '<table>\n'
        + '<?js\n'
        + '  var len = list.length\n'
        + '  for (var i = 0; i < len; i++) {\n'
        + '    var item = list[i];\n'
        + ' ?>\n'
        + '  <tr>\n'
        + '    <td>#{item}</td>\n'
        + '    <td>${item}</td>\n'
        + '  </tr>\n'
        + '<?js } ?>\n'
        + '</table>\n'
      );
      var script = (
        ''
        + 'var _buf = \'\';  _buf += \'<table>\\n\';\n'
        + '\n'
        + '  var len = list.length\n'
        + '  for (var i = 0; i < len; i++) {\n'
        + '    var item = list[i];\n'
        + '\n'
        + ' _buf += \'  <tr>\\n\\\n'
        + '    <td>\' + toStr(item) + \'</td>\\n\\\n'
        + '    <td>\' + escapeXml(item) + \'</td>\\n\\\n'
        + '  </tr>\\n\';\n'
        + ' }\n'
        + ' _buf += \'</table>\\n\';\n'
        + '_buf\n'
      );
      var tpl = new Tenjin.Template();
      var actual = tpl.convert(input);
      ok (actual).eq(script);
    });

  });


  topic("#render()", function() {

    spec("renders template file with context data.", function(jshtml) {
      var input = (
        ''
        + '<ul>\n'
        + '<?js for (var i=0, len=items.length; i<len; i++) { ?>\n'
        + '  <li id="item-${i+1}">${items[i]}</li>\n'
        + '<?js } ?>\n'
        + '</ul>\n'
        );
      var expected_output = (
        ''
        + '<ul>\n'
        + '  <li id="item-1">Haruhi</li>\n'
        + '  <li id="item-2">Mikuru</li>\n'
        + '  <li id="item-3">Yuki</li>\n'
        + '</ul>\n'
      );
      Tenjin.writeFile(jshtml, input);
      var t = new Tenjin.Template(jshtml);
      var context = {items: ['Haruhi', 'Mikuru', 'Yuki']};
      var output = t.render(context);
      ok (output).eq(expected_output);
    });

  });


});


topic('Tenjin.Engine', function() {

  var input = (
    ''
    + '<table>\n'
    + '  <?js for (var i = 0, n = items.length; i < n; i++) { ?>\n'
    + '  <tr class="#{i % 2 == 0 ? \'odd\' : \'even\'}">\n'
    + '    <td>#{i+1}</td>\n'
    + '    <td>${items[i]}</td>\n'
    + '  </tr>\n'
    + '  <?js } ?>\n'
    + '</table>\n'
  );
  var script_expected = (
    ''
    + 'var _buf = \'\';  _buf += \'<table>\\n\';\n'
    + '   for (var i = 0, n = items.length; i < n; i++) {\n'
    + ' _buf += \'  <tr class="\' + toStr(i % 2 == 0 ? \'odd\' : \'even\') + \'">\\n\\\n'
    + '    <td>\' + toStr(i+1) + \'</td>\\n\\\n'
    + '    <td>\' + escapeXml(items[i]) + \'</td>\\n\\\n'
    + '  </tr>\\n\';\n'
    + '   }\n'
    + ' _buf += \'</table>\\n\';\n'
    + '_buf\n'
  );
  var output_expected = (
    ''
    + '<table>\n'
    + '  <tr class="odd">\n'
    + '    <td>1</td>\n'
    + '    <td>&lt;Haruhi&gt;</td>\n'
    + '  </tr>\n'
    + '  <tr class="even">\n'
    + '    <td>2</td>\n'
    + '    <td>Mikuru&amp;Michiru</td>\n'
    + '  </tr>\n'
    + '  <tr class="odd">\n'
    + '    <td>3</td>\n'
    + '    <td>&quot;Yuki&quot;</td>\n'
    + '  </tr>\n'
    + '</table>\n'
  );

  this.provideContext = function() {
    var context = {
      items: ["<Haruhi>", "Mikuru&Michiru", '"Yuki"']
    };
    return context;
  };

  var layout_input = (
    ''
    + '<!DOCTYPE html>\n'
    + '<html>\n'
    + '  <body>\n'
    + '  #{_content}\n'
    + '  </body>\n'
    + '</html>\n'
  );

  var output_layout_expected = (
    ''
    + '<!DOCTYPE html>\n'
    + '<html>\n'
    + '  <body>\n'
    //+ '#{_content}\n'
    + '  ' + output_expected + '\n'
    + '  </body>\n'
    + '</html>\n'
  );

  this.before = function before(this_) {
    this_.cleaner = new oktest.fixture.Cleaner();
    this_.writeFile = function(fname, content) {
      Tenjin.writeFile(fname, content);
      this_.cleaner.add(fname);
      this_.cleaner.add(fname + '.cache');
    };
  };

  this.after = function after(this_) {
    this_.cleaner.clean();
  };

  var writeFile = Tenjin.writeFile;


  topic('#render()', function() {

    spec("renders template with context data.", function(jshtml, context) {
      writeFile(jshtml, input);
      var engine = new Tenjin.Engine({cache:false});
      var output = engine.render(jshtml, context);
      ok (output).eq(output_expected);
    });

    spec("creates cache file when 'cache' option is true.", function(jshtml, context) {
      writeFile(jshtml, input);
      var engine = new Tenjin.Engine({cache:true});
      var cache_file = jshtml + '.cache';
      precond (cache_file).notExist();
      var output = engine.render(jshtml, context);
      //ok (output).eq(output_expected);
      ok (cache_file).exists();
      var cached = Tenjin.readFile(cache_file);
      ok (cached).eq(script_expected);
    });

    spec("not create cache file when 'cache' option is false.", function(jshtml, context) {
      writeFile(jshtml, input);
      var engine = new Tenjin.Engine({cache:false});
      var cache_file = jshtml + '.cache';
      precond (cache_file).notExist();
      var output = engine.render(jshtml, context);
      //ok (output).eq(output_expected);
      ok (cache_file).notExist();
    });

    spec("uses layout templates when 'layout' option is specified.", function(jshtml, context) {
      writeFile(jshtml, input);
      var layout_fname = '_test_layout.jshtml';
      writeFile(layout_fname, layout_input);
      this.cleaner.add(layout_fname, layout_fname + '.cache');
      var engine = new Tenjin.Engine({layout: layout_fname});
      var output = engine.render(jshtml, context);
      ok (output).eq(output_layout_expected);
    });

  });


  topic("#macroHandlers", function() {

    spec("echo() is available in template file.", function(jshtml) {
      var input = "<p>x=<?js echo(x); ?></p>";
      writeFile(jshtml, input);
      var engine = new Tenjin.Engine();
      var output = engine.render(jshtml, {x: 'SOS'});
      ok (output).match(/<p>x=SOS<\/p>/);
    });

    spec("include() is available in template file.", function(jshtml) {
      var input_form = (
        ''
        + '  <p>\n'
        + '    <label for="name">Name</label>:\n'
        + '    <input type="text" id="name" name="name" value="${user.name}" />\n'
        + '  </p>\n'
        + '  <p>\n'
        + '    <label for="email">Email</label>:\n'
        + '    <input type="text" id="email" name="email" value="${user.email}" />\n'
        + '  </p>\n'
      );
      var input_create = (
        ''
        + '<form action="/cgi-bin/edit.cgi" method="post">\n'
        + '  <?js include(\'form.jshtml\'); ?>\n'
        + '  <input type="submit" name="submit" value="Edit"/>\n'
        + '</form>\n'
      );
      var input_footer = (
        ''
        + '<hr />\n'
        + '<address><a href="webmaster@mail.com">webmaster@mail.com</a></address>\n'
      );
      var input_layout = (
        ''
        + '<html>\n'
        + '  <body>\n'
        + '    <h1>${title}</h1>\n'
        + '    <div id="content">\n'
        + '      <?js include(\'create.jshtml\'); ?>\n'
        + '    </div>\n'
        + '    <div id="footer">\n'
        + '      <?js include("footer.jshtml"); ?>\n'
        + '    </div>\n'
        + '  </body>\n'
        + '</html>\n'
      );
      var script_layout = (
        ''
        + 'var _buf = \'\';  _buf += \'<html>\\n\\\n'
        + '  <body>\\n\\\n'
        + '    <h1>\' + escapeXml(title) + \'</h1>\\n\\\n'
        + '    <div id="content">\\n\';\n'
        + '       _buf += _context._engine.render(\'create.jshtml\', _context, false);\n'
        + ' _buf += \'    </div>\\n\\\n'
        + '    <div id="footer">\\n\';\n'
        + '       _buf += _context._engine.render("footer.jshtml", _context, false);\n'
        + ' _buf += \'    </div>\\n\\\n'
        + '  </body>\\n\\\n'
        + '</html>\\n\';\n'
        + '_buf\n'
      );
      var context = {
        title: 'Edit User',
        user: { name: 'Foo', email: 'foo@mail.com' }
      };
      var output_expected = (
        ''
        + '<html>\n'
        + '  <body>\n'
        + '    <h1>Edit User</h1>\n'
        + '    <div id="content">\n'
        + '<form action="/cgi-bin/edit.cgi" method="post">\n'
        + '  <p>\n'
        + '    <label for="name">Name</label>:\n'
        + '    <input type="text" id="name" name="name" value="Foo" />\n'
        + '  </p>\n'
        + '  <p>\n'
        + '    <label for="email">Email</label>:\n'
        + '    <input type="text" id="email" name="email" value="foo@mail.com" />\n'
        + '  </p>\n'
        + '  <input type="submit" name="submit" value="Edit"/>\n'
        + '</form>\n'
        + '    </div>\n'
        + '    <div id="footer">\n'
        + '<hr />\n'
        + '<address><a href="webmaster@mail.com">webmaster@mail.com</a></address>\n'
        + '    </div>\n'
        + '  </body>\n'
        + '</html>\n'
      );
      //
      var e, t, fname, output, _cleaner = this.cleaner;
      // script
      this.writeFile('layout.jshtml', input_layout);
      e = new Tenjin.Engine();
      t = e.getTemplate('layout.jshtml');
      ok (t.script).eq(script_layout);
      // output
      this.writeFile('form.jshtml',   input_form);
      this.writeFile('create.jshtml', input_create);
      this.writeFile('footer.jshtml', input_footer);
      this.writeFile('layout.jshtml', input_layout);
      output = e.render('layout.jshtml', context);
      ok (output).eq(output_expected);
    });

    spec("capture() is available in template file.", function() {
      var input = (
        ''
        + '<html>\n'
        + '  <body>\n'
        + '    <h1><?js startCapture("title"); ?>Start&amp;Stop Capture<?js stopCapture(); ?></h1>\n'
        + '    <div>\n'
        + '  <?js startCapture("maincontent"); ?>\n'
        + '      <ul>\n'
        + '    <?js for (var i = 0, n = list.length; i < n; i++) { ?>\n'
        + '        <li>${list[i]}</li>\n'
        + '    <?js } ?>\n'
        + '      </ul>\n'
        + '  <?js stopCapture(); ?>\n'
        + '    </div>\n'
        + '  </body>\n'
        + '</html>\n'
      );
      var layout = (
        ''
        + '<html xml:lang="en" lang="en">\n'
        + '  <head>\n'
        + '    <title>#{title}</title>\n'
        + '  </head>\n'
        + '  <body>\n'
        + '    <h1>#{title}</h1>\n'
        + '    <div id="content">\n'
        + '#{maincontent}\n'
        + '    </div>\n'
        + '  </body>\n'
        + '</html>\n'
      );
      var script_input = (
        ''
        + 'var _buf = \'\';  _buf += \'<html>\\n\\\n'
        + '  <body>\\n\\\n'
        + '    <h1>\'; var _buf_bkup = _buf; _buf = \'\'; var _capture_varname = "title"; _buf += \'Start&amp;Stop Capture\'; _context[_capture_varname] = _buf; _buf = _buf_bkup; _buf += \'</h1>\\n\\\n'
        + '    <div>\\n\';\n'
        + '   var _buf_bkup = _buf; _buf = \'\'; var _capture_varname = "maincontent";\n'
        + ' _buf += \'      <ul>\\n\';\n'
        + '     for (var i = 0, n = list.length; i < n; i++) {\n'
        + ' _buf += \'        <li>\' + escapeXml(list[i]) + \'</li>\\n\';\n'
        + '     }\n'
        + ' _buf += \'      </ul>\\n\';\n'
        + '   _context[_capture_varname] = _buf; _buf = _buf_bkup;\n'
        + ' _buf += \'    </div>\\n\\\n'
        + '  </body>\\n\\\n'
        + '</html>\\n\';\n'
        + '_buf\n'
      );
      var script_layout = (
        ''
        + 'var _buf = \'\';  _buf += \'<html xml:lang="en" lang="en">\\n\\\n'
        + '  <head>\\n\\\n'
        + '    <title>\' + toStr(title) + \'</title>\\n\\\n'
        + '  </head>\\n\\\n'
        + '  <body>\\n\\\n'
        + '    <h1>\' + toStr(title) + \'</h1>\\n\\\n'
        + '    <div id="content">\\n\\\n'
        + '\' + toStr(maincontent) + \'\\n\\\n'
        + '    </div>\\n\\\n'
        + '  </body>\\n\\\n'
        + '</html>\\n\';\n'
        + '_buf\n'
      );
      var context = { list: ['<AAA>', 'B&B', '"CCC"'] };
      var output_without_layout = (
        ''
        + '<html>\n'
        + '  <body>\n'
        + '    <h1></h1>\n'
        + '    <div>\n'
        + '    </div>\n'
        + '  </body>\n'
        + '</html>\n'
      );
      var output_with_layout = (
        ''
        + '<html xml:lang="en" lang="en">\n'
        + '  <head>\n'
        + '    <title>Start&amp;Stop Capture</title>\n'
        + '  </head>\n'
        + '  <body>\n'
        + '    <h1>Start&amp;Stop Capture</h1>\n'
        + '    <div id="content">\n'
        + '      <ul>\n'
        + '        <li>&lt;AAA&gt;</li>\n'
        + '        <li>B&amp;B</li>\n'
        + '        <li>&quot;CCC&quot;</li>\n'
        + '      </ul>\n'
        + '\n'
        + '    </div>\n'
        + '  </body>\n'
        + '</html>\n'
      );
      //
      var e, t, fname, output;
      // convert input
      fname = 'input.jshtml';
      this.writeFile(fname, input);
      e = new Tenjin.Engine();
      t = e.getTemplate(fname);
      ok (t.script).eq(script_input);
      // convert layout
      fname = 'layout.jshtml';
      this.writeFile(fname, layout);
      t = e.getTemplate(fname);
      ok (t.script).eq(script_layout);
      // render input without layout
      output = e.render('input.jshtml', context);
      ok (output).eq(output_without_layout);
      // render input with layout
      e = new Tenjin.Engine({layout: 'layout.jshtml'});
      output = e.render('input.jshtml', context);
      ok (output).eq(output_with_layout);
    });

  });


  topic('#compile', function() {

    spec("returns function object.", function() {
      var input = (
        ''
        + '<?js //@ARGS title, items ?>\n'
        + '<h1>${title}</h1>\n'
        + '<ul>\n'
        + '<?js for (var i = 0, n = items.length; i < n; i++) { ?>\n'
        + '  <li>${items[i]}</li>\n'
        + '<?js } ?>\n'
        + '</ul>\n'
      );
      var script = (
        ''
        + 'var _buf = \'\';  var title = _context[\'title\']; var items = _context[\'items\'];\n'
        + ' _buf += \'<h1>\' + escapeXml(title) + \'</h1>\\n\\\n'
        + '<ul>\\n\';\n'
        + ' for (var i = 0, n = items.length; i < n; i++) {\n'
        + ' _buf += \'  <li>\' + escapeXml(items[i]) + \'</li>\\n\';\n'
        + ' }\n'
        + ' _buf += \'</ul>\\n\';\n'
        + '_buf\n'
      );
      var compiled_spidermonkey = (
        ''
        + 'function (_context) {\n'
        + '    var _buf = "";\n'
        + '    var title = _context.title;\n'
        + '    var items = _context.items;\n'
        + '    _buf += "<h1>" + escapeXml(title) + "</h1>\\n<ul>\\n";\n'
        + '    for (var i = 0, n = items.length; i < n; i++) {\n'
        + '        _buf += "  <li>" + escapeXml(items[i]) + "</li>\\n";\n'
        + '    }\n'
        + '    _buf += "</ul>\\n";\n'
        + '    return _buf;\n'
        + '}\n'
      );
      var copmpiled_rhino = ("\n" + compiled_spidermonkey + "\n").replace(/_context\.(title|items)/g, '_context["\1"]');
      var compiled_nodejs = (
        ''
        + 'function (_context) { var _buf = \'\';  var title = _context[\'title\']; var items = _context[\'items\'];\n'
        + ' _buf += \'<h1>\' + escapeXml(title) + \'</h1>\\n\\\n'
        + '<ul>\\n\';\n'
        + ' for (var i = 0, n = items.length; i < n; i++) {\n'
        + ' _buf += \'  <li>\' + escapeXml(items[i]) + \'</li>\\n\';\n'
        + ' }\n'
        + ' _buf += \'</ul>\\n\';\n'
        + 'return _buf\n'
        + '}'
      );
      var compiled = compiled_nodejs;
      //
      var original_spidermonkey = (
        ''
        + 'function (_context) {\n'
        + '    this.compile(_context);\n'
        + '    return this.render(_context);\n'
        + '}\n'
      );
      var original_rhino = "\n" + original_spidermonkey + "\n";
      var original_nodejs = (
        ''
        + 'function (_context) {\n'
        + '    this.compile(_context);\n'
        + '    return this.render(_context);\n'
        + '  }'
      );
      var original = original_nodejs;
      //
      var t;
      // convert input
      this.writeFile('input.jshtml', input);
      t = new Tenjin.Template();
      ok (t.convert(input)).eq(script);
      // compiled function
      this.writeFile('input.jshtml', input);
      t = new Tenjin.Template();
      t.convert(input);
      t.compile();
      ok (t.render).isFunction();
      ok (String(t.render)).eq(compiled);
      // compiled automatically when this.args is true
      var desc = 'compiled automatically';
      this.writeFile('input.jshtml', input);
      t = new Tenjin.Template();
      t.convert(input);
      ok (String(t.render)).eq(original);
      t.render({title: 'Compile Test', items: [10, 20, 30]});
      ok (String(t.render)).eq(compiled);
      t.compile();
      ok (String(t.render)).eq(compiled);
    });

  });


  topic('#cache', function() {

    spec("", function() {
      var content = (
        ''
        + '<?js //@ARGS x,y , z ?>\n'
        + '<p>\n'
        + 'x = #{x}\n'
        + 'y = #{y}\n'
        + 'z = #{z}\n'
        + '</p>\n'
      );
      var layout = (
        ''
        + '<html>\n'
        + ' <body>\n'
        + '#{_content}\n'
        + ' </body>\n'
        + '</html>\n'
      );
      var content_script = (
        ''
        + 'var _buf = \'\';  var x = _context[\'x\']; var y = _context[\'y\']; var z = _context[\'z\'];\n'
        + ' _buf += \'<p>\\n\\\n'
        + 'x = \' + toStr(x) + \'\\n\\\n'
        + 'y = \' + toStr(y) + \'\\n\\\n'
        + 'z = \' + toStr(z) + \'\\n\\\n'
        + '</p>\\n\';\n'
        + '_buf\n'
      );
      var layout_script = (
        ''
        + 'var _buf = \'\';  _buf += \'<html>\\n\\\n'
        + ' <body>\\n\\\n'
        + '\' + toStr(_content) + \'\\n\\\n'
        + ' </body>\\n\\\n'
        + '</html>\\n\';\n'
        + '_buf\n'
      );
      var output_expected = (
        ''
        + '<html>\n'
        + ' <body>\n'
        + '<p>\n'
        + 'x = 10\n'
        + 'y = 20\n'
        + 'z = 30\n'
        + '</p>\n'
        + '\n'
        + ' </body>\n'
        + '</html>\n'
      );
      var content_render_spidermonkey = (
        ''
        + 'function (_context) {\n'
        + '    var _buf = "";\n'
        + '    var x = _context.x;\n'
        + '    var y = _context.y;\n'
        + '    var z = _context.z;\n'
        + '    _buf += "<p>\\nx = " + toStr(x) + "\\ny = " + toStr(y) + "\\nz = " + toStr(z) + "\\n</p>\\n";\n'
        + '    return _buf;\n'
        + '}\n'
      );
      var content_render_rhino = ("\n" + content_render_spidermonkey + "\n").replace(/\.([xyz]);/g, '["\1"];');
      var content_render_nodejs = (
        ''
        + 'function (_context) { var _buf = \'\';  var x = _context[\'x\']; var y = _context[\'y\']; var z = _context[\'z\'];\n'
        + ' _buf += \'<p>\\n\\\n'
        + 'x = \' + toStr(x) + \'\\n\\\n'
        + 'y = \' + toStr(y) + \'\\n\\\n'
        + 'z = \' + toStr(z) + \'\\n\\\n'
        + '</p>\\n\';\n'
        + 'return _buf\n'
        + '}'
      );
      var content_render = content_render_nodejs;
      var layout_render_spidermonkey = (
        ''
        + 'function (_context) {\n'
        + '    var _content = _context._content;\n'
        + '    var _buf = "";\n'
        + '    _buf += "<html>\\n <body>\\n" + toStr(_content) + "\\n </body>\\n</html>\\n";\n'
        + '    return _buf;\n'
        + '}\n'
      );
      var layout_render_rhino = "\n" + layout_render_spidermonkey + "\n";
      var layout_render_nodejs = (
        ''
        + 'function (_context) { var _content = _context._content;\n'
        + 'var _buf = \'\';  _buf += \'<html>\\n\\\n'
        + ' <body>\\n\\\n'
        + '\' + toStr(_content) + \'\\n\\\n'
        + ' </body>\\n\\\n'
        + '</html>\\n\';\n'
        + 'return _buf\n'
        + '}'
      );
      var layout_render = layout_render_nodejs;
      //var original_render = (
      //  ''
      //  + 'function (_context) {\n'
      //  + '    if (_context) {\n'
      //  + '        eval(Tenjin._setlocalvarscode(_context));\n'
      //  + '    } else {\n'
      //  + '        _context = {};\n'
      //  + '    }\n'
      //  + '    return eval(this.script);\n'
      //  + '}\n'
      //);
      var original_render_spidermonkey = (
        ''
        + 'function (_context) {\n'
        + '    var x = _context.x;\n'
        + '    var y = _context.y;\n'
        + '    var z = _context.z;\n'
        + '    var _engine = _context._engine;\n'
        + '    var _layout = _context._layout;\n'
        + '    var _content = _context._content;\n'
        + '    var _buf = "";\n'
        + '    _buf += "<html>\\n <body>\\n" + toStr(_content) + "\\n </body>\\n</html>\\n";\n'
        + '    return _buf;\n'
        + '}\n'
      );
      var original_render_rhino = "\n" + original_render_spidermonkey + "\n";
      var original_render_nodejs = (
        ''
        + 'function (_context) { var x = _context.x; var y = _context.y; var z = _context.z; var _engine = _context._engine; var _layout = _context._layout; var _content = _context._content; var _buf = \'\';  _buf += \'<html>\\n\\\n'
        + ' <body>\\n\\\n'
        + '\' + toStr(_content) + \'\\n\\\n'
        + ' </body>\\n\\\n'
        + '</html>\\n\';\n'
        + 'return _buf\n'
        + '}'
      );
      var original_render = original_render_nodejs;
      var compiled_render_spidermoneky = (
        ''
        + 'function (_context) {\n'
        + '    var x = _context.x;\n'
        + '    var y = _context.y;\n'
        + '    var z = _context.z;\n'
        + '    var _engine = _context._engine;\n'
        + '    var _layout = _context._layout;\n'
        + '    var _buf = "";\n'
        + '    var x = _context.x;\n'
        + '    var y = _context.y;\n'
        + '    var z = _context.z;\n'
        + '    _buf += "<p>\\nx = " + toStr(x) + "\\ny = " + toStr(y) + "\\nz = " + toStr(z) + "\\n</p>\\n";\n'
        + '    return _buf;\n'
        + '}\n'
      );
      var compiled_render_rhino = ("\n" + compiled_render_spidermoneky + "\n").replace(/\.([xyz]);/g, '["\1"];');
      var compiled_render_nodejs = (
        ''
        + 'function (_context) { var x = _context.x; var y = _context.y; var z = _context.z; var _engine = _context._engine; var _layout = _context._layout; var _content = _context._content; var _buf = \'\';  _buf += \'<html>\\n\\\n'
        + ' <body>\\n\\\n'
        + '\' + toStr(_content) + \'\\n\\\n'
        + ' </body>\\n\\\n'
        + '</html>\\n\';\n'
        + 'return _buf\n'
        + ' }'
      );
      var compiled_render = compiled_render_nodejs;
      //
      var context = {x:10, y:20, z:30};
      var content_args = "//@ARGS x,y,z\n";
      var layout_args  = "//@ARGS _content\n";
      // when no cache file exist
      var desc = 'when no cache file exist';
      this.writeFile('test_content.jshtml', content);
      this.writeFile('test_layout.jshtml',  layout);
      var e = new Tenjin.Engine({cache:true, prefix:'test_', postfix:'.jshtml', layout:':layout'});
      ok (e.render(':content', context)).eq(output_expected);
      //// template args
      ok (Tenjin.readFile('test_content.jshtml.cache')).eq(content_args + content_script);
      //// no template args
      ok (Tenjin.readFile('test_layout.jshtml.cache')).eq(layout_script);
      //// render() function
      ok (String(e.getTemplate(':content').render)).eq(content_render); // compiled
      ok (String(e.getTemplate(':layout').render)).eq(original_render); // not compiled
      //// when cache file exists
      desc = 'when cache file exists';
      this.writeFile('test_content.jshtml.cache', content_script);
      this.writeFile('test_layout.jshtml.cache',  layout_args + "var _content = _context._content;\n" + layout_script);
      var e2 = new Tenjin.Engine({cache:true, prefix:'test_', postfix:'.jshtml', layout:':layout'});
      ok (e2.render(':content', context)).eq(output_expected);
      //// content template has no args
      var t1 = e2.getTemplate(':content');
      ok (t1.args).is(null);
      //// layout template has an argument
      var t2 = e2.getTemplate(':layout');
      ok (t2.args).deepEqual(['_content']);
      //// render() function
      var content_render2 = (
        ''
        + 'function (_context) { var x = _context.x; var y = _context.y; var z = _context.z; var _engine = _context._engine; var _layout = _context._layout; var _content = _context._content; var _buf = \'\';  var x = _context[\'x\']; var y = _context[\'y\']; var z = _context[\'z\'];\n'
        + ' _buf += \'<p>\\n\\\n'
        + 'x = \' + toStr(x) + \'\\n\\\n'
        + 'y = \' + toStr(y) + \'\\n\\\n'
        + 'z = \' + toStr(z) + \'\\n\\\n'
        + '</p>\\n\';\n'
        + 'return _buf\n'
        + '}'
      );
      ok (String(e2.getTemplate(':content').render)).eq(content_render2);
      ok (String(e2.getTemplate(':layout').render)).eq(layout_render);
    });

  });


  topic('placeholder', function() {

    spec('', function() {
      var content = (
        ''
        + '<html>\n'
        + '  <body>\n'
        + '    <?js startCapture(\'content_part\'); ?>\n'
        + '    <ul>\n'
        + '    <?js for (var i = 0, n = items.length; i < n; i++) { ?>\n'
        + '      <li>${items[i]}</li>\n'
        + '    <?js } ?>\n'
        + '    </ul>\n'
        + '    <?js stopCapture(); ?>\n'
        + '    <?js startCapture(\'footer_part\'); ?>\n'
        + '    <div id="footer">\n'
        + '      <p>copyright(c) 2007 kuwata-lab.com all rights are reserved</p>\n'
        + '    </div>\n'
        + '    <?js stopCapture(); ?>\n'
        + '  </body>\n'
        + '</body>\n'
      );
      var layout = (
        ''
        + '<?js _context._buf = _buf; ?>\n'
        + '<html>\n'
        + '  <body>\n'
        + '    <!-- HEADER -->\n'
        + '    <?js startPlaceholder(\'header_part\'); ?>\n'
        + '    <h1>${title}</h1>\n'
        + '    <?js stopPlaceholder(); ?>\n'
        + '    <!-- HEADER -->\n'
        + '    <!-- CONTENT -->\n'
        + '    <?js startPlaceholder(\'content_part\'); ?>\n'
        + '    <?js stopPlaceholder(); ?>\n'
        + '    <!-- /CONTENT -->\n'
        + '    <!-- FOOTER -->\n'
        + '    <?js startPlaceholder(\'footer_part\'); ?>\n'
        + '    <hr />\n'
        + '    <address>webmaster@localhost</address>\n'
        + '    <?js stopPlaceholder(); ?>\n'
        + '    <!-- /FOOTER -->\n'
        + '  </body>\n'
        + '</html>\n'
      );
      var output_expected = (
        ''
        + '--- content_part ---\n'
        + '    <ul>\n'
        + '      <li>AAA</li>\n'
        + '      <li>BBB</li>\n'
        + '      <li>CCC</li>\n'
        + '    </ul>\n'
        + '\n'
        + '--- footer_part ---\n'
        + '    <div id="footer">\n'
        + '      <p>copyright(c) 2007 kuwata-lab.com all rights are reserved</p>\n'
        + '    </div>\n'
      );
      var output2_expected = (
        ''
        + '<html>\n'
        + '  <body>\n'
        + '    <!-- HEADER -->\n'
        + '    <h1>Example</h1>\n'
        + '    <!-- HEADER -->\n'
        + '    <!-- CONTENT -->\n'
        + '    <ul>\n'
        + '      <li>AAA</li>\n'
        + '      <li>BBB</li>\n'
        + '      <li>CCC</li>\n'
        + '    </ul>\n'
        + '    <!-- /CONTENT -->\n'
        + '    <!-- FOOTER -->\n'
        + '    <div id="footer">\n'
        + '      <p>copyright(c) 2007 kuwata-lab.com all rights are reserved</p>\n'
        + '    </div>\n'
        + '    <!-- /FOOTER -->\n'
        + '  </body>\n'
        + '</html>\n'
      );
      /// capture test
      this.writeFile('test_content.jshtml', content);
      (function() {
        var engine = new Tenjin.Engine();
        var context = { title: 'Example', items: ['AAA', 'BBB', 'CCC'] };
        var output = engine.render('test_content.jshtml', context);
        var s = '--- content_part ---\n' + context['content_part'] + "\n"
              + '--- footer_part ---\n'  + context['footer_part'];
        ok (s).eq(output_expected);
      })();
      /// _context.capturedAs()
      this.writeFile('test_content.jshtml', content);
      this.writeFile('test_layout.jshtml',  layout);
      (function() {
        var engine  = new Tenjin.Engine({prefix:'test_', postfix:'.jshtml', layout:':layout'});
        var context = { title: 'Example', items: ['AAA', 'BBB', 'CCC'] };
        var output  = engine.render(':content', context);
        ok (output).eq(output2_expected);
      })();
      /// placeholder
      this.writeFile('test_content.jshtml', content);
      this.writeFile('test_layout.jshtml',  layout);
      (function() {
        var engine  = new Tenjin.Engine({prefix:'test_', postfix:'.jshtml', layout:':layout'});
        var context = { title: 'Example', items: ['AAA', 'BBB', 'CCC'] };
        var output  = engine.render(':content', context);
        ok (output).eq(output2_expected);
      })();
    });

  });


  topic('path', function() {

    spec('', function() {
      var input = (
        ''
        + '<ul>\n'
        + '<?js for (var i = 0, n = items.length; i < n; i++) { ?>\n'
        + '  <li>${i+1}: ${items[i]}</li>\n'
        + '<?js } ?>\n'
        + '</ul>\n'
      );
      var output_expected = (
        ''
        + '<ul>\n'
        + '  <li>1: A</li>\n'
        + '  <li>2: B</li>\n'
        + '  <li>3: C</li>\n'
        + '</ul>\n'
      );
      /// render with path
      var path = '_tmppath';
      fs.mkdirSync(path, 0755);
      this.cleaner.add(path);
      this.writeFile(path + "/test_path.jshtml", input);
      var engine = new Tenjin.Engine({cache:false, path:[path], postfix:'.jshtml'});
      var output = engine.render(':test_path', {items: ['A','B','C']});
      ok (output).eq(output_expected);
    });

  });


  topic('emptystr', function() {

    spec('', function() {
      var input = (
        ''
        + '<p>\n'
        + 'null: "#{x}", "${x}"\n'
        + 'undefined: "#{y}", "${y}"\n'
        + '</p>\n'
      );
      var script1 = (
        ''
        + 'var _buf = \'\';  _buf += \'<p>\\n\\\n'
        + 'null: "\' + toStr(x) + \'", "\' + escapeXml(x) + \'"\\n\\\n'
        + 'undefined: "\' + toStr(y) + \'", "\' + escapeXml(y) + \'"\\n\\\n'
        + '</p>\\n\';\n'
        + '_buf\n'
      );
      var script2 = (
        ''
        + 'var _buf = \'\';  _buf += \'<p>\\n\\\n'
        + 'null: "\' + (x) + \'", "\' + escapeXml(x) + \'"\\n\\\n'
        + 'undefined: "\' + (y) + \'", "\' + escapeXml(y) + \'"\\n\\\n'
        + '</p>\\n\';\n'
        + '_buf\n'
      );
      var context = { x: null, y: undefined };
      var output1 = (
        ''
        + '<p>\n'
        + 'null: "", ""\n'
        + 'undefined: "", ""\n'
        + '</p>\n'
      );
      var output2 = (
        ''
        + '<p>\n'
        + 'null: "null", ""\n'
        + 'undefined: "undefined", ""\n'
        + '</p>\n'
      );
      /// Tenjin.Template#convert()
      var fname = 'input.jshtml';
      this.writeFile(fname, input);
      var t1 = new Tenjin.Template();
      ok (t1.convert(input)).eq(script1);
      var t2 = new Tenjin.Template({emptystr:false});
      ok (t2.convert(input)).eq(script2);
      /// Tenjin.Template#render()
      ok (t1.render(context)).eq(output1);
      ok (t2.render(context)).eq(output2);
    });

  });


});


if (require.main === module) {
  oktest.main();
}
