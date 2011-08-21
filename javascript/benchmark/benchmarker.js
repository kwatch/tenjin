// -*- coding: utf-8 -*-

///
/// $Release: $
/// $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
/// $License: MIT License $
///


var os = require("os");

function _repeat(str, n) {
  var buf = "";
  var i = n / 2 | 0;
  var s = str + str;
  while (i-- > 0) buf += s;
  if (n % 2 == 1) buf += str;
  return buf;
}

function _print(str, width) {
  if (width) {
    var space = _repeat(" ", width - str.length);
    process.stdout.write("" + str + space);
  }
  else {
    process.stdout.write("" + str);
  }
}

function _println(str, width) {
  _print(str, width);
  process.stdout.write("\n");
}

function _formatInt(integer) {
  var x = integer;
  var arr = [];
  while (x >= 1000) {
    var mod = x % 1000;
    if      (mod <  10) arr.push('00' + mod);
    else if (mod < 100) arr.push('0' + mod);
    else                arr.push(mod);
    x = (x - mod) / 1000;
  }
  arr.push(x);
  return arr.reverse().join(',');
}

var Benchmarker = function Benchmarker(loop, cycle) {
  if (loop)  this.loop = loop;
  if (cycle) this.cycle = cycle;
  this._tasks = [];
  this._empty_task = null;
};


(function(def) {

  def.loop = 1000*1000,

  def.cycle = 1;

  def.width = 40;

  def.task = function task(title, body) {
    this._tasks.push({title: title, body: body});
  };

  def._emptyTask = null;

  def.emptyTask = function emptyTask(body) {
    this._emptyTask = {title: "(Empty)", body: body};
  };

  def._getTasks = function() {
    var tasks = this._tasks;
    if (this._emptyTask) {
      tasks = [this._emptyTask].concat(tasks);
    }
    return tasks;
  };

  def._printEnvironment = function _printEnvironment(width) {
    if (! width) width = 30;
    _print("# process.version:",    width); _println(process.version);
    _print("# process.platform:",   width); _println(process.platform);
    _print("# process.arch:",       width); _println(process.arch || "-");
    _print("# os.type():",          width); _println(os.type());
    var cpu = os.cpus()[0];
    _print("# os.cpus()[0].model:", width); _println(cpu.model);
    _print("# os.cpus()[0].speed:", width); _println(cpu.speed);
    _print("# os.totalmemo():",     width); _println(os.totalmem());
    _println("");
  };


  def.run = function run(loop, cycle) {
    if (! loop)  loop  = this.loop;
    if (! cycle) cycle = this.cycle;
    var tasks = this._getTasks();
    this._printEnvironment();
    process.stdout.write("# loop = " + loop + "\n");
    for (var i = 1; i <= cycle; i++) {
      process.stdout.write("\n");
      this._run_tasks(loop, i, tasks);
    }
  };


  def._run_tasks = function _run_tasks(loop, cycle, tasks) {
    var width = this.width;
    _print("# cycle=" + cycle, width);
    process.stdout.write("real      actual    memory(byte)\n");
    var emptyTime = 0;
    for (var i = 0, n = tasks.length; i < n; i++) {
      var task = tasks[i];
      _print(task.title, width);
      var free_mem = os.freemem();
      var start = new Date();
      task.body(loop);
      var stop = new Date();
      var mem = free_mem - os.freemem();
      var msec = (+ stop) - (+ start);
      var actual = msec - emptyTime;
      var isEmptyTask = this._emptyTask && i == 0;
      if (isEmptyTask) emptyTime = msec;
      task.result = {real: msec, actual: actual};
      _print("" + (msec / 1000.0), 10);
      _print("" + (actual / 1000.0), 10);
      _print("" + _formatInt(mem), 10);
      process.stdout.write("\n");
    }
  };

})(Benchmarker.prototype);


exports.Benchmarker = Benchmarker;
