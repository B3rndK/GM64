#!/bin/bash 
# use ./sim or ./sim_sv
#./sim.sh
if [ $# -gt 1 ] || [ "$1" == "--help" ]; then
  echo "Usage: ./sim.sh (icarus) or ./sim.sh _sv (verilator)"
  exit -1
fi
make vlog_sim$1.vvp
if [ $? -eq 0 ]; then
  if [ $# -eq 0 ]; then
    sim/vlog_sim.vvp  
    #gtkwave sim/gm64_tb.vcd
  else
    obj_dir/Vgm64_tb --trace-fst --assert
    # gtkwave sim/gm64_tb.fst
  fi
fi