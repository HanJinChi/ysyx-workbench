TOPNAME = top

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --trace 
				
WORK_DIR  = $(shell pwd)

BUILD_DIR = $(WORK_DIR)/build
OBJ_DIR = $(WORK_DIR)/build/obj_dir

INC_PATH = $(WORK_DIR)/csrc/include 

BIN = $(BUILD_DIR)/$(TOPNAME)

ARGS += --log=$(BUILD_DIR)/npclog.txt --mlog=$(BUILD_DIR)/memory-npc-log.txt --flog=$(BUILD_DIR)/function-npc-log.txt --vlog=$(BUILD_DIR)/device-npc-log.txt -d $(NEMU_HOME)/build/riscv32-nemu-interpreter-so

# Include all filelist.mk to merge file lists
FILELIST_MK = $(shell find -L ./csrc/src -name "filelist.mk")
include $(FILELIST_MK)

# Command to execute NEMU
IMG ?=
NPC_EXEC := $(BIN) $(ARGS) $(IMG)

run-env: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

VSRCS = $(shell find $(abspath ./vsrc) -name "*.sv")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")


INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\"" -g -O0
LDFLAGS += -lncurses -lreadline -ldl -lSDL2
default: $(BIN)


$(BIN): $(VSRCS) $(CSRCS)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

all:
	default

sim: run-env
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(NPC_EXEC)

gdb: run-env
	$(call git_commit, "gdb RTL")
	gdb -s $(BIN) --args $(NPC_EXEC)

clean:
	rm -rf $(BUILD_DIR)

include ../Makefile
