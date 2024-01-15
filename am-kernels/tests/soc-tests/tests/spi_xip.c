#include "am.h"
#include "trap.h"

#define FLASH_BASE 0x30000000
#define FLASH_SIZE 0x10000000

static inline uint32_t  inl(uintptr_t addr) { return *(volatile uint32_t  *)addr; }

uint32_t flash_data_rev(uint32_t data){
  uint32_t num = 0;
  for(int i = 0; i < 4; i++){
    for(int j = 7; j >= 0; j--){
      int bit = (data >> (i*8+j)) & 0x1;
      num = num | (bit << (i*8 + (7-j)));
    }
  }
  return num;
}

int main(){
    for(int i = 0; i < FLASH_SIZE/4; i++){
        if(flash_data_rev(inl(FLASH_BASE + i*4)) == (FLASH_BASE+i*4))
            putch('Y');
        else
            putch('N');
    }

}