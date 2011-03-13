load('../lib/shotenjin.js');
load('oktest.js');

var target = Oktest.target;
var ok = Oktest.ok;

target('Shotenjin.Tenjin', function(t) {

	target('#convert()', function(t) {

		t.spec("converts text into JS coode.", function(s) {
			var input = [
				'<table>\n',
				'</table>\n',
			].join('');
			var expected = [
				'var _buf = [];  _buf.push(\'<table>\\n\\\n',
				'</table>\\n\\\n',
				'\');\n',
				'_buf.join(\'\')\n',
			].join('');
			var actual = new Shotenjin.Template().convert(input);
			ok (actual).eq(expected);
		});

		t.spec("converts expression to JS coode.", function(s) {
			var input = [
				'<td>#{i}</td>\n',
				'<td>${item}</td>\n',
			].join('');
			var expected = [
				'var _buf = [];  _buf.push(\'<td>\', i, \'</td>\\n\\\n',
				'<td>\', escapeXml(item), \'</td>\\n\\\n',
				'\');\n',
				'_buf.join(\'\')\n',
			].join('');
			var actual = new Shotenjin.Template().convert(input);
			ok (actual).eq(expected);
		});

		t.spec("converts statements into JS coode.", function(s) {
			var input = [
				'<table>\n',
				'  <?js for (var i = 0, n = items.length; i < n; ) { ?>\n',
				'  <?js   var item = items[i++]; ?>\n',
				'  <tr class="#{i % 2 == 1 ? \'odd\' : \'even\'}">\n',
				'    <td>#{[i].join()}</td>\n',
				'    <td>${item}</td>\n',
				'  </tr>\n',
				'  <?js } ?>\n',
				'</table>\n',
			].join('');
			var expected = [
				'var _buf = [];  _buf.push(\'<table>\\n\\\n',
				'  \'); for (var i = 0, n = items.length; i < n; ) { _buf.push(\'\\n\\\n',
				'  \');   var item = items[i++]; _buf.push(\'\\n\\\n',
				'  <tr class="\', i % 2 == 1 ? \'odd\' : \'even\', \'">\\n\\\n',
				'    <td>\', [i].join(), \'</td>\\n\\\n',
				'    <td>\', escapeXml(item), \'</td>\\n\\\n',
				'  </tr>\\n\\\n',
				'  \'); } _buf.push(\'\\n\\\n',
				'</table>\\n\\\n',
				'\');\n',
				'_buf.join(\'\')\n',
			].join('');
			var actual = new Shotenjin.Template().convert(input);
			ok (actual).eq(expected);
		});

	});

});

Oktest.run_all();
