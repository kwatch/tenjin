#!/bin/sh

script="user_bench.rb"
datafile="user_context.rb"
ntime=100

export RUBYLIB='../../lib'

if [ "$1" == "-p" ]; then
    option="-f $datafile -p"
    ruby $script $option -l user_layout1.rbhtml user_list.rbhtml > test1.output
    #ruby $script $option -l user_layout2.rbhtml user_list.rbhtml > test2.output
    ruby $script $option    user_layout3.rbhtml                  > test3.output
    ruby $script $option    user_layout4.rbhtml                  > test4.output
    ruby $script $option    user_layout5.rbhtml                  > test5.output
else
    [ -n "$1" ] && ntime=$1 || ntime=100
    echo "*** ntime=$ntime"
    option="-f $datafile -n $ntime"
    ruby $script $option -l user_layout1.rbhtml user_list.rbhtml
    #ruby $script $option -l user_layout2.rbhtml user_list.rbhtml
    ruby $script $option    user_layout3.rbhtml
    ruby $script $option    user_layout4.rbhtml
    ruby $script $option    user_layout5.rbhtml
fi
