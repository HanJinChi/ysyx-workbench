#include <isa.h>
#include <cpu/difftest.h>

extern char *regs[];

bool difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {

  if(ref_r->pc != cpu.pc){
    printf("pc is : 0x%8X\n", pc);
    printf("error reg name is : %s \n", "pc");
    printf("DUT pc value is : 0x%x \n", cpu.pc);
    printf("REF reg value is : 0x%x \n", ref_r->pc);
    return false;
  }
  if(ref_r->csr.mcause != cpu.csr.mcause){
    printf("pc is : 0x%8X\n", pc);
    printf("error reg name is : %s \n", "mcause");
    printf("DUT reg value is : 0x%x \n", cpu.csr.mcause);
    printf("REF reg value is : 0x%x \n", ref_r->csr.mcause);
    return false;
  }
  if(ref_r->csr.mepc != cpu.csr.mepc){
    printf("pc is : 0x%8X\n", pc);
    printf("error reg name is : %s \n", "mepc");
    printf("DUT reg value is : 0x%x \n", cpu.csr.mepc);
    printf("REF reg value is : 0x%x \n", ref_r->csr.mepc);
    return false;
  }
  if(ref_r->csr.mstatus != cpu.csr.mstatus){
    printf("pc is : 0x%8X\n", pc);
    printf("error reg name is : %s \n", "mstatus");
    printf("DUT reg value is : 0x%x \n", cpu.csr.mstatus);
    printf("REF reg value is : 0x%x \n", ref_r->csr.mstatus);
    return false;
  }
  if(ref_r->csr.mtvec != cpu.csr.mtvec){
    printf("pc is : 0x%8X\n", pc);
    printf("error reg name is : %s \n", "mtvec");
    printf("DUT reg value is : 0x%x \n", cpu.csr.mtvec);
    printf("REF reg value is : 0x%x \n", ref_r->csr.mtvec);
    return false;
  }
  for(int i = 0; i < 32; i++){
    if((ref_r->gpr[i]) != cpu.gpr[i]){
      printf("pc is : 0x%8X\n", pc);
      printf("error reg name is : %s \n", regs[i]);
      printf("DUT reg value is : 0x%x \n", cpu.gpr[i]);
      printf("REF reg value is : 0x%x \n", ref_r->gpr[i]);
      return false;
    }
  }
  if(ref_r->memory_write_addr != cpu.memory_write_addr){
    printf("pc is : 0x%8X\n", pc);
    printf("error memory write addr\n");
    printf("DUT memory write addr is : 0x%x \n", cpu.memory_write_addr);
    printf("REF memory write addr : 0x%x \n", ref_r->memory_write_addr);
    return false;
  }
  if(ref_r->memory_write_context != cpu.memory_write_context){
    printf("pc is : 0x%8X\n", pc);
    printf("error memory write context\n");
    printf("DUT memory write context is : 0x%x \n", cpu.memory_write_context);
    printf("REF memory write context is : 0x%x \n", ref_r->memory_write_context);
    return false;
  }
  return true;
}