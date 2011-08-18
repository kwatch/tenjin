if (typeof(require) == 'function' && typeof(require.resolve) == 'function') { // node.js
	var Shotenjin = require('../lib/shotenjin.js').Shotenjin;
	var oktest = require('oktest');
}
else {
	load('../lib/shotenjin.js');
	load('oktest.js');
}

var topic   = oktest.topic,
    spec    = oktest.spec,
    ok      = oktest.ok,
    NG      = oktest.NG,
    precond = oktest.precond;

topic('Shotenjin.Tenjin', function(t) {

	topic('#convert()', function(t) {

		spec("converts text into JS coode.", function() {
			var input = [
				'<table>',
				'</table>',
			    ''].join("\n");
			var expected = [
				'var _buf = \'\';  _buf += \'<table>\\n\\',
				'</table>\\n\';',
				'_buf',
			    ''].join("\n");
			var actual = (new Shotenjin.Template()).convert(input);
			ok (actual).eq(expected);
		});

		spec("converts embedded expressions into JS coode.", function() {
			var input = [
				'<td>#{i}</td>',
				'<td>${item}</td>',
			    ''].join("\n");
			var expected = [
				'var _buf = \'\';  _buf += \'<td>\' + toStr(i) + \'</td>\\n\\',
				'<td>\' + escapeXml(item) + \'</td>\\n\';',
				'_buf',
			    ''].join("\n");
			var actual = new Shotenjin.Template().convert(input);
			ok (actual).eq(expected);
		});

		spec("converts embedded statements into JS coode.", function() {
			var input = [
				'<table>',
				'  <?js for (var i = 0, n = items.length; i < n; ) { ?>',
				'  <?js   var item = items[i++]; ?>',
				'  <tr class="#{i % 2 == 1 ? \'odd\' : \'even\'}">',
				'    <td>#{i}</td>',
				'    <td>${item}</td>',
				'  </tr>',
				'  <?js } ?>',
				'</table>',
			    ''].join("\n");
			var expected = [
				'var _buf = \'\';  _buf += \'<table>\\n\';',
				'   for (var i = 0, n = items.length; i < n; ) {',
				'     var item = items[i++];',
				' _buf += \'  <tr class="\' + toStr(i % 2 == 1 ? \'odd\' : \'even\') + \'">\\n\\',
				'    <td>\' + toStr(i) + \'</td>\\n\\',
				'    <td>\' + escapeXml(item) + \'</td>\\n\\',
				'  </tr>\\n\';',
				'   }',
				' _buf += \'</table>\\n\';',
				'_buf',
			    ''].join("\n");
			var actual = new Shotenjin.Template().convert(input);
			ok (actual).eq(expected);
		});

		spec("converts //@ARGS into JS code.", function() {
			var input = [
				'<?js //@ARGS x, y ?>',
				'<p>x: #{x}</p>',
				'<p>y: #{y}</p>',
				''].join("\n");
			var expected = [
				'var _buf = \'\';   var x=_context.x; var y=_context.y;',
				' _buf += \'<p>x: \' + toStr(x) + \'</p>\\n\\',
				'<p>y: \' + toStr(y) + \'</p>\\n\';',
				'_buf',
				''].join("\n");
			var actual = new Shotenjin.Template().convert(input);
			ok (actual).eq(expected);
		});

		spec("converts only first appeared //@ARGS.", function() {
			var input = [
				'<?js //@ARGS x, y ?>',
				'<?js //@ARGS z ?>',
				'<p>x: #{x}</p>',
				'<p>y: #{y}</p>',
				''].join("\n");
			var expected = [
				'var _buf = \'\';   var x=_context.x; var y=_context.y;',
				' //@ARGS z',
				' _buf += \'<p>x: \' + toStr(x) + \'</p>\\n\\',
				'<p>y: \' + toStr(y) + \'</p>\\n\';',
				'_buf',
				''].join("\n");
			var actual = new Shotenjin.Template().convert(input);
			ok (actual).eq(expected);
		});

	});

	topic('#render()', function(t) {

		spec("renders template with context data.", function() {
			var input = [
				'<table>',
				'  <?js for (var i = 0, n = items.length; i < n; ) { ?>',
				'  <?js   var item = items[i++]; ?>',
				'  <tr class="#{i % 2 == 1 ? \'odd\' : \'even\'}">',
				'    <td>#{i}</td>',
				'    <td>${item}</td>',
				'  </tr>',
				'  <?js } ?>',
				'</table>',
				''].join("\n");
			var expected = [
				'<table>',
				'  <tr class="odd">',
				'    <td>1</td>',
				'    <td>A&amp;A</td>',
				'  </tr>',
				'  <tr class="even">',
				'    <td>2</td>',
				'    <td>&lt;BBB&gt;</td>',
				'  </tr>',
				'  <tr class="odd">',
				'    <td>3</td>',
				'    <td>&quot;CCC&quot;</td>',
				'  </tr>',
				'</table>',
				''].join("\n");
			var context = {items: ['A&A', '<BBB>', '"CCC"']};
			var actual = new Shotenjin.Template(input).render(context);
			ok (actual).eq(expected);
		});

		spec("renders template with arguments.", function() {
			var input = [
				'<?js //@ARGS x, y ?>',
				'<?js //@ARGS z ?>',
				'<p>x: #{x}</p>',
				'<p>y: #{y}</p>',
				''].join("\n");
			var expected = [
				'<p>x: Haruhi</p>',
				'<p>y: Sasaki</p>',
				''].join("\n");
			var context = {x: 'Haruhi', y: 'Sasaki'};
			var actual = new Shotenjin.Template(input).render(context);
			ok (actual).eq(expected);
		});

		spec("throws error if undeclared variable appeared.", function() {
			var input = [
				'<?js //@ARGS x, y ?>',
				'<?js //@ARGS z ?>',
				'<p>x: #{x}</p>',
				'<p>y: #{y}</p>',
				'<p>y: #{z}</p>',
				''].join("\n");
			var expected = [
				'<p>x: Haruhi</p>',
				'<p>y: Sasaki</p>',
				''].join("\n");
			var t = new Shotenjin.Template(input);
			var context = {x: 'Haruhi', y: 'Sasaki', 'z': 'John'};
			var fn = function() { t.render(context); };
			ok (fn).throws(ReferenceError, 'z is not defined');
		});

	});

});


topic('Shotenjin', function(t) {

	topic('.render()', function(t) {

		spec("renders template string with context data.", function() {
			var input = [
				'<?js //@ARGS items ?>',
				'<ul>',
				'  <?js for (var i = 0, item; item = items[i++]; ) { ?>',
				'  <li>${item}</li>',
				'  <?js } ?>',
				'</ul>',
				''].join("\n");
			var expected = [
				'<ul>',
				'  <li>&lt;Haruhi&gt;</li>',
				'  <li>Sasaki&amp;Kyon</li>',
				'</ul>',
				''].join("\n");
			var context = { items: ['<Haruhi>', 'Sasaki&Kyon'] };
			var output = Shotenjin.render(input, context);
			ok (output).eq(expected);
		});

	});

});


if (typeof(require) == 'function' && typeof(require.resolve) == 'function') { // node.js
	if (require.main === module) {
		oktest.main();
	}
}
else {
	oktest.main();
}
