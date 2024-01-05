NAME := ethernet

PCF := io.pcf
ASC := $(NAME).asc
BIN := $(NAME).bin
JSON := $(NAME).json
VP := $(NAME).vp
VCD := $(NAME).vcd

SRCS += top.v
SRCS += ethernet.v


all: $(BIN)

sim: $(VCD)

$(BIN): $(ASC)
	icepack $(NAME).asc $@

$(JSON): $(SRCS)
	yosys -p "synth_ice40 -top top -json $(NAME).json" top.v

$(ASC): $(JSON)
	nextpnr-ice40 --quiet --freq 48 --package sg48 --up5k --json $(JSON) --pcf $(PCF) --asc $(ASC)

gui: $(ASC) $(PCF)
	nextpnr-ice40 --quiet --freq 48 --package sg48 --up5k --json $(JSON) --pcf $(PCF) --gui

$(VP): $(SRCS) test.v
	iverilog -Wall -Winfloop -o $(VP) test.v 

$(VCD): $(VP) $(SRCS)
	vvp $(VP)

lint: $(SRCS)
	verilator --lint-only -Wall --timing --top top top.v
	verilator --lint-only -Wall --timing --top test test.v

prog: $(BIN)
	iceprog -S $(BIN)

prog_flash: $(BIN)
	iceprog $(BIN)

clean:
	rm -rf $(JSON) $(ASC) $(BIN) $(VP) $(VCD)
