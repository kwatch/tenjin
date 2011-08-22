
///
/// $Release: $
/// $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
/// $License: MIT License $
///
"use strict";

var fs     = require("fs");
var util   = require("util");
var assert = require("assert");
var tenjin = require("tenjin");
var cmdopt = require("cmdopt");
var Benchmarker = require("./benchmarker").Benchmarker;

var $loop = 10000;
var $cycle = 1;
var $debug = false;
var $template_filename = 'bench_tenjin.jshtml';
var $context;
var $context_filename = 'bench_context.json';
var $flag_print = false;


function println(str) {
  process.stdout.write(str);
  process.stdout.write("\n");
}

var expecteds = {};

function verify(name, out) {
  if ($flag_print) {
    fs.writeFileSync('output.tenjin', out);
  }
  if (! expecteds[name]) {
    var fpath = "expected/" + name + ".expected";
    expecteds[name] = fs.readFileSync(fpath, "utf-8");
  }
  assert.equal(out, expecteds[name]);
};

if ($debug) {
  verify = function(name, out) { return; };
}

function _debug(expr, value) {
  if ($debug) {
    //console.log("\x1b[0;31m*** debug: " + expr + "=" + util.inspect(value) + "\x1b[0m");
    process.stderr.write("\x1b[0;31m*** debug: " + expr + "=" + util.inspect(value) + "\x1b[0m\n");
  }
}


///
/// register benchmark tasks
///

var $bm = new Benchmarker($loop);


$bm.emptyTask(function(loop) {
  var output, template_filename = $template_filename, context = $context;
  while (loop--) {
    var x = 0;
  }
});


$bm.task('tenjin (reuse:yes, cache:yes)', function(loop) {
  var output, template_filename = $template_filename, context = $context;
  var engine = new tenjin.Engine({cache:true});
  while (loop--) {
    output = engine.render(template_filename, context);
  }
  verify('tenjin', output);
});


$bm.task('tenjin (reuse:no, cache:yes)', function(loop) {
  var output, template_filename = $template_filename, context = $context;
  while (loop--) {
    var engine = new tenjin.Engine({cache:true});
    output = engine.render(template_filename, context);
  }
  verify('tenjin', output);
});


$bm.task('tenjin (reuse:no, cache:no)', function(loop) {
  var output, template_filename = $template_filename, context = $context;
  while (loop--) {
    var engine = new tenjin.Engine({cache:false});
    output = engine.render(template_filename, context);
  }
  verify('tenjin', output);
});


///
/// main application
///

function MainApp() {
};

(function(def) {

  def.run = function main(args) {
    var parser = this._commandOptionParser();
    if (! args) args = process.argv.slice(2);
    var opts = parser.parse(args);
    if (opts.debug) $debug = true;
    _debug('opts', opts);
    //
    if (opts.help) {
      println('Usage: node bennch.js [options]');
      println(parser.helpMessage());
      return;
    }
    if (opts.loop)  $loop = parseInt(opts.loop, 10);
    if (opts.cycle) $cycle = parseInt(opts.cycle, 10);
    if (opts.print) $flag_print = true;
    if (args) this._filterTasks(args, $bm._tasks);
    //
    $context = this._loadContextData();
    _debug('$context', $context);
    this._buildTemplateFile($template_filename);
    $bm.run($loop, $cycle);
  };

  def._commandOptionParser = function _commandOptionParser() {
    /// parse command-line options
    var parser = new cmdopt.Parser();
    parser.option('-h')         .name('help')  .desc('help');
    parser.option('-D')         .name('debug') .desc('debug');
    parser.option('-p')         .name('print') .desc('print output');
    parser.option('-n').arg('N').name('loop')  .desc('loop times (default ' + $loop + ')');
    parser.option('-c').arg('N').name('cycle') .desc('cycle to repeat (default ' + $cycle + ')');
    return parser;
  };

  def._filterTasks = function _filterTasks(args, tasks) {
    for (var i = 0, n = args.length; i < n; i++) {
      var pat = args[i];
      var j = tasks.length;
      while (--j >= 0) {
        var task = tasks[j];
        if (! task.title.match(pat)) {
          tasks.splice(j, 1);
        }
      }
    }
  };

  def._loadContextData = function _loadContextData(args) {
    var s = fs.readFileSync($context_filename);
    var context;
    eval("context = "+s);
    return context;
  };

  def._buildTemplateFile = function _buildTemplateFile(template_filename) {
    var decl   = "<?js //@ARGS items ?>\n";
    var header = fs.readFileSync("templates/_header.html");
    var body   = fs.readFileSync("templates/" + template_filename);
    var footer = fs.readFileSync("templates/_footer.html");
    fs.writeFileSync(template_filename, decl + header + body + footer);
  };

})(MainApp.prototype);


if (require.main === module) {
  new MainApp().run();
}
