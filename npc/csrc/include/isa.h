#ifndef __ISA_H__
#define __ISA_H__

#include <common.h>

void isa_reg_display();
word_t isa_reg_str2val(const char *name, bool *success);

typedef struct{
  word_t mcause;
  vaddr_t mepc;
  word_t mstatus;
  word_t mtvec;
}riscv32_CPU_CSR;

typedef struct {
  word_t gpr[32];
  riscv32_CPU_CSR csr;
  vaddr_t pc;
  vaddr_t memory_write_addr;
  word_t  memory_write_context;
}CPU_state;


extern CPU_state cpu;

bool difftest_checkregs(CPU_state *ref_r, vaddr_t pc);


#endif