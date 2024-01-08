include $(AM_HOME)/scripts/isa/riscv.mk
include $(AM_HOME)/scripts/platform/nemusoc.mk
COMMON_CFLAGS += -march=rv32e_zicsr -mabi=ilp32e  # overwrite
LDFLAGS       += -melf32lriscv                    # overwrite

AM_SRCS += riscv/nemusoc/libgcc/div.S \
           riscv/nemusoc/libgcc/muldi3.S \
           riscv/nemusoc/libgcc/multi3.c \
           riscv/nemusoc/libgcc/ashldi3.c \
           riscv/nemusoc/libgcc/unused.c
