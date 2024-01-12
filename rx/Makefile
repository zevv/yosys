
CFLAGS += -Wall -Werror


rx: rx.c
	gcc -o rx rx.c

run: rx
	sudo ./rx enx00e04c680290 | play -t raw -r 10124 -b 16 -e signed-integer -L -c 16 --buffer 16384 -

baudline: rx
	sudo ./rx enx00e04c680290 | baudline -stdin -channels 2 -format le16 -record


