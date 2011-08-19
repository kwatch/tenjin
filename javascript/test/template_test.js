///
/// $Release: $
/// $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
/// $License: MIT License $
///

require('./initialize');
var fs     = require('fs');

var oktest = require('oktest');
var topic = oktest.topic,
    spec  = oktest.spec,
    ok    = oktest.ok,
    NG    = oktest.NG,
    precond = oktest.precond;

var Tenjin = require('tenjin');



topic('Tenjin.Template', function(t) {

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

    spec("not use toStr() if 'emptystr' option is false.", function() {
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


});


if (require.main === module) {
  oktest.main();
}
