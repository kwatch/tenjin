load('../lib/shotenjin.js');
load('oktest.js');

var target = Oktest.target;
var ok = Oktest.ok;

target('Shotenjin.Tenjin', function(t) {

	target('#convert()', function(t) {

		t.spec("converts text into JS coode.", function(s) {
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

		t.spec("converts embedded expressions into JS coode.", function(s) {
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

		t.spec("converts embedded statements into JS coode.", function(s) {
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

		t.spec("converts //@ARGS into JS code.", function(s) {
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

		t.spec("converts only first appeared //@ARGS.", function(s) {
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

	target('#render()', function(t) {

		t.spec("renders template with context data.", function(s) {
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

		t.spec("renders template with arguments.", function(s) {
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

		t.spec("throws error if undeclared variable appeared.", function(s) {
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
			ok (fn).throws();
		});

	});

});

Oktest.run_all();
