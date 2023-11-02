#include <isa.h>
#include <cpu/difftest.h>

extern char *regs[];

bool difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {

  if(ref_r->pc != cpu.pc){
    printf("pc is : 0x%8X\n", pc);
    printf("error reg name is : %s \n", "pc");
    printf("DUT pc value is : %x \n", cpu.pc);
    printf("REF reg value is : %x \n", ref_r->pc);
    return false;
  }
  for(int i = 0; i < 32; i++){
    if((ref_r->gpr[i]) != cpu.gpr[i]){
      printf("pc is : 0x%8X\n", pc);
      printf("error reg name is : %s \n", regs[i]);
      printf("DUT reg value is : %x \n", cpu.gpr[i]);
      printf("REF reg value is : %x \n", ref_r->gpr[i]);
      return false;
    }
  }
  return true;
}