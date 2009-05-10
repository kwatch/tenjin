for i in 0 1 2 3 4 5 6 7 8 9 ; do
	echo "*** i=$i"
	python bench.py -qn 10000 2>&1 | tee bench.log$i
done
