#include <cpu/cpu.h>
#include <cpu/decode.h>
#include <cpu/difftest.h>
#include <memory/paddr.h>
#include <isa.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"

VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;
Vtop* top;
CPU_state cpu = {};
static Decode s;

uint32_t ins = 0;
bool end = 0;
int write_count = 0;
int read_count = 0;

void ftrace_check_address(int, uint32_t, uint32_t);
void step_and_dump_wave();

void device_update();

void end_sim(int end_simluation){
  end = (end_simluation != 0);
}

void set_decode_inst(int pc, int inst){
  s.pc = (vaddr_t)pc;
  s.inst = inst;
}


void n_pmem_read(int raddr, int *rdata){
  *rdata = paddr_read(raddr, 4);
}

void n_pmem_write(int waddr, int wdata, char wmask){
  int i = 0;
  uint8_t wdata_bytes[sizeof(int)];
  memcpy(wdata_bytes, &wdata, sizeof(int));

  switch (wmask)
  {
  case 0:
    break;
  case 1:
    paddr_write(waddr, 1, wdata_bytes[0]);
    break;
  case 0b11:
    paddr_write(waddr, 2, wdata_bytes[1]<<8 | wdata_bytes[0]);
    break;
  case 0b1111:
    paddr_write(waddr, 4, wdata);
    break;
  default:
    break;
  }
  
}

void copy_cpu_state(){
  for(int i = 0; i < 32; i++) cpu.gpr[i] = top->__PVT__top->__PVT__wb->__PVT__w_regarray_subsequent[i];
  cpu.csr.mcause = top->__PVT__top->__PVT__wb->__PVT__w_csrarray_subsequent[0];
  cpu.csr.mepc   = top->__PVT__top->__PVT__wb->__PVT__w_csrarray_subsequent[1];
  cpu.csr.mstatus   = top->__PVT__top->__PVT__wb->__PVT__w_csrarray_subsequent[2];
  cpu.csr.mtvec   = top->__PVT__top->__PVT__wb->__PVT__w_csrarray_subsequent[3];

}

void trace_and_difftest(){
  #ifdef CONFIG_TRACE
    log_write("%s\n", s.logbuf);
  #endif

  #ifdef CONFIG_FTRACE
    char *p = s.logbuf + 24; // inst start
    uint32_t addr = 0; 
    if(strncmp(p, "jal\t", 4) == 0){
      if(strncmp("zero", p+4, 4) == 0){
        p = p + 12;
      }else{
        p = p + 10;
      }
      sscanf(p, "%8X", &addr);
      ftrace_check_address(0, s.pc, addr);
    }else if(strncmp(p, "jalr\t", 5) == 0){
      int type = 0;
      char rega[3] = {};
      bool success = false;
      if(strncmp("zero", p+5, 4) == 0){
        p = p + 13;
        type = 1;
      }else{
        p = p + 11;
      }
      strncpy(rega, p, 2);
      addr = isa_reg_str2val(rega, &success);
      assert(success);
      ftrace_check_address(type, s.pc, addr);
    }
  #endif

  #ifdef CONFIG_DIFFTEST
    difftest_step(cpu.pc,0);
  #endif
}

void init_cpu(){
  contextp = new VerilatedContext;
  tfp = new VerilatedVcdC;
  top = new Vtop;
#ifdef CONFIG_VCD_TRACE
  contextp->traceEverOn(true);
  contextp->time(0);
  contextp->timeunit(1); // 设置时间单位为1ns
  contextp->timeprecision(1); // 时间单位为1ns
  top->trace(tfp, 0);
  tfp->open("dump.vcd");
#endif
  top->rst = 1;
  top->clk = 0;
  top->eval();
#ifdef CONFIG_VCD_TRACE
  tfp->dump(contextp->time());
  contextp->timeInc(1);
#endif
  top->clk = 1;
  top->eval();
#ifdef CONFIG_VCD_TRACE
  tfp->dump(contextp->time());
  contextp->timeInc(1);
#endif

  top->rst = 0;
  top->clk = 0;
  top->eval();
#ifdef CONFIG_VCD_TRACE
  tfp->dump(contextp->time());
  contextp->timeInc(1);
#endif
  cpu.pc = 0x80000000;
}

void cpu_exit(){
  tfp->close();
  delete contextp;
  delete tfp;
}

void step_and_dump_wave(){ // 执行一次函数是半个周期
  top->clk = !top->clk;
//   printf("top reg is %0x8x\n", top->rootp->__Vtrigrprev__TOP__top__ra__genblk1__BRA__31__KET____DOT__regx____PVT__clk);
  top->eval();
#ifdef CONFIG_VCD_TRACE
  tfp->dump(contextp->time());
  contextp->timeInc(1);
#endif

}

void exec_once(){
  // 执行两个周期是一条指令
  while(true){
    step_and_dump_wave();
    step_and_dump_wave();
    if(top->__PVT__top->__PVT__lsu_send_valid == 1) break;
  }

  cpu.pc = top->pc_next;
  copy_cpu_state();

  #ifdef CONFIG_TRACE
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


  if(end){
    NPCTRAP(s.pc, cpu.gpr[0]);
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

void cpu_exec(uint64_t n){
  switch (npc_state.state) {
    case NPC_END: case NPC_ABORT:
      printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
      return;
    default: npc_state.state = NPC_RUNNING;
  }
  execute(n);

  switch (npc_state.state) {
    case NPC_RUNNING: npc_state.state = NPC_STOP; break;

    case NPC_END: case NPC_ABORT:
      Log("npc: %s at pc = " FMT_WORD,
          (npc_state.state == NPC_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) :
           (npc_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
            ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
          npc_state.halt_pc);
      // fall through
    // case NPC_QUIT: statistic();
    default: break;
  }
}

void assert_fail_msg() {

}