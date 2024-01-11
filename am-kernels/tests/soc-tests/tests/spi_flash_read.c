#include "klib-macros.h"
#include "trap.h"

#define FLASH_BASE 0x30000000
#define FLASH_SIZE 0x10000000
#define SPI_BASE         0x10001000
#define SPI_TX_0         0x0
#define SPI_RX_0         0x0  
#define SPI_RX_1         0x4 
#define SPI_CTRL         0x10
#define SPI_DIVIDER      0x14
#define SPI_SS           0x18

static inline uint8_t   inb(uintptr_t addr) { return *(volatile uint8_t  *)addr; }
static inline uint16_t  inw(uintptr_t addr) { return *(volatile uint16_t  *)addr; }
static inline uint32_t  inl(uintptr_t addr) { return *(volatile uint32_t  *)addr; }
static inline void      outl(uintptr_t addr, uint32_t data) { *(volatile uint32_t  *)addr = data; }

uint32_t bitrev(uint32_t num){
  unsigned int result = 0;
  int i;
  for (i = 0; i < 24; i++) {
    result <<= 1; 
    if (num & 1) { 
      result |= 1; 
    }
    num >>= 1; 
  }
  return result;
}

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

uint32_t flash_read(uint32_t addr){
  // TX 
  outl(SPI_BASE+SPI_TX_0, (bitrev(addr&0xffffff)<<8)+0xc0); 
  // DIVIDER
  outl(SPI_BASE+SPI_DIVIDER, 0x10);
  // SS
  outl(SPI_BASE+SPI_SS, 0x01);
  // CTRL
  outl(SPI_BASE+SPI_CTRL, 0x2940);

  while(((inl(SPI_BASE+SPI_CTRL)>>8)&0x1) == 1);

  uint32_t data = inl(SPI_BASE+SPI_RX_1);

  outl(SPI_BASE+SPI_CTRL, 0x0);

  return flash_data_rev(data);
}

int main(){
    for(int i = 1; i < FLASH_SIZE/4; i++){
      if(flash_read(FLASH_BASE+i*4) == (FLASH_BASE+i*4))
        putch('Y');
      else
        putch('N');
    }
}