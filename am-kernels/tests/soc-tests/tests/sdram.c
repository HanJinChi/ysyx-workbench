#include "trap.h"

int main(){

  intptr_t addr = 0xa0000001;
  uint32_t x = *(volatile uint32_t *)addr;
}