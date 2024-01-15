#ifndef NEMUSOC_H__
#define NEMUSOC_H__

#include <riscv.h>
#include <klib-macros.h>

#define DEVICE_BASE 0xa0000000

#define MMIO_BASE 0xa0000000

#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)

#define RTC_ADDR        (DEVICE_BASE + 0x0000048)
#define VGACTL_ADDR     (DEVICE_BASE + 0x0000100)
#define KBD_ADDR        (DEVICE_BASE + 0x0000060)
#define FB_ADDR         (MMIO_BASE   + 0x1000000)


#endif