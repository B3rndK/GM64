#!/bin/bash 
# use ./run or ./run_sv
if [ $# -gt 1 ] || [ "$1" == "--help" ]; then
  echo "Usage: ./run.sh (yosys) or ./run.sh _sv (yosys_slang)"
  exit -1
fi
echo "Make in progress... Hint: Add _sv for SystemVerilog"
make all$1
