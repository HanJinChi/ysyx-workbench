/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include "local-include/reg.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void isa_reg_display() {
  printf("%-15s 0x%-15x %-15d\n", "pc", cpu.pc, cpu.pc);
  printf("%-15s 0x%-15x %-15d\n", "mstatus", cpu.csr.mstatus, cpu.csr.mstatus);
  printf("%-15s 0x%-15x %-15d\n", "mepc", cpu.csr.mepc, cpu.csr.mepc);
  printf("%-15s 0x%-15x %-15d\n", "mcause", cpu.csr.mcause, cpu.csr.mcause);
  printf("%-15s 0x%-15x %-15d\n", "mtvec", cpu.csr.mtvec, cpu.csr.mtvec);
  for(int i = 0 ; i < sizeof(regs)/sizeof(regs[0]); i++){
    printf("%-15s 0x%-15x %-15d\n", regs[i], cpu.gpr[i], cpu.gpr[i]);
  }

}

word_t isa_reg_str2val(const char *s, bool *success) {
  if(strcmp("pc", s) == 0){
    *success = true;
    return cpu.pc;
  }
  for(int i = 0 ; i < sizeof(regs)/sizeof(regs[0]); i++){
    if(strcmp(regs[i], s) == 0){
      *success = true;
      return cpu.gpr[i];
    }
  }
  *success = false;
  return 0;
}
