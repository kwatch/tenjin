/*
 * $Release: $
 * $Copyright: copyright(c) 2007-2011 kuwata-lab.com all rights reserved. $
 * $License: MIT License $
 */

/**
 * client-side template engine
 *
 * usage:
 *    <script src="/js/jquery.js"></script>
 *    <script src="/js/shotenjin.js"></script>
 *
 *    <div id="template1" style="display:none">
 *         <ul>
 *         <?js for (var i = 0, n = items.length; i < n; i++) { ?>
 *           <li>${i}: ${items[i]}</li>
 *         <?js } ?>
 *         </ul>
 *    </div>
 *    <div id="placeholder1"></div>
 *
 *    <script>
 *      var context = {
 *        items: ["A","B","C"]
 *      };
 *      var html = $('#template1').renderWith(context, true);          // return html string
 *      $('#template1').renderWith(context, '#placeholder1');           // replace '#placeholder1' content by html
 *      $('#template1').renderWith(context).appendTo('#placeholder1');  // append html into into #placeholder1
 *    </script>
 *
 */


/**
 *  namespace
 */

var Shotenjin = {

  _escape_table: { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' },

  _escape_func: function(m) { return Shotenjin._escape_table[m]; },

  escapeHtml: function(s) {
    if (s == null) return '';
    if (typeof(s) != 'string') return s;
    return s.replace(/[&<>"]/g, Shotenjin._escape_func); //"
  },

  toStr: function(s) {
    if (s == null) return '';
    return s;
  },

  strip: function(s) {
    if (! s) return s;
    //return s.replace(/^\s+|\s+$/g, '');
    return s.replace(/^\s+/, '').replace(/\s+$/, '');
  },

  // ex. {x: 10, y: 'foo'}
  //       => "var x = _context['x'];\nvar y = _conntext['y'];\n"
  _setlocalvarscode: function(obj) {
    var sb = "", p;
    for (p in obj) sb += "var " + p + " = _context['" + p + "'];\n";
    return sb;
  }

};

var escapeHtml = Shotenjin.escapeHtml;
var toStr      = Shotenjin.toStr;


/**
 *  Template class
 */

Shotenjin.Template = function(input, properties) {
  if (typeof(input) === 'object' && ! properties) {
    input = null;
    properties = input;
  }
  if (properties) {
    if (properties['tostrfunc'])  this.escapefunc = properties['tostrfunc'];
    if (properties['escapefunc']) this.escapefunc = properties['escapefunc'];
  }
  if (input) this.convert(input);
};

Shotenjin.Template.prototype = {

  tostrfunc: 'toStr',
  escapefunc: 'escapeHtml',

  script: null,

  preamble: "var _buf = ''; ",
  postamble: "_buf\n",

  convert: function(input) {
    this.args = null;
    input = input.replace(/<!--\?js/g, '<?js').replace(/\?-->/g, '?>');  // for Chrome
    return this.script = this.preamble + this.parseStatements(input) + this.postamble;
  },

  parseStatements: function(input) {
    var sb = '',
        pos = 0,
        regexp = /(^[ \t]*)?<\?js(\s(?:.|\n)*?) ?\?>([ \t]*\r?\n)?/mg,
        ended_with_nl = true,
        remained = null,
        m, lspace, stmt, rspace, is_bol, text, rest;
    while ((m = regexp.exec(input)) != null) {
      lspace = m[1]; stmt = m[2]; rspace = m[3];
      is_bol = lspace || ended_with_nl;
      text = input.substring(pos, m.index);
      pos = m.index + m[0].length;
      if (remained) {
        text = remained + text;
        remained = null;
      }
      if (is_bol && rspace) {
        stmt = (lspace || '') + stmt + rspace;
      }
      else {
        if (lspace) text += lspace;
        remained = rspace;
      }
      if (text) sb += this.parseExpressions(text);
      stmt = this._parseArgs(stmt);
      sb += stmt;
    }
    rest = pos == 0 ? input : input.substring(pos);
    sb += this.parseExpressions(rest);
    return sb;
  },

  args: null,

  _parseArgs: function(stmt) {
    var m, sb, arr, args, i, n, arg;
    if (this.args !== null) return stmt;
    m = stmt.match(/^(\s*)\/\/@ARGS:?[ \t]+(.*?)(\r?\n)?$/);
    if (! m) return stmt;
    sb = m[1];
    arr = m[2].split(/,/);
    args = [];
    for (i = 0, n = arr.length; i < n; i++) {
      arg = arr[i].replace(/^\s+/, '').replace(/\s+$/, '');
      args.push(arg);
      sb += " var " + arg + "=_context." + arg + ";";
    }
    sb += m[3];
    this.args = args;
    return sb;
  },

  parseExpressions: function(input) {
    var sb, regexp, pos, m, text, s, indicator, expr, funcname, rest, is_newline;
    if (! input) return '';
    sb = " _buf += ";
    regexp = /([$#])\{(.*?)\}/g;
    pos = 0;
    while ((m = regexp.exec(input)) != null) {
      text = input.substring(pos, m.index);
      s = m[0];
      pos = m.index + s.length;
      indicator = m[1];
      expr = m[2];
      funcname = indicator == "$" ? this.escapefunc : this.tostrfunc;
      sb += "'" + this._escapeText(text) + "' + " + funcname + "(" + expr + ") + ";
    }
    rest = pos == 0 ? input : input.substring(pos);
    is_newline = input.charAt(input.length-1) == "\n";
    sb += "'" + this._escapeText(rest, true) + (is_newline ? "';\n" : "';");
    return sb;
  },

  _escapeText: function(text, eol) {
    if (! text) return "";
    text = text.replace(/[\'\\]/g, '\\$&').replace(/\n/g, '\\n\\\n');
    if (eol) text = text.replace(/\\n\\\n$/, "\\n");
    return text;
  },

  render: function(_context) {
    if (! _context) {
      _context = {};
    }
    else if (this.args === null) {
      eval(Shotenjin._setlocalvarscode(_context));
    }
    return eval(this.script);
  }

};


/*
 *  convenient function
 */
Shotenjin.render = function(template_str, context) {
  var template, output;
  template = new Shotenjin.Template();
  template.convert(template_str);
  output = template.render(context);
  return output;
};


/*
 *  jQuery plugin
 */
if (typeof(jQuery) !== "undefined") {
  jQuery.fn.extend({
    renderWith: function renderWith(context, option) {
      var tmpl, html;
      tmpl = this.html();
      tmpl = tmpl.replace(/^\s*\<\!\-\-/, '').replace(/\-\-\>\s*$/, '');
      html = Shotenjin.render(tmpl, context);
      if (option === true) return html;
      if (option) return jQuery(option).html(html);
      return jQuery(html);
    }
  });
}


/*
 *  for node.js
 */
if (typeof(exports) == 'object') {  // node.js
  //(function() {
  //  for (var k in Shotenjin) {
  //    exports[k] = Shotenjin[k];
  //  }
  //})();
  exports.Shotenjin = Shotenjin;
}
