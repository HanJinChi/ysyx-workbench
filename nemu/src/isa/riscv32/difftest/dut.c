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
#include <cpu/difftest.h>
#include "../local-include/reg.h"

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {

  if(ref_r->pc != cpu.pc){
    printf("pc is : 0x%8X\n", pc);
    printf("error reg name is : %s \n", "pc");
    printf("DUT pc value is : %x \n", cpu.pc);
    printf("REF pc value is : %x \n", ref_r->pc);
    return false;
  }
  if(ref_r->csr.mstatus != cpu.csr.mstatus){
    // printf("pc is : 0x%8X\n", pc);
    // printf("error reg name is : %s \n", "mstatus");
    // printf("DUT mstatus value is : %x \n", cpu.csr.mstatus);
    // printf("REF mstatus value is : %x \n", ref_r->csr.mstatus);
    // return false;
  }
  if(ref_r->csr.mepc != cpu.csr.mepc){
    printf("pc is : 0x%8X\n", pc);
    printf("error reg name is : %s \n", "mepc");
    printf("DUT mepc value is : %x \n", cpu.csr.mepc);
    printf("REF mpec value is : %x \n", ref_r->csr.mepc);
    return false;
  }
  if( ref_r->csr.mcause != cpu.csr.mcause){
    // printf("pc is : 0x%8X\n", pc);
    // printf("error reg name is : %s \n", "mcause");
    // printf("DUT mcause value is : %x \n", cpu.csr.mcause);
    // printf("REF mcause value is : %x \n", ref_r->csr.mcause);
  }
  if(ref_r->csr.mtvec != cpu.csr.mtvec){
    printf("pc is : 0x%8X\n", pc);
    printf("error reg name is : %s \n", "mtvec");
    printf("DUT mtvec value is : %x \n", cpu.csr.mtvec);
    printf("REF mtvec value is : %x \n", ref_r->csr.mtvec);
    return false;
  }
  for(int i = 0; i < 32; i++){
    if((ref_r->gpr[i]) != gpr(i)){
      if((ref_r->csr.mcause == ref_r->gpr[i]) && (gpr(i) == cpu.csr.mcause)){

      }
      else{
        printf("pc is : 0x%8X\n", pc);
        printf("error reg name is : %s \n", reg_name(i));
        printf("DUT reg value is : %x \n", gpr(i));
        printf("REF reg value is : %x \n", ref_r->gpr[i]);
        return false;
      }

    }
  }
  
  return true;
}

void isa_difftest_attach() {
}
