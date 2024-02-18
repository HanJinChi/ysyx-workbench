#include <memory/host.h>
#include <memory/paddr.h>
#include <isa.h>
#include <device/mmio.h>
#include <common.h>

extern CPU_state cpu;
extern VysyxSoCFull* top;

static uint8_t pmem[MSIZE] = {};
static uint8_t pflash[FLASH_SIZE] = {};

extern void cpu_exit();

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + MBASE; }

uint8_t* flash_guest_to_host(paddr_t paddr) { return pflash + paddr - FLASH_BASE; }
paddr_t flash_host_to_guest(uint8_t *haddr) { return haddr - pflash + FLASH_BASE; }

static word_t flash_read(paddr_t addr, int len) {
  word_t ret = host_read(flash_guest_to_host(addr), len);
  return ret;
}

static void flash_write(paddr_t addr, int len, word_t data) {
  host_write(flash_guest_to_host(addr), len, data);
}

word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
  #ifdef CONFIG_DIFFTEST
    cpu.memory_write_addr    = addr;
    switch(len){
      case 1: cpu.memory_write_context = data & 0xFF; break;
      case 2: cpu.memory_write_context = data & 0xFFFF; break;
      case 4: cpu.memory_write_context = data; break;
      default: cpu.memory_write_context = data;
    }
  #endif
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
    if(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__arb__DOT__araddrMux == 2){ // 取值
      memory_log_write("pc is 0x%x, from address 0x%x read %d byte: 0x%x\n", top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ls__DOT__pc_v, addr, len, data); 
    }else{
      memory_log_write("pc is 0x%x, from address 0x%x read %d byte: 0x%x\n", addr, addr, len, data);
    }
  #endif
    return data;
  }
  if(in_flash(addr)){
    word_t data = flash_read(addr, len);
  #ifdef CONFIG_MTRACE
    if(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__arb__DOT__araddrMux == 2){ // 取值
      memory_log_write("pc is 0x%x, from address 0x%x read %d byte: 0x%x\n", top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ls__DOT__pc_v, addr, len, data); 
    }else{
      memory_log_write("pc is 0x%x, from address 0x%x read %d byte: 0x%x\n", addr, addr, len, data);
    }
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
    memory_log_write("pc is 0x%x, to address 0x%x write %d byte: 0x%x\n", top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ls__DOT__pc_v, addr, len, (len == 4) ? data : ((len == 1) ? (data & 0xFF) : (data & 0xFFFF)));
  #endif
    return; 
  }
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}

void init_flash(){
  for(int i = 0; i < FLASH_SIZE/4; i++){
    flash_write(FLASH_BASE+i*4, 4, FLASH_BASE+i*4);
  }
}