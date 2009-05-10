for i in 1 2 3 4 5 6 7 8 9 0; do
        echo "*** i=$i"
        ruby bench.rb -qn 10000 2>&1 | tee bench.log$i
done
