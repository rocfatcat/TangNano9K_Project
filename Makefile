BOARD  = tangnano9k
FAMILY = GW1N-9C
DEVICE = GW1NR-LV9QN88PC6/I5

# Project files
TOP = top
VSRCS = $(wildcard src/*.v)
CST = src/tangnano9k.cst

# Build artifacts
JSON = $(TOP).json
PNR_JSON = $(TOP)_pnr.json
FS = $(TOP).fs

all: $(FS)

# Synthesis
$(JSON): $(VSRCS)
	yosys -p "read_verilog $(VSRCS); synth_gowin -top $(TOP) -json $(JSON)"

# Place and Route
$(PNR_JSON): $(JSON) $(CST)
	nextpnr-himbaechel --json $(JSON) \
		--write $@ \
		--device $(DEVICE) \
		--vopt family=$(FAMILY) \
		--vopt cst=$(CST) 

# Bitstream Generation
$(FS): $(PNR_JSON)
	gowin_pack -d $(FAMILY) -o $@ $^

# Program SRAM (volatile, lost after power cycle)
load: $(FS)
	openFPGALoader -b $(BOARD) $(FS)

# Program Flash (persistent)
flash: $(FS)
	openFPGALoader -b $(BOARD) -f $(FS)

clean:
	rm -f $(JSON) $(PNR_JSON) $(FS)

.PHONY: all load flash clean
