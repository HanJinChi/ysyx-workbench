AM_SRCS := riscv/npc/start.S \
           riscv/npc/trm.c \
           riscv/npc/ioe.c \
           riscv/npc/gpu.c \
           riscv/npc/timer.c \
           riscv/npc/input.c \
           riscv/npc/cte.c \
           riscv/npc/trap.S \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
LDFLAGS   += -T $(AM_HOME)/scripts/linker.ld \
						 --defsym=_pmem_start=0x80000000 --defsym=_entry_offset=0x0
LDFLAGS   += --gc-sections -e _start  --print-map 
DIFF_ARGS = -d $(NPC_HOME)/riscv32-nemu-interpreter-so
CFLAGS += -DMAINARGS=\"$(mainargs)\"
CFLAGS += -I$(AM_HOME)/am/src/riscv/npc/include
NPCFLAGS +=  -b  -l $(shell dirname $(IMAGE).elf)/npc-log.txt -m $(shell dirname $(IMAGE).elf)/memory-npc-log.txt -f $(shell dirname $(IMAGE).elf)/function-npc-log.txt -e $(IMAGE).elf -v $(shell dirname $(IMAGE).elf)/device-npc-log.txt
NPCFLAGS += -a $(shell dirname $(IMAGE).elf)/bin -x $(shell dirname $(IMAGE).elf)/exception-npc-log.txt
NPCFLAGS += $(DIFF_ARGS)


.PHONY: $(AM_HOME)/am/src/riscv/npc/trm.c

image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -C $(NPC_HOME) sim ARGS="$(NPCFLAGS)" IMG=$(IMAGE).bin

gdb: image
	$(MAKE) -C $(NPC_HOME) gdb ARGS="$(NPCFLAGS)" IMG=$(IMAGE).bin
