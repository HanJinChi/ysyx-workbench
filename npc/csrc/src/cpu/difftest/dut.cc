#include "common.h"
#include <dlfcn.h>
#include <isa.h>
#include <cpu/cpu.h>
#include <memory/paddr.h>
#include <difftest-def.h>
#include <utils.h>
#include <cpu/difftest.h>


void (*ref_difftest_memcpy)(paddr_t, void* buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;


#ifdef CONFIG_DIFFTEST

static bool is_skip_ref = false;
static bool skip_difftest = false;
// static int skip_dut_nr_inst = 0;
char* so_file;

void difftest_skip_ref(){
  is_skip_ref = true;
}

void difftest_detach(){
  skip_difftest = true;
}

void difftest_attach(){
  skip_difftest = false;

  ref_difftest_memcpy(PFLASH_LEFT, flash_guest_to_host(PFLASH_LEFT), FLASH_SIZE, DIFFTEST_TO_REF);

  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

void init_difftest(char *ref_so_file, long img_size, int port){
  assert(ref_so_file != NULL);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = (void (*)(paddr_t, void*, size_t, bool))dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (void (*)(void*, bool))dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (void (*)(uint64_t))dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (void (*)(uint64_t))dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  void (*ref_difftest_init)(int) = (void (*)(int))dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  ref_difftest_init(port);
  ref_difftest_memcpy(PFLASH_LEFT, flash_guest_to_host(PFLASH_LEFT), img_size, DIFFTEST_TO_REF);
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

static void checkregs(CPU_state *ref, vaddr_t pc) {
  if (!difftest_checkregs(ref, pc)) {
    npc_state.state = NPC_ABORT;
    npc_state.halt_pc = pc;
    isa_reg_display();
    // cpu_exit();
  }
}

void difftest_step(vaddr_t pc, vaddr_t npc){
  CPU_state ref_r;
  if(skip_difftest) return;

  if(is_skip_ref){
    // to skip the checking of an instruction, just copy the reg state to reference design
    ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
    is_skip_ref = false;
  }
  else{
    ref_difftest_exec(1);
    ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);

    checkregs(&ref_r, pc);
  }
}

#endif