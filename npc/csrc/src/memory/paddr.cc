#include <memory/host.h>
#include <memory/paddr.h>
#include <isa.h>
#include <device/mmio.h>
#include <common.h>

extern CPU_state cpu;

static uint8_t pmem[MSIZE] = {};

extern void cpu_exit();

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + MBASE; }

word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

void init_mem() {
  
}

void out_of_bound(paddr_t addr) {
  panic("address = " FMT_WORD " is out of bound of pmem [" FMT_WORD ", " FMT_WORD "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}


word_t paddr_read(paddr_t addr, int len) {
  if (in_pmem(addr)) {
    word_t data = pmem_read(addr, len);
  #ifdef CONFIG_MTRACE 
    memory_log_write("pc is 0x%x, from address 0x%x read %d byte: 0x%x\n", cpu.pc, addr, len, data);
  #endif
    return data;
  }
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  if (in_pmem(addr)) { 
    pmem_write(addr, len, data); 
  #ifdef CONFIG_MTRACE 
    memory_log_write("pc is 0x%x, to address 0x%x write %d byte: 0x%x\n", cpu.pc, addr, len, data);
  #endif
    return; 
  }
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}
