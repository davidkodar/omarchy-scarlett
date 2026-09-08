CC ?= cc
CPPFLAGS += $(shell pkg-config --cflags alsa json-c)
CFLAGS ?= -O2 -g
CFLAGS += -std=c11 -Wall -Wextra -Wpedantic -Werror
LDLIBS += $(shell pkg-config --libs alsa json-c)

.PHONY: all check clean
all: bin/scarlett-helper
bin/scarlett-helper: src/scarlett-helper.c
	mkdir -p bin
	$(CC) $(CPPFLAGS) $(CFLAGS) $< $(LDFLAGS) $(LDLIBS) -o $@
check: all
	python3 tests/test_protocol.py
clean:
	rm -f bin/scarlett-helper
