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

#ifndef __MEMORY_PADDR_H__
#define __MEMORY_PADDR_H__

#include <common.h>

#define PMEM_LEFT  ((paddr_t)CONFIG_MBASE)
#define PMEM_RIGHT ((paddr_t)CONFIG_MBASE + CONFIG_MSIZE - 1)
#define RESET_VECTOR (PMEM_LEFT + CONFIG_PC_RESET_OFFSET)

/* convert the guest physical address in the guest program to host virtual address in NEMU */
uint8_t* guest_to_host(paddr_t paddr);
/* convert the host virtual address in NEMU to guest physical address in the guest program */
paddr_t host_to_guest(uint8_t *haddr);

static inline bool in_pmem(paddr_t addr) {
  return addr - CONFIG_MBASE < CONFIG_MSIZE;
}

word_t paddr_read(paddr_t addr, int len);
void paddr_write(paddr_t addr, int len, word_t data);

#define PMROM_LEFT  ((paddr_t)CONFIG_MROM_MBASE)
#define PMROM_RIGHT ((paddr_t)CONFIG_MROM_MBASE + CONFIG_MROM_SIZE - 1)
#define MROM_RESET_VECTOR (PMROM_LEFT + CONFIG_PC_RESET_OFFSET)

/* convert the guest physical address in the guest program to host virtual address in NPC */
uint8_t* mrom_guest_to_host(paddr_t paddr);
/* convert the host virtual address in NPC to guest physical address in the guest program */
paddr_t mrom_host_to_guest(uint8_t *haddr);

static inline bool in_mrom(paddr_t addr) {
  return addr - CONFIG_MROM_MBASE < CONFIG_MROM_SIZE;
}

#define PSRAM_LEFT  ((paddr_t)CONFIG_SRAM_MBASE)
#define PSRAM_RIGHT ((paddr_t)CONFIG_SRAM_MBASE + CONFIG_SRAM_SIZE - 1)

/* convert the guest physical address in the guest program to host virtual address in NPC */
uint8_t* mrom_guest_to_host(paddr_t paddr);
/* convert the host virtual address in NPC to guest physical address in the guest program */
paddr_t mrom_host_to_guest(uint8_t *haddr);

static inline bool in_sram(paddr_t addr) {
  return addr - CONFIG_SRAM_MBASE < CONFIG_SRAM_SIZE;
}

#endif
