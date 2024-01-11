#include "klib-macros.h"
#include "trap.h"

#define FLASH_BASE 0x30000000

#define SPI_BASE         0x10001000
#define SPI_TX_0         0x0
#define SPI_RX_0         0x0  
#define SPI_CTRL         0x10
#define SPI_DIVIDER      0x14
#define SPI_SS           0x18

static inline uint8_t   inb(uintptr_t addr) { return *(volatile uint8_t  *)addr; }
static inline uint16_t  inw(uintptr_t addr) { return *(volatile uint16_t  *)addr; }
static inline uint32_t  inl(uintptr_t addr) { return *(volatile uint32_t  *)addr; }
static inline void      outl(uintptr_t addr, uint32_t data) { *(volatile uint32_t  *)addr = data; }

int main(){
  // TX 
  outl(SPI_BASE+SPI_TX_0, 0xcc); // 8'b11001100
  // DIVIDER
  outl(SPI_BASE+SPI_DIVIDER, 0xff);
  // SS
  outl(SPI_BASE+SPI_SS, 0x80);
  // CTRL
  // [13]  , [12], [11]  , [8]
  // ASS(1)  IE(0) LSB(0)  GO_BSY(1)
  outl(SPI_BASE+SPI_CTRL, 0x910);
  while(((inl(SPI_BASE+SPI_CTRL)>>8)&0x1) == 1);
  uint16_t data = inw(SPI_BASE+SPI_RX_0);
  for(int i = 0; i < 8; i++){
    putch('0'+(((data >> 9)>>i)&0x1));
  }

}