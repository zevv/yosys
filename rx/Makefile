
CFLAGS += -Wall -Werror
SRATE = 20000
CHANNELS ?= 8
FACE ?= enx00e04c280b03


rx: rx.c
	gcc -o rx rx.c

run: rx
	sudo mii-tool -F 10BaseT-FD $(IFACE)
	sudo ./rx $(IFACE) | play -t raw -r $(SRATE) -b 16 -e signed-integer -L -c $(CHANNELS) --buffer 1024 -

baudline: rx
	sudo ./rx $(IFACE)| baudline -samplerate $(SRATE) -stdin -channels $(CHANNELS) -format le16 -record


