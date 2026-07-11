#!/bin/bash 

# default values
target="icarus-memCtrl"
showWave="no"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--icarus) target="icarus-memCtrl"; shift ;;
        -v|--verilator) target="verilator-memCtrl" ;;
        -w|--wave) showWave="yes" ;;
        *) echo "Possible values are -i (for icarus, default) or -v (for verilator) and optionally -w (for waveviewer). Your parameter \"$1\" is unknown."; exit 1 ;;
    esac
    shift
done

if [[ "$target" == "icarus-memCtrl" ]]; then
  make icarus-memCtrl
  sim/icarus-memCtrl
fi

if [[ "$target" == "verilator-memCtrl" ]]; then
  make verilator-memCtrl
  obj_dir/VmemCtrl_tb
fi

if [[ "$showWave" == "yes" ]]; then
  surfer sim/memCtrl_tb.vcd
  # gtkwave sim/memCtrl_tb.vcd
fi
