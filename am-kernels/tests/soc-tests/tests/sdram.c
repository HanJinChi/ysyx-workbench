#include "trap.h"

int main(){

  // intptr_t addr = 0xa0000300;
  // *(volatile uint16_t *)addr = (0x5678);

  // uint16_t data = *(volatile uint16_t*)addr;
  // printf("read data is 0x%x\n", data);
  int len = 0x10;
  intptr_t addr = 0xa0000000;
  for(int j = 0; j < 4; j++){
    addr = addr + 1;
    printf("addr is 0x%x:", addr);
    for(int i = 0; i < len; i++){
      *(volatile uint8_t*)(addr+i) = i;
    }
    for(int i = 0; i < len; i++){
      uint8_t data = *(volatile uint8_t*)(addr+i);
      if(data == i)
        printf("Y");
      else
        printf("N");
    }
    for(int i = 0; i < len; i++){
      *(volatile uint16_t*)(addr+i*2) = i;
    }
    for(int i = 0; i < len; i++){
      uint16_t data = *(volatile uint16_t*)(addr+i*2);
      if(data == i)
        printf("Y");
      else
        printf("N");
    }

    for(int i = 0; i < len; i++){
      *(volatile uint32_t*)(addr+i*4) = i;
    }
    for(int i = 0; i < len; i++){
      uint32_t data = *(volatile uint32_t*)(addr+i*4);
      if(data == i)
        printf("Y");
      else
        printf("N");
    }
    printf("\n");
  }

}