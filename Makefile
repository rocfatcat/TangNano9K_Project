BOARD  = tangnano9k
FAMILY = GW1N-9C
DEVICE = GW1NR-LV9QN88PC6/I5

# Default voltage for eSPI is 1.8V. 
# Override via 'make VOLTAGE=3.3'
VOLTAGE ?= 1.8

# Select CST file based on voltage
ifeq ($(VOLTAGE),3.3)
    CST = src/tangnano9k_3v3.cst
else
    CST = src/tangnano9k_1v8.cst
endif

# Project files
TOP = top
VSRCS = $(wildcard src/*.v)

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
	@echo "Using constraints: $(CST) for $(VOLTAGE)V IO"
	nextpnr-gowin --json $(JSON) \
		--write $@ \
		--device $(DEVICE) \
		--family $(FAMILY) \
		--cst $(CST)

# Bitstream Generation
$(FS): $(PNR_JSON)
	gowin_pack -d $(FAMILY) -o $@ $^

# Program SRAM
load: $(FS)
	openFPGALoader -b $(BOARD) $(FS)

# Program Flash
flash: $(FS)
	openFPGALoader -b $(BOARD) -f $(FS)

clean:
	rm -f $(JSON) $(PNR_JSON) $(FS)

.PHONY: all load flash clean
