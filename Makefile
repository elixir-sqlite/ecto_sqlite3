SRC = sqlite3/sqlite3.c c_src/sqlite3_nif.c

CFLAGS ?= -g

# TODO: We should allow the person building to be able to specify this
CFLAGS += -O3

CFLAGS += -Wall
CFLAGS += -I"$(ERTS_INCLUDE_DIR)"
CFLAGS += -Isqlite3 -Ic_src
CFLAGS += -DSQLITE_THREADSAFE=1 -DSQLITE_USE_URI -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS

# TODO: We should allow the person building to be able to specify this
CFLAGS += -DNDEBUG=1

KERNEL_NAME := $(shell uname -s)

PRIV_DIR = $(MIX_APP_PATH)/priv
LIB_NAME = $(PRIV_DIR)/sqlite3_nif.so

ifneq ($(CROSSCOMPILE),)
	LIB_CFLAGS := -shared -fPIC -fvisibility=hidden
	SO_LDFLAGS := -Wl,-soname,libsqlite3.so.0
else
	ifeq ($(KERNEL_NAME), Linux)
		LIB_CFLAGS := -shared -fPIC -fvisibility=hidden
		SO_LDFLAGS := -Wl,-soname,libsqlite3.so.0
	endif
	ifeq ($(KERNEL_NAME), Darwin)
		LIB_CFLAGS := -dynamiclib -undefined dynamic_lookup
	endif
	ifeq ($(KERNEL_NAME), $(filter $(KERNEL_NAME),OpenBSD FreeBSD NetBSD))
		LIB_CFLAGS := -shared -fPIC
	endif
endif

all: $(PRIV_DIR) $(LIB_NAME)

$(LIB_NAME): $(SRC)
	$(CC) $(CFLAGS) $(LIB_CFLAGS) $(SO_LDFLAGS) $^ -o $@

$(PRIV_DIR):
	mkdir -p $@

clean:
	rm -f $(LIB_NAME)

.PHONY: all clean
