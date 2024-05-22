#!/bin/bash
#get p from command line argument
p=$3
#get b from command line argument
b=$2
#get n from command line argument
n=$1

if [ $b -eq 32 ] && [ $n -eq 3 ]; then
    CUDA_VISIBLE_DEVICES=0 ./piranha32_3 -p $p -c files/samples/benchmark_conv.json
elif [ $b -eq 64 ] && [ $n -eq 3 ]; then
    CUDA_VISIBLE_DEVICES=0 ./piranha64_3 -p $p -c files/samples/benchmark_conv.json
elif [ $b -eq 32 ] && [ $n -eq 4 ]; then
    CUDA_VISIBLE_DEVICES=0 ./piranha32_4 -p $p -c files/samples/benchmark_conv.json
elif [ $b -eq 64 ] && [ $n -eq 4 ]; then
    CUDA_VISIBLE_DEVICES=0 ./piranha64_4 -p $p -c files/samples/benchmark_conv.json
fi
