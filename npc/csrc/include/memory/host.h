
#ifndef __MEMORY_HOST_H__
#define __MEMORY_HOST_H__

#include <common.h>
#include <cstdint>

static inline word_t host_read(void *addr, int len) {
  switch (len) {
    case 1: return *(uint8_t  *)addr;
    case 2: return *(uint16_t *)addr;
    case 4: return *(uint32_t *)addr;
    default: return 0;
  }
}

static inline void host_write(void *addr, int len, word_t data) {
  switch (len) {
    case 1: *(uint8_t  *)addr = data; return;
    case 2: *(uint16_t *)addr = data; return;
    case 3: *(uint16_t *)addr = data & 0xffff; *(uint8_t *)((uintptr_t)addr+2) = (data >> 16) & 0xff; return;
    case 4: *(uint32_t *)addr = data; return;
    default: assert(0);
  }
}

#endif
