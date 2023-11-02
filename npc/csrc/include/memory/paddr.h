
#ifndef __MEMORY_PADDR_H__
#define __MEMORY_PADDR_H__

#include <common.h>

#define PMEM_LEFT  ((paddr_t)MBASE)
#define PMEM_RIGHT ((paddr_t)MBASE + MSIZE - 1)
#define RESET_VECTOR (PMEM_LEFT + PC_RESET_OFFSET)

/* convert the guest physical address in the guest program to host virtual address in NPC */
uint8_t* guest_to_host(paddr_t paddr);
/* convert the host virtual address in NPC to guest physical address in the guest program */
paddr_t host_to_guest(uint8_t *haddr);

static inline bool in_pmem(paddr_t addr) {
  return addr - MBASE < MSIZE;
}

word_t paddr_read(paddr_t addr, int len);
void paddr_write(paddr_t addr, int len, word_t data);

#endif
