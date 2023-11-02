CFLAGS += $(shell llvm-config )
LDFLAGS += $(shell llvm-config --libs)