/*
 * $Rev$
 * $Release: 0.0.0 $
 * $Copyright$
 * License:  MIT License
 */

/**
 *  namespace
 */

var Shotenjin = {

	_escape_table: { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' },

	_escape_func: function(m) { return Shotenjin._escape_table[m] },

	escapeXml: function(s) {
		if (s === null || s === undefined) return '';
		if (typeof(s) != 'string') return s;
		return s.replace(/[&<>"]/g, Shotenjin._escape_func); //"
	},

	strip: function(s) {
		if (! s) return s;
		//return s.replace(/^\s+|\s+$/g, '');
		return s.replace(/^\s+/, '').replace(/\s+$/, '');
	},

	// ex. {x: 10, y: 'foo'}
	//       => "var x = _context['x'];\nvar y = _conntext['y'];\n"
	_setlocalvarscode: function(obj) {
		var buf = [];
		for (var p in obj) {
			buf.push("var ", p, " = _context['", p, "'];\n");
		}
		return buf.join('');
	},
	
	_end: undefined  // dummy property to escape strict warning (not legal in ECMA-262)
};
delete(Shotenjin._end);

var escapeXml = Shotenjin.escapeXml;


/**
 *  Template class
 */

Shotenjin.Template = function(properties) {
	if (properties) {
		var p = properties;
		if (p['escaefunc']) this.escapefunc = p['escapefunc'];
	}
};

Shotenjin.Template.prototype = {

	escapefunc: 'escapeXml',

	script: null,

	preamble: "var _buf = '', _V; ",
	postamble: "_buf\n",

	convert: function(input) {
		return this.script = this.preamble + this.parseStatements(input) + this.postamble;
	},

	parseStatements: function(input) {
		var sb = '';
		var regexp = /(^[ \t]*)?<\?js(\s(?:.|\n)*?) ?\?>([ \t]*\r?\n)?/mg;
		var pos = 0;
		var m;
		var ended_with_nl = true;
		var remained = null;
		while ((m = regexp.exec(input)) != null) {
			var lspace = m[1], stmt = m[2], rspace = m[3];
			var is_bol = lspace || ended_with_nl;
			var ended_with_nl = !! rspace;
			var text = input.substring(pos, m.index);
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
			sb += stmt;
		}
		var rest = pos == 0 ? input : input.substring(pos);
		sb += this.parseExpressions(rest);
		return sb;
	},

	parseExpressions: function(input) {
		if (! input) return;
		var sb = " _buf += ";
		var regexp = /([$#])\{(.*?)\}/g;
		var pos = 0;
		var m;
		while ((m = regexp.exec(input)) != null) {
			var text = input.substring(pos, m.index);
			var s = m[0];
			pos = m.index + s.length;
			var indicator = m[1];
			var expr = m[2];
			if (indicator == "$") {
				sb += "'" + this.escapeText(text) + "' + " + this.escapefunc + "(" + expr + ") + ";
			}
			else {
				sb += "'" + this.escapeText(text) + "' + ((_V = (" + expr + ")) === null || _V === undefined ? '' : _V) + ";
			}
		}
		var rest = pos == 0 ? input : input.substring(pos);
		var newline = input.charAt(input.length-1) == "\n" ? "\n" : "";
		sb += "'" + this.escapeText(rest, true) + "';" + newline;
		return sb;
	},

	escapeText: function(text, eol) {
		if (! text) return "";
		text = text.replace(/[\'\\]/g, '\\$&').replace(/\n/g, '\\n\\\n');
		if (eol) text = text.replace(/\\n\\\n$/, "\\n");
		return text;
	},

	render: function(_context) {
		if (_context) {
			eval(Shotenjin._setlocalvarscode(_context));
		}
		else {
			_context = {};
		}
		return eval(this.script);
	},

	_end: undefined  // dummy property to escape strict warning (not legal in ECMA-262)
};
delete(Shotenjin.Template.prototype._end);


/*
 *  convenient function
 */
Shotenjin.render = function(template_str, context) {
	var template = new Shotenjin.Template();
	template.convert(template_str);
	var output = template.render(context);
	return output;
};
