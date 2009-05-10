#!/bin/sh


# user_layout1 - layout & evaluate_with_layout
# user_layout2 - layout & _evaluate_with_layout
# user_layout3 - expand()
# user_layout4 - include()

script="user_bench.py"
datafile="user_context.py"
#ntime=100

export PYTHONPATH='../../lib'

if [ "$1" == "-p" ]; then
    option="-f $datafile -p"
    python $script $option -l user_layout1.pyhtml user_list.pyhtml > test1.output
    #python $script $option -l user_layout2.pyhtml user_list.pyhtml > test2.output
    python $script $option    user_layout3.pyhtml                  > test3.output
    python $script $option    user_layout4.pyhtml                  > test4.output
else
    [ -n "$1" ] && ntime=$1 || ntime=100
    echo "*** ntime=$ntime"
    option="-f $datafile -n $ntime"
    python $script $option -l user_layout1.pyhtml user_list.pyhtml
    #python $script $option -l user_layout2.pyhtml user_list.pyhtml
    python $script $option    user_layout3.pyhtml
    python $script $option    user_layout4.pyhtml
fi
