#include "trap.h"

#define FLASH_BASE 0x30000000
#define FLASH_SIZE 0x1000

static inline uint32_t  inw(uintptr_t addr) { return *(volatile uint32_t  *)addr; }

int main(){
  for(int i = 0; i < FLASH_SIZE/4; i++){
    check(inw(FLASH_BASE+i) == (FLASH_BASE+i));
  }
}