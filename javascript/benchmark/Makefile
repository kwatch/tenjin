JS = js
#JS = java -jar js.jar
N = 1000
OPT = 
#OPT = -p

bench:	bench_tenjin.jshtml
	time $(JS) bench.js -n $(N) $(OPT)
	time $(JS) bench.js -n $(N) $(OPT) tenjin-cached
	time $(JS) bench.js -n $(N) $(OPT) tenjin-nocache
	time $(JS) bench.js -n $(N) $(OPT) tenjin-reuse

bench_tenjin.jshtml:
	cat templates/_header.html templates/$@ templates/_footer.html > $@


template: bench_tenjin.jshtml


clean:
	rm -f bench_tenjin.jshtml*