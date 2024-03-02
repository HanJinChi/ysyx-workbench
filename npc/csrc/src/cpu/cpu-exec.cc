#include <cpu/cpu.h>
#include <cpu/decode.h>
#include <cpu/difftest.h>
#include <memory/paddr.h>
#include <nvboard.h>
#include <isa.h>
#include "common.h"
#include "svdpi.h"
#include "VysyxSoCFull__Dpi.h"
#include "utils.h"

VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;
VysyxSoCFull* top;
CPU_state cpu = {};
static Decode s;

void nvboard_bind_all_pins(VysyxSoCFull* top);

uint32_t ins = 0;
bool end = 0;

uint64_t  clock_count = 0;
uint64_t  ins_count = 0;

uint64_t cost_time = 0;


bool check_watchpoint();
bool check_breakpoint(word_t pc);
void ftrace_check_address(int, uint32_t, uint32_t);
void sdb_mainloop();
void reopen_all_log();

void step_and_dump_wave();

void single_cycle();

void device_update();

void set_decode_inst(int pc, int inst){
  s.pc = (vaddr_t)pc;
  s.inst = inst;
}

extern "C" void flash_read(int addr, int *data) { 
  addr = addr &(~0x3u);
  addr = addr + FLASH_BASE;
  *data = paddr_read(addr, 4);
}
extern "C" void mrom_read(int addr, int* data)  { 
  addr = addr & (~0x3u);
  *data = paddr_read(addr, 4); 
}

extern "C" void psram_read(int addr, int* data)  { 
  // addr = addr & (~0x3u); // 因为psram最后是verilog实现的，所以这里不用四字节对齐
  addr = addr + MBASE;
  *data = paddr_read(addr, 4); 
}

extern "C" void psram_write(int addr, int data, char mask)  { 
  // addr = addr & (~0x3u); // 因为psram最后是verilog实现的，所以这里不用四字节对齐
  addr = addr + MBASE;
  int len = 0;
  switch (mask) 
  {
    case 0:
      break;
    case 1:
      paddr_write(addr, 1, data);
      break;
    case 0b11:
      paddr_write(addr, 2, data);
      break;
    case 0b1111:
      paddr_write(addr, 4, data);
      break;
    default:
      break;
  }
}

extern "C" void sdram_read(int addr, int* data){
  addr = addr + SDRAM_BASE;
  *data = paddr_read(addr, 4);
  // printf("read addr: 0x%x, data is 0x%x\n", addr, *data);
}

extern "C" void sdram_write(int addr, int data, char mask)  { 
  addr = addr + SDRAM_BASE;
  int len = 0;
  // printf("write addr: 0x%x, data is 0x%x, mask is %d\n", addr, data, mask);
  switch (mask) 
  {
    case 0:
      break;
    case 1:
      paddr_write(addr, 1, data & 0xff);
      break;
    case 0b10:
      paddr_write(addr+1, 1, (data & 0xff00)>>8);
      break;
    case 0b100:
      paddr_write(addr+2, 1, (data & 0xff0000)>>16);
      break;
    case 0b1000:
      paddr_write(addr+3, 1, (data & 0xff000000)>>24);
      break;
    case 0b1100:
      paddr_write(addr+2, 2, (data & 0xffff0000)>>16);
      break;
    case 0b11:
      paddr_write(addr, 2, data & 0x0000ffff);
      break;
    case 0b0110:
      paddr_write(addr+1, 2, (data & 0x0ff0)>>8);
      break;
    case 0b0111:
      paddr_write(addr, 3, data & 0x00ffffff);
      break;
    case 0b1110:
      paddr_write(addr+1, 3, (data & 0xffffff00)>>8);
      break;
    case 0b1111:
      paddr_write(addr, 4, data);
      break;
    default:
      break;
  }
}

void copy_cpu_state(){
  cpu.csr.mcause =  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk2__BRA__0__KET____DOT__regt____pinNumber4;
  cpu.csr.mepc   = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk2__BRA__1__KET____DOT__regt____pinNumber4;
  cpu.csr.mstatus   = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk2__BRA__2__KET____DOT__regt____pinNumber4;
  cpu.csr.mtvec   = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk2__BRA__3__KET____DOT__regt____pinNumber4;
  cpu.gpr[0] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__0__KET____DOT__regx____pinNumber4;
  cpu.gpr[1] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__1__KET____DOT__regx____pinNumber4;
  cpu.gpr[2] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__2__KET____DOT__regx____pinNumber4;
  cpu.gpr[3] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__3__KET____DOT__regx____pinNumber4;
  cpu.gpr[4] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__4__KET____DOT__regx____pinNumber4;
  cpu.gpr[5] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__5__KET____DOT__regx____pinNumber4;
  cpu.gpr[6] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__6__KET____DOT__regx____pinNumber4;
  cpu.gpr[7] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__7__KET____DOT__regx____pinNumber4;
  cpu.gpr[8] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__8__KET____DOT__regx____pinNumber4;
  cpu.gpr[9] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__9__KET____DOT__regx____pinNumber4;
  cpu.gpr[10] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__10__KET____DOT__regx____pinNumber4;
  cpu.gpr[11] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__11__KET____DOT__regx____pinNumber4;
  cpu.gpr[12] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__12__KET____DOT__regx____pinNumber4;
  cpu.gpr[13] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__13__KET____DOT__regx____pinNumber4;
  cpu.gpr[14] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__14__KET____DOT__regx____pinNumber4;
  cpu.gpr[15] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__15__KET____DOT__regx____pinNumber4;
  cpu.gpr[16] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__16__KET____DOT__regx____pinNumber4;
  cpu.gpr[17] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__17__KET____DOT__regx____pinNumber4;
  cpu.gpr[18] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__18__KET____DOT__regx____pinNumber4;
  cpu.gpr[19] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__19__KET____DOT__regx____pinNumber4;
  cpu.gpr[20] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__20__KET____DOT__regx____pinNumber4;
  cpu.gpr[21] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__21__KET____DOT__regx____pinNumber4;
  cpu.gpr[22] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__22__KET____DOT__regx____pinNumber4;
  cpu.gpr[23] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__23__KET____DOT__regx____pinNumber4;
  cpu.gpr[24] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__24__KET____DOT__regx____pinNumber4;
  cpu.gpr[25] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__25__KET____DOT__regx____pinNumber4;
  cpu.gpr[26] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__26__KET____DOT__regx____pinNumber4;
  cpu.gpr[27] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__27__KET____DOT__regx____pinNumber4;
  cpu.gpr[28] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__28__KET____DOT__regx____pinNumber4;
  cpu.gpr[29] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__29__KET____DOT__regx____pinNumber4;
  cpu.gpr[30] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__30__KET____DOT__regx____pinNumber4;
  cpu.gpr[31] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__31__KET____DOT__regx____pinNumber4;
  cpu.pc      = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT__pc_next;  // cpu.pc代表执行完一条指令后,下一条应该执行哪条指令
}

void set_cpu_state(){
  top->clock = 1;
  top->reset = 1;
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__set_pc = cpu.pc;
  top->eval();
#ifdef CONFIG_VCD_TRACE
  tfp->dump(contextp->time());
  contextp->timeInc(1);
#endif
  top->clock = 0;
  top->reset = 0;
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc = cpu.pc;
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk2__BRA__0__KET____DOT__regt____pinNumber4 = cpu.csr.mcause ;
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk2__BRA__1__KET____DOT__regt____pinNumber4 = cpu.csr.mepc;
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk2__BRA__2__KET____DOT__regt____pinNumber4 = cpu.csr.mstatus ;
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk2__BRA__3__KET____DOT__regt____pinNumber4 = cpu.csr.mtvec;
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__0__KET____DOT__regx____pinNumber4 = cpu.gpr[0];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__1__KET____DOT__regx____pinNumber4 = cpu.gpr[1];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__2__KET____DOT__regx____pinNumber4 = cpu.gpr[2];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__3__KET____DOT__regx____pinNumber4 = cpu.gpr[3];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__4__KET____DOT__regx____pinNumber4 = cpu.gpr[4];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__5__KET____DOT__regx____pinNumber4 = cpu.gpr[5];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__6__KET____DOT__regx____pinNumber4 = cpu.gpr[6];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__7__KET____DOT__regx____pinNumber4 = cpu.gpr[7];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__8__KET____DOT__regx____pinNumber4 = cpu.gpr[8];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__9__KET____DOT__regx____pinNumber4 = cpu.gpr[9];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__10__KET____DOT__regx____pinNumber4 = cpu.gpr[10];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__11__KET____DOT__regx____pinNumber4 = cpu.gpr[11];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__12__KET____DOT__regx____pinNumber4 = cpu.gpr[12];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__13__KET____DOT__regx____pinNumber4 = cpu.gpr[13];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__14__KET____DOT__regx____pinNumber4 = cpu.gpr[14];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__15__KET____DOT__regx____pinNumber4 = cpu.gpr[15];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__16__KET____DOT__regx____pinNumber4 = cpu.gpr[16];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__17__KET____DOT__regx____pinNumber4 = cpu.gpr[17];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__18__KET____DOT__regx____pinNumber4 = cpu.gpr[18];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__19__KET____DOT__regx____pinNumber4 = cpu.gpr[19];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__20__KET____DOT__regx____pinNumber4 = cpu.gpr[20];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__21__KET____DOT__regx____pinNumber4 = cpu.gpr[21];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__22__KET____DOT__regx____pinNumber4 = cpu.gpr[22];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__23__KET____DOT__regx____pinNumber4 = cpu.gpr[23];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__24__KET____DOT__regx____pinNumber4 = cpu.gpr[24];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__25__KET____DOT__regx____pinNumber4 = cpu.gpr[25];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__26__KET____DOT__regx____pinNumber4 = cpu.gpr[26];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__27__KET____DOT__regx____pinNumber4 = cpu.gpr[27];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__28__KET____DOT__regx____pinNumber4 = cpu.gpr[28];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__29__KET____DOT__regx____pinNumber4 = cpu.gpr[29];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__30__KET____DOT__regx____pinNumber4 = cpu.gpr[30];
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT____Vcellout__genblk1__BRA__31__KET____DOT__regx____pinNumber4 = cpu.gpr[31];
  top->eval();
#ifdef CONFIG_VCD_TRACE
  tfp->dump(contextp->time());
  contextp->timeInc(1);
#endif
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__set_pc = 0;
}

void trace_and_difftest(){
  #ifdef CONFIG_TRACE
    log_write("%s\n", s.logbuf);
  #endif

  #ifdef CONFIG_FTRACE
  char *p = s.logbuf + 24; // inst start
  uint32_t addr = s.dnpc; 
  if(strncmp(p, "jal\t", 4) == 0){
    ftrace_check_address(0, s.pc, addr);
  }else if(strncmp(p, "jalr\t", 5) == 0){
    ftrace_check_address(1, s.pc, addr);
  }
  #endif

  #ifdef CONFIG_DIFFTEST
    difftest_step(cpu.pc,0);
  #endif

#ifdef CONFIG_WATCHPOINT
  if(check_watchpoint()) { 
    npc_state.state = NPC_STOP;
    printf("reach watchpoint\n");
    sdb_mainloop();
  }
  if(check_breakpoint(s.pc)) { 
    npc_state.state = NPC_STOP;
    printf("reach breakpoint\n");  
    sdb_mainloop();
  }
#endif
}


void init_cpu(){
  contextp = new VerilatedContext;
  tfp = new VerilatedVcdC;
  top = new VysyxSoCFull;

#ifdef CONFIG_HAS_NVBOARD
  nvboard_bind_all_pins(top);
  nvboard_init();
#endif  

#ifdef CONFIG_VCD_TRACE
  contextp->traceEverOn(true);
  contextp->time(0);
  contextp->timeunit(1); // 设置时间单位为1ns
  contextp->timeprecision(1); // 时间单位为1ns
  top->trace(tfp, 0);
  tfp->open("dump.vcd");
#endif
  // reset
  top->reset = 1;
  top->clock = 0;
  top->eval();
#ifdef CONFIG_VCD_TRACE
  tfp->dump(contextp->time());
  contextp->timeInc(1);
#endif
  for(int i = 0; i < 10; i++){
    step_and_dump_wave();
    step_and_dump_wave();
  }
  top->clock = 1;
  top->eval();
#ifdef CONFIG_VCD_TRACE
  tfp->dump(contextp->time());
  contextp->timeInc(1);
#endif
  top->reset = 0;
  top->clock = 0;
  top->eval();
#ifdef CONFIG_VCD_TRACE
  tfp->dump(contextp->time());
  contextp->timeInc(1);
#endif
  cpu.pc = 0x30000000;
}

void cpu_exit(){
  tfp->close();
  delete contextp;
  delete tfp;
}

inline void step_and_dump_wave(){ // 执行一次函数是半个周期
  top->clock = !top->clock;
//   printf("ysyx_23060059 reg is %0x8x\n", top->rootp->__Vtrigrprev__ysyx_23060059__ysyx_23060059__ra__genblk1__BRA__31__KET____DOT__regx____PVT__clock);
  top->eval();
#ifdef CONFIG_VCD_TRACE
  tfp->dump(contextp->time());
  contextp->timeInc(1);
#endif

}

void single_cycle(){
  step_and_dump_wave();
  step_and_dump_wave();
#ifdef CONFIG_HAS_NVBOARD 
  nvboard_update();
#endif
}

void exec_once(){
  // 执行两个周期是一条指令
  while(true){
    single_cycle();
    clock_count++;
    if(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ls__DOT__send_valid_r == 1) {
      single_cycle();
      clock_count++;
      break;
    }
  } 
  ins_count++;
  copy_cpu_state();

  #ifdef CONFIG_DIFFTEST
    if(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__skip == 1) difftest_skip_ref();
  #endif

  #ifdef CONFIG_TRACE
    s.pc   = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT__pc;  // s.pc代表刚执行完的这条指令的pc值
    s.dnpc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT__pc_next;
    s.inst = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT__instruction;

    char *p = s.logbuf;
    p += snprintf(p, sizeof(s.logbuf), FMT_WORD ":", s.pc);
    uint8_t *inst = (uint8_t *)&s.inst;
    for (int i = 4 - 1; i >= 0; i --) {
      p += snprintf(p, 4, " %02x", inst[i]);
    }
    int space_len = 1;
    memset(p, ' ', space_len);
    p += space_len;

    void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
    disassemble(p, s.logbuf + sizeof(s.logbuf) - p,
        s.pc, (uint8_t *)&s.inst, 4);
  #endif

  #ifdef CONFIG_XTRACE
    if(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT__ecall_r == 1){
      exception_log_write("pc is 0x%x, raise intr with exception number is %d\n", s.pc, cpu.gpr[15]);
    }
  #endif
  end = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ebreak;

  if(end){
    NPCTRAP(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wb__DOT__pc, cpu.gpr[0]);
  } 
}


void execute(uint64_t n){
  for(; n > 0; n--){
    exec_once();
    trace_and_difftest();
    if (npc_state.state != NPC_RUNNING) break;
    IFDEF(CONFIG_DEVICE, device_update());
  }
}

void statistic(){
  Log("clock count: %ld, inst_count : %ld, IPC: %f", clock_count, ins_count, (1.0*ins_count)/clock_count);
  Log("host time spent = %ld us", cost_time);
  if (cost_time > 0) Log("simulation frequency = %ld inst/s", ins_count * 1000000 / cost_time);
}

void cpu_exec(uint64_t n){
  switch (npc_state.state) {
    case NPC_END: case NPC_ABORT:
      printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
      return;
    default: npc_state.state = NPC_RUNNING;
  }

  uint64_t start_time = get_time();

  execute(n);

  cost_time = get_time() - start_time;

  switch (npc_state.state) {
    case NPC_RUNNING: npc_state.state = NPC_STOP; break;

    case NPC_END: case NPC_ABORT:
      Log("npc: %s at pc = " FMT_WORD,
          (npc_state.state == NPC_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) :
           (npc_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
            ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
          npc_state.halt_pc);
      // Log("clock count: %d, inst_count : %d, IPC: %f\n", clock_count, ins_count, (1.0*ins_count)/clock_count);
      // fall through
    case NPC_QUIT: statistic();
    default: break;
  }
}

void assert_fail_msg() {
  isa_reg_display();
  statistic();
  cpu_exit();
}