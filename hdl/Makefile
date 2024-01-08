NAME := ethernet

PCF := io.pcf
ASC := $(NAME).asc
BIN := $(NAME).bin
JSON := $(NAME).json
VP := $(NAME).vp
VCD := $(NAME).vcd

SRCS += top.v
SRCS += ethernet.v
SRCS += sender.v
SRCS += bram.v
SRCS += audio.v

NEXTPNRFLAGS := --freq 48 --package sg48 --up5k --detailed-timing-report

all: $(BIN)

sim: $(VCD)

$(BIN): $(ASC)
	icepack $(NAME).asc $@

$(JSON): $(SRCS)
	yosys -Q -T -p "synth_ice40 -top top -json $(NAME).json" top.v

$(ASC): $(JSON)
	nextpnr-ice40 $(NEXTPNRFLAGS) --json $(JSON) --pcf $(PCF) --asc $(ASC) -l $(NAME).log

gui: $(ASC) $(PCF)
	nextpnr-ice40 $(NEXTPNRFLAGS) --json $(JSON) --pcf $(PCF) --gui

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

report: $(JSON)
	./timing.pl < $(NAME).log

clean:
	rm -rf $(JSON) $(ASC) $(BIN) $(VP) $(VCD)
