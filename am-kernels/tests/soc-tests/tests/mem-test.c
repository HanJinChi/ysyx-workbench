#include "trap.h"

int main(){
  int len = 0x10;
  intptr_t addr = 0x80400000;
  for(int j = 0; j < 1; j++){
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
    addr = addr + 0;
  }
}