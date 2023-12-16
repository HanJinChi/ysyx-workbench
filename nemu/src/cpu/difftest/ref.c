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

#include "common.h"
#include <isa.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>


struct difftest_npc {
  word_t gpr[32];
  word_t mcause;
  vaddr_t mepc;
  word_t mstatus;
  word_t mtvec;
  vaddr_t pc;
  vaddr_t memory_write_addr;
  word_t  memory_write_context;
};

__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  assert(direction == DIFFTEST_TO_REF);
  memcpy(guest_to_host(addr), buf, n);
}

__EXPORT void difftest_regcpy(void *dut, bool direction) {
  struct difftest_npc* npc = (struct difftest_npc*)dut;
  if(direction == DIFFTEST_TO_REF){
    for(int i = 0; i < 32; i++){
      cpu.gpr[i] = npc->gpr[i];
    }
    cpu.csr.mcause = npc->mcause;
    cpu.csr.mepc = npc->mepc;
    cpu.csr.mstatus = npc->mstatus;
    cpu.csr.mtvec = npc->mtvec;
    cpu.pc = npc->pc;
    cpu.memory_write_addr = npc->memory_write_addr;
    cpu.memory_write_context = npc->memory_write_context;
  }else{
    for(int i = 0; i < 32; i++){
      npc->gpr[i] = cpu.gpr[i];
    }
    npc->mcause = cpu.csr.mcause;
    npc->mepc = cpu.csr.mepc;
    npc->mstatus = cpu.csr.mstatus;
    npc->mtvec = cpu.csr.mtvec;
    npc->pc = cpu.pc;
    npc->memory_write_addr = cpu.memory_write_addr;
    npc->memory_write_context = cpu.memory_write_context;
  }
}

__EXPORT void difftest_exec(uint64_t n) {
  cpu_exec(n);
}

__EXPORT void difftest_raise_intr(word_t NO) {
  assert(0);
}

__EXPORT void difftest_init(int port) {
  void init_mem();
  init_mem();
  /* Perform ISA dependent initialization. */
  init_isa();
}
