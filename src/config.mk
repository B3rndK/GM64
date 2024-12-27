
EXE =

## Source root
SRC=~/git/GM64

## toolchain
YOSYS = ~/GateMate/bin/yosys/yosys$(EXE)
PR    = ~/GateMate/bin/p_r/p_r$(EXE)
OFL   = ~/1git/openFPGALoader/build/openFPGALoader$(EXE)
OFLFLAGS =-b olimex_gatemateevb

GTKW = /usr/bin/gtkwave
IVL = iverilog
VVP = vvp
IVLFLAGS = -Winfloop -g2012 -gspecify -Ttyp

## simulation libraries
CELLS_SYNTH = ~/GateMate/bin/yosys/share/gatemate/cells_sim.v
CELLS_IMPL = ~/GateMate/bin/p_r/cpelib.v

## target sources
VLOG_SRC = $(shell find ./src/ -type f \( -iname \*.v -o -iname \*.sv \))
VHDL_SRC = $(shell find ./src/ -type f \( -iname \*.vhd -o -iname \*.vhdl \))

## misc tools
RM = find $(SRC) -type f -name 

## toolchain targets
synth: synth_vlog

synth_vlog: $(VLOG_SRC)
	$(YOSYS) -ql log/synth.log -p 'read -sv $^; synth_gatemate -top $(TOP) -nomx8 -vlog net/$(TOP)_synth.v'

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

## verilog simulation targets
vlog_sim.vvp:
	$(IVL) $(IVLFLAGS) -o sim/$@ $(VLOG_SRC) sim/$(TOP)_tb.v $(CELLS_SYNTH)

synth_sim.vvp:
	$(IVL) $(IVLFLAGS) -o sim/$@ net/$(TOP)_synth.v sim/$(TOP)_tb.v $(CELLS_SYNTH)

impl_sim.vvp:
	$(IVL) $(IVLFLAGS) -o sim/$@ $(TOP)_00.v sim/$(TOP)_tb.v $(CELLS_IMPL)

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
