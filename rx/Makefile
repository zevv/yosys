
CFLAGS += -Wall -Werror


rx: rx.c
	gcc -o rx rx.c

run: rx
	sudo ./rx enx00e04c680290 | play -t raw -r 15625 -b 16 -e signed-integer -L -c 2 --buffer 128 -

