
load('../lib/tenjin.js');

function main(arguments) {

	/// default values
	//var testnames = ['tenjin-nocache', 'tenjin-cached', 'tenjin-reuse'];
	var template_filename = 'bench_tenjin.jshtml';
	var ntimes = 1000;
	var flag_help = false;
	var flag_debug = false;
	var flag_print = false;
	
	/// command-line options
	for (var i = 0, n = arguments.length; i < n; i++) {
		var argstr = arguments[i];
		if (argstr.charAt(0) != '-')
			break;
		if (false)  { }
		else if (argstr == '-h') { flag_help = true; }
		else if (argstr == '-D') { flag_debug = true; }
		else if (argstr == '-p') { flag_print = true; }
		else if (argstr == '-n') {
			i++;
			if (i >= n) throw "-n: argument required.";
			ntimes = parseInt(arguments[i]);
		}
		else {
			throw ""+argstr+": unknown option.";
		}
	}
	
	var testnames = arguments.slice(i);
	if (flag_debug) {
		print("*** debug: ntimes="+ntimes);
		print("*** debug: typeof(ntimes)="+typeof(ntimes));
		print("*** debug: testnames="+testnames);
	}
	


	/// help
	if (flag_help) {
		print("js bench.js [-h] [-p] [-n N] testname");
		print("  -h       :  help");
		print("  -p       :  print result");
		print("  -n N     :  repeat N times");
		return;
	}


	/// context data
	var s = Tenjin.readFile('bench_context.json');
	var context;
	eval("context = "+s);
	//print("*** debug: contet="+Tenjin.inspect(context));
	

	/// create template file
	//var header = Tenjin.readFile("templates/_header.html");
	//var body   = Tenjin.readFile("templates/" + template_filename);
	//var footer = Tenjin.readFile("templates/_footer.html");
	//Tenjin.writeFile(template_filename, header+body+footer);
	

	///// benchmark functions
	var bench_funcs = {};
	
	bench_funcs['tenjin-nocache'] = function(ntimes, context) {
		var output;
		for (var i = 0; i < ntimes; i++) {
			var engine = new Tenjin.Engine({cache:false});
			output = engine.render(template_filename, context);
		}
		return output;
	};
	
	bench_funcs['tenjin-cached'] = function(ntimes, context) {
		var output;
		for (var i = 0; i < ntimes; i++) {
			var engine = new Tenjin.Engine({cache:true});
			output = engine.render(template_filename, context);
		}
		return output;
	};
	
	bench_funcs['tenjin-reuse'] = function(ntimes, context) {
		var engine = new Tenjin.Engine({cache:true});
		var output;
		for (var i = 0; i < ntimes; i++) {
			output = engine.render(template_filename, context);
		}
		return output;
	};
	
	
	/// main loop
	for (var i = 0, n = testnames.length; i < n; i++) {
		var testname = testnames[i];
		if (flag_debug) print("*** testname: "+testname+", ntimes="+ntimes);
		var func = bench_funcs[testname] || null;
		if (! func) {
			throw ""+testname+": unknown testname.";
		}
		var output = func(ntimes, context);
		if (flag_print) Tenjin.writeFile("output." + testname, output);
	}

}

main(arguments);