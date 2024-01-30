#include "trap.h"

int main(){

  intptr_t addr = 0x80300000;
  for(int i = 0; i < 0x100; i++){
    *(volatile uint8_t*)(addr+i) = i;
  }
  for(int i = 0; i < 0x100; i++){
    uint8_t data = *(volatile uint8_t*)(addr+i);
    if(data == i)
      printf("Y");
    else
      printf("N");
  }
  for(int i = 0; i < 0x100; i++){
    *(volatile uint16_t*)(addr+i*2) = i;
  }
  for(int i = 0; i < 0x100; i++){
    uint16_t data = *(volatile uint16_t*)(addr+i*2);
    if(data == i)
      printf("Y");
    else
      printf("N");
  }
}