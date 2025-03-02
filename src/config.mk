
EXE =

## Source root
SRC=~/git/GM64

## toolchain
OSS=~/Applications/oss-cad-suite/bin
YOSYS = $(OSS)/yosys$(EXE)
#YOSYS = ~/GateMate/bin/yosys/yosys$(EXE)
PR    = ~/GateMate/bin/p_r/p_r$(EXE)
# OFL   = ~/git/openFPGALoader/build/openFPGALoader$(EXE)
OFL = $(OSS)/openFPGALoader$(EXE)
OFLFLAGS =-b olimex_gatemateevb

GTKW = /usr/bin/gtkwave
IVL_SVL = $(OSS)/verilator
IVL = iverilog
VVP = vvp
IVLFLAGS = -Winfloop -g2012 -gspecify -Ttyp -I ./ -I ./src -I ./src/src -I ../src/memCtrl/src -I ../src/clockGen/src -I ../src/visuMon/src ../src/VisuMon # -v #-delaborate
IVL_SVL_FLAGS= -binary --top gm64_tb --trace-fst --assert -I./reset/src -I./sketchpad/src -I./counter/src -I./clockGen/src/ -I./memCtrl/src/ -I./visuMon/src/ -I./ -I./src -I./src/src -I./visuMon/src -I./visuMon/syncGen/src -I./VIC6569/src
SV_INCLUDES = -IclockGen/src -IsyncGen/src -IVIC6569/src -Ireset/src -Icounter/src -ImemCtrl/src -Isketchpad/src -IvisuMon/src

## simulation libraries
CELLS_SYNTH = ~/GateMate/bin/yosys/share/gatemate/cells_sim.v
CELLS_SYNTH_SV = /home/bernd/GateMate/bin/yosys/share/gatemate/cells_bb.v #/home/bernd/GateMate/bin/yosys/share/gatemate/cells_sim.v 
CELLS_SIM_SV =	/home/bernd/GateMate/bin/yosys/share/gatemate/cells_sim.v 
CELLS_IMPL = ~/GateMate/bin/p_r/cpelib.v

## target sources
VLOG_SRC = $(shell find ./src/ -type f \( -iname \*.v -o -iname \*.sv \))
VHDL_SRC = $(shell find ./src/ -type f \( -iname \*.vhd -o -iname \*.vhdl \))

## misc tools
RM = find $(SRC) -type f -name 

## toolchain targets
synth: synth_vlog

synth_sv: synth_svlog


# SYNTHESIS

# System verilog
synth_svlog: $(VLOG_SRC) #
	$(YOSYS) -m slang -p 'read_slang --top gm64 $(SV_INCLUDES) $(CELLS_SYNTH_SV) $^ ;  synth_gatemate  -nomx8 -vlog net/$(TOP)_synth.v stat' 

# Verilog
synth_vlog: $(VLOG_SRC)
	$(YOSYS) -ql log/synth.log -p 'read_verilog -sv $(SV_INCLUDES) $^; synth_gatemate -top $(TOP) -nomx8 -vlog net/$(TOP)_synth.v'

# VHDL
synth_vhdl: $(VHDL_SRC)
	$(YOSYS) -ql log/synth.log -p 'ghdl --warn-no-binding -C --ieee=synopsys $^ -e $(TOP); synth_gatemate -top $(TOP) -nomx8 -vlog net/$(TOP)_synth.v'

impl:
	$(PR) -tm 1 -i net/$(TOP)_synth.v -o $(TOP) $(PRFLAGS) > log/$@.log

jtag:
	$(OFL) $(OFLFLAGS) $(TOP)_00.cfg

jtag-flash:
	$(OFL) $(OFLFLAGS) -b olimex_gatemateevb -f --verify $(TOP)_00.cfg

spi:
	$(OFL) $(OFLFLAGS) -b olimex_gatemateevb -m $(TOP)_00.cfg

spi-flash:
	$(OFL) $(OFLFLAGS) -b olimex_gatemateevb -f --verify $(TOP)_00.cfg

all: synth impl jtag

all_sv: synth_sv impl jtag

## verilator system verilog simulation targets  
vlog_sim_sv.vvp:
	$(IVL_SVL) $(CELLS_SYNTH) $(CELLS_SYNTH_SV) $(IVL_SVL_FLAGS)  $(VLOG_SRC) ./sim/gm64_tb.sv

## icarus verilog simulation targets
vlog_sim.vvp:
	$(IVL) $(IVLFLAGS) -o sim/$@ $(VLOG_SRC) sim/$(TOP)_tb.sv $(CELLS_SYNTH)

synth_sim.vvp:
	$(IVL) $(IVLFLAGS) -o sim/$@ net/$(TOP)_synth.v sim/$(TOP)_tb.sv $(CELLS_SYNTH) -I ./ -I ./src -I ./src/src -I ../src/memCtrl/src -I ../src/visuMon/src

impl_sim.vvp:
	$(IVL) $(IVLFLAGS) -o sim/$@ $(TOP)_00.v sim/$(TOP)_tb.sv $(CELLS_IMPL) -I ./ -I ./src -I ./src/src -I ../src/memCtrl/src -I ../src/visuMon/src

.PHONY: %sim %sim.vvp

%sim: %sim.vvp
	$(VVP) -N sim/$< -lx2
	@$(RM) sim/$^

wave:
	$(GTKW) sim/$(TOP)_tb.vcd sim/config.gtkw

clean:
	$(RM) "*.txt" -delete
	$(RM) "*.log" -delete
	$(RM) "*_synth.v" -delete
	$(RM) "*.history" -delete
	$(RM) "*.refwire" -delete
	$(RM) "*.refparam" -delete
	$(RM) "*.refcomp" -delete
	$(RM) "*.pos" -delete
	$(RM) "*.pathes" -delete
	$(RM) "*.path_struc" -delete
	$(RM) "*.net" -delete
	$(RM) "*.id" -delete
	$(RM) "*.prn" -delete
	$(RM) "*_00.v" -delete
	$(RM) "*.used" -delete
	$(RM) "*.sdf" -delete
	$(RM) "*.place" -delete
	$(RM) "*.pin" -delete
	$(RM) "*_00.cfg*" -delete
	$(RM) "*.cdf" -delete
	$(RM) "*.vcd" -delete
	$(RM) "*.vvp" -delete
	$(RM) "*.gtkw" -delete
