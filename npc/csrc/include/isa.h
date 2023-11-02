#ifndef __ISA_H__
#define __ISA_H__

#include <common.h>

void isa_reg_display();
word_t isa_reg_str2val(const char *name, bool *success);

typedef struct {
    word_t gpr[32];
    vaddr_t pc;
}CPU_state;


extern CPU_state cpu;

bool difftest_checkregs(CPU_state *ref_r, vaddr_t pc);


#endif