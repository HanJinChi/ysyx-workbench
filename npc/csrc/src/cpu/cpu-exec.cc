#include <cpu/cpu.h>
#include <cpu/decode.h>
#include <cpu/difftest.h>
#include <memory/paddr.h>
#include <isa.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include "utils.h"

VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;
Vtop* top;
CPU_state cpu = {};
static Decode s;

uint32_t ins = 0;
bool end = 0;

uint64_t  clock_count = 0;
uint64_t  ins_count = 0;

bool check_watchpoint();
bool check_breakpoint(word_t pc);
void ftrace_check_address(int, uint32_t, uint32_t);
void sdb_mainloop();
void reopen_all_log();

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
  cpu.csr.mcause =  top->rootp->top__DOT__wb__DOT____Vcellout__genblk2__BRA__0__KET____DOT__regx____pinNumber4;
  cpu.csr.mepc   = top->rootp->top__DOT__wb__DOT____Vcellout__genblk2__BRA__1__KET____DOT__regx____pinNumber4;
  cpu.csr.mstatus   = top->rootp->top__DOT__wb__DOT____Vcellout__genblk2__BRA__2__KET____DOT__regx____pinNumber4;
  cpu.csr.mtvec   = top->rootp->top__DOT__wb__DOT____Vcellout__genblk2__BRA__3__KET____DOT__regx____pinNumber4;
  cpu.gpr[0] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__0__KET____DOT__regx____pinNumber4;
  cpu.gpr[1] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__1__KET____DOT__regx____pinNumber4;
  cpu.gpr[2] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__2__KET____DOT__regx____pinNumber4;
  cpu.gpr[3] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__3__KET____DOT__regx____pinNumber4;
  cpu.gpr[4] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__4__KET____DOT__regx____pinNumber4;
  cpu.gpr[5] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__5__KET____DOT__regx____pinNumber4;
  cpu.gpr[6] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__6__KET____DOT__regx____pinNumber4;
  cpu.gpr[7] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__7__KET____DOT__regx____pinNumber4;
  cpu.gpr[8] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__8__KET____DOT__regx____pinNumber4;
  cpu.gpr[9] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__9__KET____DOT__regx____pinNumber4;
  cpu.gpr[10] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__10__KET____DOT__regx____pinNumber4;
  cpu.gpr[11] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__11__KET____DOT__regx____pinNumber4;
  cpu.gpr[12] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__12__KET____DOT__regx____pinNumber4;
  cpu.gpr[13] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__13__KET____DOT__regx____pinNumber4;
  cpu.gpr[14] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__14__KET____DOT__regx____pinNumber4;
  cpu.gpr[15] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__15__KET____DOT__regx____pinNumber4;
  cpu.gpr[16] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__16__KET____DOT__regx____pinNumber4;
  cpu.gpr[17] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__17__KET____DOT__regx____pinNumber4;
  cpu.gpr[18] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__18__KET____DOT__regx____pinNumber4;
  cpu.gpr[19] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__19__KET____DOT__regx____pinNumber4;
  cpu.gpr[20] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__20__KET____DOT__regx____pinNumber4;
  cpu.gpr[21] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__21__KET____DOT__regx____pinNumber4;
  cpu.gpr[22] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__22__KET____DOT__regx____pinNumber4;
  cpu.gpr[23] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__23__KET____DOT__regx____pinNumber4;
  cpu.gpr[24] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__24__KET____DOT__regx____pinNumber4;
  cpu.gpr[25] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__25__KET____DOT__regx____pinNumber4;
  cpu.gpr[26] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__26__KET____DOT__regx____pinNumber4;
  cpu.gpr[27] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__27__KET____DOT__regx____pinNumber4;
  cpu.gpr[28] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__28__KET____DOT__regx____pinNumber4;
  cpu.gpr[29] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__29__KET____DOT__regx____pinNumber4;
  cpu.gpr[30] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__30__KET____DOT__regx____pinNumber4;
  cpu.gpr[31] = top->rootp->top__DOT__wb__DOT____Vcellout__genblk1__BRA__31__KET____DOT__regx____pinNumber4;
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
    clock_count++;
    if(top->rootp->top__DOT__ls__DOT__lsu_send_valid_r == 1) {
      step_and_dump_wave();
      step_and_dump_wave();
      clock_count++;
      break;
    }
  } 
  ins_count++;
  cpu.pc = top->rootp->top__DOT__wb__DOT__pc_next;  // cpu.pc代表执行完一条指令后,下一条应该执行哪条指令
  copy_cpu_state();


  #ifdef CONFIG_TRACE
    if(ins_count % 100000 == 0){
      #ifdef CONFIG_VCD_TRACE
        tfp->close();
        tfp->open("dump.vcd");
      #endif
        reopen_all_log();
    }
  #endif

  #ifdef CONFIG_TRACE
    s.pc   = top->rootp->top__DOT__wb__DOT__pc;
    s.dnpc = top->rootp->top__DOT__wb__DOT__pc_next;
    s.inst = top->rootp->top__DOT__wb__DOT__instruction;

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
    if(top->rootp->top__DOT__wb__DOT__ecall_r == 1){
      exception_log_write("pc is 0x%x, raise intr with exception number is %d\n", s.pc, cpu.gpr[15]);
    }
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

void statistic(){
  Log("clock count: %ld, inst_count : %ld, IPC: %f", clock_count, ins_count, (1.0*ins_count)/clock_count);
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
      // Log("clock count: %d, inst_count : %d, IPC: %f\n", clock_count, ins_count, (1.0*ins_count)/clock_count);
      break;
      // fall through
    case NPC_QUIT: statistic();
    default: break;
  }
}

void assert_fail_msg() {
  isa_reg_display();
  statistic();
}