AM_SRCS := riscv/ysyxsoc/start.S \
		   riscv/ysyxsoc/ssbl.S \
           riscv/ysyxsoc/trm.c \
		   riscv/ysyxsoc/timer.c \
		   riscv/ysyxsoc/ioe.c 

CFLAGS    += -fdata-sections -ffunction-sections
LDFLAGS   += -T $(AM_HOME)/scripts/soc_linker.ld
# --gc-sections:不链接未使用函数
LDFLAGS   += --gc-sections -e _start --print-map
CFLAGS += -DMAINARGS=\"$(mainargs)\"
DIFF_ARGS = -d $(NPC_HOME)/riscv32-nemu-interpreter-so
CFLAGS += -I$(AM_HOME)/am/src/riscv/ysyxsoc/include
YSYXSOCFLAGS += -l $(shell dirname $(IMAGE).elf)/ysyxsoc-log.txt -m $(shell dirname $(IMAGE).elf)/memory-ysyxsoc-log.txt -f $(shell dirname $(IMAGE).elf)/function-ysyxsoc-log.txt -e $(IMAGE).elf -v $(shell dirname $(IMAGE).elf)/device-ysyxsoc-log.txt
YSYXSOCFLAGS += -b -a $(shell dirname $(IMAGE).elf)/bin -x $(shell dirname $(IMAGE).elf)/exception-ysyxsoc-log.txt
YSYXSOCFLAGS += $(DIFF_ARGS)

.PHONY: $(AM_HOME)/am/src/riscv/ysyxsoc/trm.c

# -S 剥离目标文件的调试信息和符号表
#
image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -C $(NPC_HOME) sim ARGS="$(YSYXSOCFLAGS)" IMG=$(IMAGE).bin

gdb: image
	$(MAKE) -C $(NPC_HOME) gdb ARGS="$(YSYXSOCFLAGS)" IMG=$(IMAGE).bin
