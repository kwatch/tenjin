///
/// $Release: $
/// $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
/// $License: MIT License $
///


var fs = require("fs");
var oktest = require('oktest');


var provider = {
  jshtml: function() {
    return "_test_" + ('' + Math.random()).substring(2, 6) + '.html';
  },
  cleaner: function() {
    return new oktest.fixture.Cleaner();
  }
};

var releaser = {
  jshtml: function(value) {
    var fname, stat;
    fname = value;
    stat = oktest.util.fstat(fname);
    if (stat && stat.isFile()) fs.unlinkSync(fname);
    fname = value + '.cache';
    stat = oktest.util.fstat(fname);
    if (stat && stat.isFile()) fs.unlinkSync(fname);
  },
  cleaner: function(value) {
    var cleaner_obj = value;
    cleaner_obj.clean();
  }
};

oktest.fixture.manager = {
  provide: function provide(name) {
    return provider[name]();
  },
  release: function release(name, value) {
    if (releaser[name]) releaser[name](value);
  }
};


//function dummyFiles(arg, func) {
//  var fnames = [];
//  try {
//    if (typeof(arg) == "object") {
//      for (var fname in arg) {
//        var content = arg[fname];
//        fnames.push(fname);
//        fs.writeFileSync(fname, content, 'utf8');
//      }
//    }
//  }
//  finally {
//    for (var i = 0, n = fnames.length; i < n; i++) {
//      if (Tenjin.isFile(fnames[i])) {
//        fs.unlinkSync(fnames[i]);
//      }
//    }
//  }
//}
