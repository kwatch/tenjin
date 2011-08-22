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



topic('Tenjin.helper', function(t) {

  this.before = function(this_) {
    this_.cleaner = new oktest.fixture.Cleaner();
  };

  this.after = function(this_) {
    this_.cleaner.clean();
  };


  topic('toStr()', function(t) {

    spec("returns empty string when arg is null.", function() {
      ok (Tenjin.toStr(null)).is('');
      ok (Tenjin.toStr(null)).isString();
    });

    spec("returns empty string when arg is undefined.", function() {
      ok (Tenjin.toStr(undefined)).is('');
      ok (Tenjin.toStr(undefined)).isString();
    });

    spec("returns arg as it is when arg is not null nor undefined.", function() {
      ok (Tenjin.toStr('foo')).isString('foo');
      ok (Tenjin.toStr(123)).is(123);
      ok (Tenjin.toStr(0)).is(0);
      ok (Tenjin.toStr(true)).is(true);
      ok (Tenjin.toStr(false)).is(false);
    });

  });


  topic('escapeXml()', function(t) {

    spec("returns html escaped string.", function() {
      ok (Tenjin.escapeXml('& < > "')).eq('&amp; &lt; &gt; &quot;');
      //ok (Tenjin.escapeXml("'")).is('&039;');
      ok (Tenjin.escapeXml("'")).eq("'");
    });

    spec("returns argument as it is when html special chars are not included.", function() {
      ok (Tenjin.escapeXml(123)).is(123);
    });

  });


  topic('unescapeXml()', function(t) {

    spec("converts html escaped string into ordinal text string.", function() {
      ok (Tenjin.unescapeXml('&amp; &lt; &gt; &quot;')).eq('& < > "');
      //ok (Tenjin.escapeXml('&039;')).is("'");
      ok (Tenjin.unescapeXml("'")).is("'");
    });

    spec("returns empty string when arg is null or undefined.", function() {
      ok (Tenjin.unescapeXml(null)).is('');
      ok (Tenjin.unescapeXml(undefined)).is('');
    });

    spec("returns argument as it is when html special chars are not included.", function() {
      ok (Tenjin.unescapeXml(123)).is(123);
    });

  });


  topic("strip()", function() {

    spec("removes heading or tailing spaces.", function() {
      ok (Tenjin.strip(" foo ")).eq("foo");
      ok (Tenjin.strip("\t bar \t\r\n")).eq("bar");
    });

  });


  topic("merge", function() {

    spec("merge objects.", function() {
      var to = {a: 10};
      var from = {b: 20};
      Tenjin.merge(to, from);
      ok (to).deepEqual({a:10, b:20});
      ok (from).deepEqual({b:20});
    });

  });


  topic("merge", function() {

    spec("merge objects.", function() {
      var to   = {a: 10, b: 20};
      var from = {b: 30, c: 40};
      Tenjin.merge(to, from);
      ok (to).deepEqual({a:10, b:30, c:40});
      ok (from).deepEqual({b:30, c:40});
    });

  });


  topic("mergeIfExists()", function() {

    spec("merge objects with specified keys.", function() {
      var to   = {a: 10, b: 20};
      var from = {b: 30, c: 40};
      Tenjin.mergeIfExists(to, from, {'c':null});
      ok (to).deepEqual({a:10, b:20, c:40});
      ok (from).deepEqual({b:30, c:40});
    });

  });


  topic("quote()", function() {

    spec("quotes arg by single quotation.", function() {
      ok (Tenjin.quote("It's Good!")).eq("'It\\'s Good!'");
    });

  });


  topic("checked()", function() {

    spec("returns 'checked' attribute when arg is true-value.", function() {
      ok (Tenjin.checked(1==1)).eq(' checked="checked"');
    });

    spec("returns empty string when arg is false-value.", function() {
      ok (Tenjin.checked(1==0)).is('');
    });

  });


  topic("selected()", function() {

    spec("returns 'selected' attribute when arg is true-value.", function() {
      ok (Tenjin.selected(1==1)).eq(' selected="selected"');
    });

    spec("returns empty string when arg is false-value.", function() {
      ok (Tenjin.selected(1==0)).is('');
    });

  });


  topic("disabled()", function() {

    spec("returns 'disabled' attribute when arg is true-value.", function() {
      ok (Tenjin.disabled(1==1)).eq(' disabled="disabled"');
    });

    spec("returns empty string when arg is false-value.", function() {
      ok (Tenjin.disabled(1==0)).is('');
    });

  });


  topic("nl2br()", function() {

    spec("converts newline into <br> tag.", function() {
      ok (Tenjin.nl2br("foo\nbar\nbaz")).eq("foo<br />\nbar<br />\nbaz");
    });

  });


  topic("text2html()", function() {

    spec("converts newline into <br> tag.", function() {
      ok (Tenjin.nl2br("foo\nbar\nbaz")).eq("foo<br />\nbar<br />\nbaz");
    });

    spec("escapes html special characters.", function() {
      ok (Tenjin.text2html('& < > "')).eq("&amp; &lt; &gt; &quot;");
    });

  });


  topic("readFile()", function() {

    spec("returns content of file.", function() {
      var fname = "_test_4918.txt";
      var content = "SOS\n";
      fs.writeFileSync(fname, content);
      this.cleaner.add(fname);
      precond(fname).isFile();
      ok (Tenjin.readFile(fname)).eq(content);
    });

  });


  topic("writeFile()", function() {

    spec("writes content into file.", function() {
      var fname = "_test_3948.txt";
      var content = "Haruhi";
      fs.writeFileSync(fname, content);
      this.cleaner.add(fname);
      precond(fname).isFile();
      Tenjin.writeFile(fname, "Sasaki");
      ok (fs.readFileSync(fname)).eq("Sasaki");
    });

    spec("creats a new file if not exists.", function() {
      var fname = "_test_6641.txt";
      var content = "SOS\n";
      this.cleaner.add(fname);
      precond(fname).notExist();
      Tenjin.writeFile(fname, content);
      ok (fs.readFileSync(fname)).eq(content);
    });

  });


  topic("isFile()", function() {

    spec("returns true if file exists.", function() {
      ok (Tenjin.isFile(__filename)).is(true);
    });

    spec("returns false if file not exist.", function() {
      ok (Tenjin.isFile("__not_exist_file")).is(false);
    });

    spec("returns false if file is a directory.", function() {
      ok (Tenjin.isFile(".")).is(false);
    });

  });


  topic("isNewer()", function() {

    spec("returns true if 1st file is newer than 2nd file.", function() {
      var fname = "_test_4011.txt";
      Tenjin.writeFile(fname, "SOS");
      this.cleaner.add(fname);
      ok (Tenjin.isNewer(fname, __filename)).is(true);
    });

    spec("returns false if 1st file is older than 2nd file.", function() {
      var fname = "_test_4012.txt";
      Tenjin.writeFile(fname, "SOS");
      this.cleaner.add(fname);
      ok (Tenjin.isNewer(__filename, fname)).is(false);
    });

    spec("returns false if 1st and 2nd files have same timestamps.", function() {
      ok (Tenjin.isNewer(__filename, __filename)).is(false);
    });

  });


  topic("mime()", function() {

    spec("returns timestamp of file.", function() {
      var fname = "_test_6919.txt";
      fs.writeFileSync(fname, "SOS");
      var now = new Date();
      var tstamp = Tenjin.mtime(fname);
      ok (tstamp.constructor).is(Date);
      ok (String(tstamp)).eq(String(now));
    });

  });


  topic("mime()", function() {

    spec("returns timestamp of file.", function() {
      var fname = "_test_6919.txt";
      fs.writeFileSync(fname, "SOS");
      var now = new Date();
      var tstamp = Tenjin.mtime(fname);
      ok (tstamp.constructor).is(Date);
      ok (String(tstamp)).eq(String(now));
    });

  });



});


if (require.main === module) {
  oktest.main();
}
