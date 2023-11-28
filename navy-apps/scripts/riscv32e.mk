CROSS_COMPILE = riscv64-linux-gnu-
LNK_ADDR = $(if $(VME), 0x40000000, 0x83000000)
CFLAGS  += -fno-pic -march=rv32e_zicsr -mabi=ilp32e
LDFLAGS += -melf32lriscv --no-relax -Ttext-segment $(LNK_ADDR)

SRCS += $(NAVY_HOME)/libs/libgcc/div.S \
		$(NAVY_HOME)/libs/libgcc/muldi3.S \
		$(NAVY_HOME)/libs/libgcc/multi3.S \
		$(NAVY_HOME)/libs/libgcc/ashldi3.S