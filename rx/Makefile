
CFLAGS += -Wall -Werror
SRATE = 20000
CHANNELS ?= 8



rx: rx.c
	gcc -o rx rx.c

run: rx
	sudo ./rx enx00e04c680290 | play -t raw -r $(SRATE) -b 16 -e signed-integer -L -c $(CHANNELS) --buffer 16384 -

baudline: rx
	sudo ./rx enx00e04c680290 | baudline -samplerate $(SRATE) -stdin -channels $(CHANNELS) -format le16 -record


