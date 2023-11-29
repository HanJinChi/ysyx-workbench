include $(NAVY_HOME)/scripts/riscv/common.mk
CFLAGS  += -march=rv32e_zicsr -mabi=ilp32e  #overwrite
LDFLAGS += -melf32lriscv

SRCS += $(NAVY_HOME)/libs/libgcc/div.S \
		$(NAVY_HOME)/libs/libgcc/muldi3.S \
		$(NAVY_HOME)/libs/libgcc/multi3.S \
		$(NAVY_HOME)/libs/libgcc/ashldi3.S