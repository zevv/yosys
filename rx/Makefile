
CFLAGS += -Wall -Werror


rx: rx.c
	gcc -o rx rx.c

run: rx
	sudo ./rx enx00e04c680290 | play -t raw -r 20000 -b 16 -e signed-integer -L -c 2 --buffer 16384 -

baudline: rx
	sudo ./rx enx00e04c680290 | baudline -samplerate 20000 -stdin -channels 2 -format le16 -record


