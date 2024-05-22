#!/bin/bash
#get p from command line argument
p=$1
#get b from command line argument
b=$2
#get n from command line argument
n=$3

if [ $b -eq 32 && $n -eq 3 ]; then
    CUDA_VISIBLE_DEVICES=0 /bin/time -v ./piranha32_3 -p $1 -c files/samples/benchmark_conv.json elif [ $b -eq 64 && $n -eq 3]; then
    CUDA_VISIBLE_DEVICES=0 /bin/time -v ./piranha64_3 -p $1 -c files/samples/benchmark_conv.json elif [ $b -eq 32 && $n -eq 4]; then
    CUDA_VISIBLE_DEVICES=0 /bin/time -v ./piranha32_4 -p $1 -c files/samples/benchmark_conv.json elif [ $b -eq 64 && $n -eq 4]; then
    CUDA_VISIBLE_DEVICES=0 /bin/time -v ./piranha64_4 -p $1 -c files/samples/benchmark_conv.json
fi
