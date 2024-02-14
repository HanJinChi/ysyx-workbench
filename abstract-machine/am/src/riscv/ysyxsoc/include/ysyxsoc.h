#ifndef YSYXSOC_H__
#define YSYXSOC_H__

#include <riscv.h>
#include <klib-macros.h>

#define DEVICE_BASE 0xa0000000

#define MMIO_BASE 0xa0000000

#define SERIAL_BASE      0x10000000
#define SERIAL_RB        0x0
#define SERIAL_TR        0x0 // LSB
#define SERIAL_IE        0x1 // MSB
#define SERIAL_LC        0x3
#define SERIAL_LS        0x5

#define SPI_BASE         0x10001000
#define SPI_CTRL         0x10
#define SPI_DIVIDER      0x14
#define SPI_SS           0x18

#define FLASH_BASE       0x30000000
#define FLASH_SIZE       0x10000000

#define SRAM_BASE        0xf000000

#define RTC_ADDR        0x2000000
#define VGACTL_ADDR     (DEVICE_BASE + 0x0000100)
#define KBD_ADDR        (DEVICE_BASE + 0x0000060)
#define FB_ADDR         (MMIO_BASE   + 0x1000000)


#endif