TOPNAME = ysyxSoCFull

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --trace -j 0 --timescale "1ns/1ns" --autoflush 

VERILATOR_INC_PATH = $(WORK_DIR)/vsrc
VERILATOR_INC_PATH += $(WORK_DIR)/../ysyxSoC/perip/uart16550/rtl
VERILATOR_INC_PATH += $(WORK_DIR)/../ysyxSoC/perip/spi/rtl

VERILATOR_INCFLAGS = $(addprefix -I, $(VERILATOR_INC_PATH))

VERILATOR_CFLAGS += $(VERILATOR_INCFLAGS)

NXDC_FILES = constr/top.nxdc
				
WORK_DIR  = $(shell pwd)

BUILD_DIR = $(WORK_DIR)/build
OBJ_DIR = $(WORK_DIR)/build/obj_dir

INC_PATH = $(WORK_DIR)/csrc/include

BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

ARGS += --log=$(BUILD_DIR)/npclog.txt --mlog=$(BUILD_DIR)/memory-npc-log.txt --flog=$(BUILD_DIR)/function-npc-log.txt --vlog=$(BUILD_DIR)/device-npc-log.txt -d $(NPC_HOME)/riscv32-nemu-interpreter-so --elf=$(NPC_HOME)/char-test.bin
ARGS += --xlog=$(BUILD_DIR)/exception-npc-log.txt

# Include all filelist.mk to merge file lists
FILELIST_MK = $(shell find -L ./csrc/src -name "filelist.mk")
include $(FILELIST_MK)

# Command to execute NPC
IMG ?=
NPC_EXEC := $(BIN) $(ARGS) $(IMG)

run-env: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
VSRCS += $(shell find $(abspath ../ysyxSoC/perip) -name "*.v")
VSRCS += $(shell find $(abspath ../ysyxSoC/generated) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""  -O2
LDFLAGS += -lncurses -lreadline -ldl -lSDL2 

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

all: default

sim: run-env
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(NPC_EXEC)

gdb: run-env
	$(call git_commit, "gdb RTL")
	gdb -s $(BIN) --args $(NPC_EXEC)

clean:
	rm -rf $(BUILD_DIR)

include ../Makefile
