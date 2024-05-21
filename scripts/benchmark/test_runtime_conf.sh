#!/bin/bash

helpFunction()
{
   echo "Script to test the runtime of single inferences for different configurations"
   echo -e "\t-p Party number or all for running locally"
   echo -e "\t-a IP address of player 0 (if ip matches player_id can be empty)"
   echo -e "\t-b IP address of player 1 (if ip matches player_id can be empty)"
   echo -e "\t-c IP address of player 2 (if ip matches player_id can be empty)"
   echo -e "\t-d IP address of player 3 (if ip matches player_id can be empty)"
   echo -e "\t-n Number of players"
   echo -e "\t-k Batch size"
   echo -e "\t-l Bitlength"
   echo -e "\t-f File or directory with files to test"
   echo -e "\t-r Number of iterations"
   echo -e "\t-h Help"

   exit 1 # Exit script after printing help
}

while getopts "p:a:b:c:d:n:k:l:f:r:" opt
do
   case "$opt" in
      p ) O_PARTY="$OPTARG" ;;
      a ) IP0="$OPTARG" ;;
      b ) IP1="$OPTARG" ;;
      c ) IP2="$OPTARG" ;;
      d ) IP3="$OPTARG" ;;
      n ) NUM_PLAYERS="$OPTARG" ;;
      k ) BATCH_SIZE="$OPTARG" ;;
      l ) BITLENGTH="$OPTARG" ;;
      f ) FILE="$OPTARG" ;;
      r ) NUM_ITERATIONS="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

O_BATCH_SIZE=1
if [ ! -z "$BATCH_SIZE" ]; then
    O_BATCH_SIZE="$BATCH_SIZE"
fi

O_PARTY="all"
if [ ! -z "$O_PARTY" ]; then
    O_PARTY="$O_PARTY"
fi

O_NUM_ITERATIONS=10
if [ ! -z "$NUM_ITERATIONS" ]; then
    O_NUM_ITERATIONS="$NUM_ITERATIONS"
fi

O_IP0="127.0.0.1"
O_IP1="127.0.0.1"
O_IP2="127.0.0.1"
O_IP3="127.0.0.1"

if [ ! -z "$IP0" ]; then
    O_IP0="$IP0"
fi

if [ ! -z "$IP1" ]; then
    O_IP1="$IP1"
fi

if [ ! -z "$IP2" ]; then
    O_IP2="$IP2"
fi

if [ ! -z "$IP3" ]; then
    O_IP3="$IP3"
fi

O_BITLENGTH=32
if [ ! -z "$BITLENGTH" ]; then
    O_BITLENGTH="$BITLENGTH"
fi

O_NUM_PLAYERS=3
if [ ! -z "$NUM_PLAYERS" ]; then
    O_NUM_PLAYERS="$NUM_PLAYERS"
fi

# If binary does not exist, then compile it
if [ "$O_NUM_PLAYERS" -eq "4" ]; then
    if [ ! -f "piranha$(BITLENGTH)_4PC" ]; then
        make -j PIRANHA_FLAGS="-DFLOAT_PRECISION=14 -D FOURPC" BITLENGTH=$BITLENGTH BINARY=piranha$(BITLENGTH)_4PC
    else
        if [ ! -f "piranha$(BITLENGTH)_3PC" ]; then
            make -j PIRANHA_FLAGS="-DFLOAT_PRECISION=14" BITLENGTH=$BITLENGTH BINARY=piranha$(BITLENGTH)_3PC
        fi
    fi
fi

declare -a functions=()

# If FILE is a directory, then loop over all files in the directory, otherwise just loop over file
if [ -d "$FILE" ]; then
    for f in $FILE/*; do
        if [ -f "$f" ]; then
            functions+=("$f")
        fi
    done
else
    functions+=("$FILE")
fi

# Update localhostconfig with the correct values
CONFIG_FILE="files/samples/benchmark.json"
sed -i "s/\"num_parties\": [0-9]\+,/\"num_parties\": $O_NUM_PLAYERS,/" $CONFIG_FILE
sed -i "s/\"party_ips\": \[.*\],/\"party_ips\": [\"$O_IP0\", \"$O_IP1\", \"$O_IP2\", \"$O_IP3\"],/" $CONFIG_FILE
sed -i "s/\"custom_batch_size_count\": [0-9]\+,/\"custom_batch_size_count\": $O_BATCH_SIZE,/" $CONFIG_FILE

for f in "${functions[@]}"; do
    for i in $(seq 1 $O_NUM_ITERATIONS); do
        echo "Running $f, batch size $O_BATCH_SIZE, Bitlength $O_BITLENGTH, iteration $i"
        if [ "$O_PARTY" == "all" ]; then
            for j in $(seq 0 $((O_NUM_PLAYERS-1))); do
                ./piranha$(BITLENGTH)_$(O_NUM_PLAYERS)PC -p $j -c $CONFIG_FILE &
            done
            wait
        else
        ./piranha$(BITLENGTH)_$(O_NUM_PLAYERS)PC -p $O_PARTY -c $CONFIG_FILE -f $f
        fi
    done
done

