AM_SRCS := riscv/nemusoc/start.S \
           riscv/nemusoc/trm.c \
		   riscv/nemusoc/trm.c \
           riscv/nemusoc/ioe/ioe.c \
           riscv/nemusoc/ioe/timer.c \
           riscv/nemusoc/ioe/input.c \
           riscv/nemusoc/ioe/gpu.c 


CFLAGS    += -fdata-sections -ffunction-sections
LDFLAGS   += -T $(AM_HOME)/scripts/soc_linker.ld 
LDFLAGS   += --gc-sections -e _start --print-map
CFLAGS += -DMAINARGS=\"$(mainargs)\"
CFLAGS += -I$(AM_HOME)/am/src/riscv/nemusoc/include
NEMUSOCFLAGS += -l $(shell dirname $(IMAGE).elf)/nemusoc-log.txt -m $(shell dirname $(IMAGE).elf)/memory-nemusoc-log.txt -f $(shell dirname $(IMAGE).elf)/function-nemusoc-log.txt -e $(IMAGE).elf -v $(shell dirname $(IMAGE).elf)/device-nemusoc-log.txt
NEMUSOCFLAGS += -a $(shell dirname $(IMAGE).elf)/bin -x $(shell dirname $(IMAGE).elf)/exception-nemusoc-log.txt

.PHONY: $(AM_HOME)/am/src/riscv/nemusoc/trm.c

# -S 剥离目标文件的调试信息和符号表
#
image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -C $(NEMU_HOME) run ARGS="$(NEMUSOCFLAGS)" IMG=$(IMAGE).bin

gdb: image
	$(MAKE) -C $(NEMU_HOME) gdb ARGS="$(NEMUSOCFLAGS)" IMG=$(IMAGE).bin
