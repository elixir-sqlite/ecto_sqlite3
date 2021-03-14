SRC = sqlite3/sqlite3.c c_src/sqlite3_nif.c
OBJ = $(SRC:.c=.o)

CFLAGS ?= -g

# TODO: We should allow the person building to be able to specify this
CFLAGS += -O3

CFLAGS += -Wall
CFLAGS += -I"$(ERTS_INCLUDE_DIR)"
CFLAGS += -Isqlite3 -Ic_src

# For more information about these features being enabled, check out
# --> https://sqlite.org/compile.html
CFLAGS += -DSQLITE_THREADSAFE=1
CFLAGS += -DSQLITE_USE_URI=1
CFLAGS += -DSQLITE_LIKE_DOESNT_MATCH_BLOBS=1
CFLAGS += -DSQLITE_DQS=0

# TODO: The following features should be completely configurable by the person
#       installing the nif. Just need to have certain environment variables
#       enabled to support them.
CFLAGS += -DALLOW_COVERING_INDEX_SCAN=1
CFLAGS += -DENABLE_FTS3_PARENTHESIS=1
CFLAGS += -DENABLE_LOAD_EXTENSION=1
CFLAGS += -DENABLE_SOUNDEX=1
CFLAGS += -DENABLE_STAT4=1
CFLAGS += -DENABLE_UPDATE_DELETE_LIMIT=1
CFLAGS += -DSQLITE_ENABLE_FTS3=1
CFLAGS += -DSQLITE_ENABLE_FTS4=1
CFLAGS += -DSQLITE_ENABLE_FTS5=1
CFLAGS += -DSQLITE_ENABLE_GEOPOLY=1
CFLAGS += -DSQLITE_ENABLE_JSON1=1
CFLAGS += -DSQLITE_ENABLE_MATH_FUNCTIONS=1
CFLAGS += -DSQLITE_ENABLE_RBU=1
CFLAGS += -DSQLITE_ENABLE_RTREE=1
CFLAGS += -DSQLITE_OMIT_DEPRECATED=1

# TODO: We should allow the person building to be able to specify this
CFLAGS += -DNDEBUG=1

KERNEL_NAME := $(shell uname -s)

PRIV_DIR = $(MIX_APP_PATH)/priv
LIB_NAME = $(PRIV_DIR)/sqlite3_nif.so

ifneq ($(CROSSCOMPILE),)
	CFLAGS += -shared -fPIC -fvisibility=hidden
	SO_LDFLAGS := -Wl,-soname,libsqlite3.so.0
else
	ifeq ($(KERNEL_NAME), Linux)
		CFLAGS += -shared -fPIC -fvisibility=hidden
		SO_LDFLAGS := -Wl,-soname,libsqlite3.so.0
	endif
	ifeq ($(KERNEL_NAME), Darwin)
		CFLAGS += -dynamiclib -undefined dynamic_lookup
	endif
	ifeq ($(KERNEL_NAME), $(filter $(KERNEL_NAME),OpenBSD FreeBSD NetBSD))
		CFLAGS += -shared -fPIC
	endif
endif

%.o: %.c
	$(CC) $(CFLAGS) -o $@ -c $<

all: $(PRIV_DIR) $(LIB_NAME)

$(LIB_NAME): $(OBJ)
	$(CC) $(CFLAGS) $(SO_LDFLAGS) $^ -o $@

$(PRIV_DIR):
	mkdir -p $@

clean:
	rm -f $(LIB_NAME)

.PHONY: all clean
