#ifndef __DEFINE_H__
#define __DEFINE_H__

// #define CONFIG_VCD_TRACE 1

#define CONFIG_TRACE 1
// #define CONFIG_FTRACE 1
#define CONFIG_MTRACE 1
// #define CONFIG_VTRACE 1
// #define CONFIG_XTRACE 1
#define CONFIG_DIFFTEST 1
// #define CONFIG_WATCHPOINT 1
// #define CONFIG_TARGET_NATIVE_ELF 1
// #define CONFIG_DEVICE 1

// serial
#define CONFIG_HAS_SERIAL 1
#define CONFIG_SERIAL_MMIO 0xa00003f8

// timer
#define CONFIG_HAS_TIMER 1
#define CONFIG_RTC_MMIO 0xa0000048

// vga
#define CONFIG_VGA_SHOW_SCREEN 1
#define CONFIG_VGA_CTL_MMIO 0xa0000100
#define CONFIG_FB_ADDR 0xa1000000
#define CONFIG_HAS_VGA 1
#define CONFIG_VGA_SIZE_400x300 1

// keyboard
#define CONFIG_HAS_KEYBOARD 1
#define CONFIG_I8042_DATA_MMIO 0xa0000060

// nvboard
// #define CONFIG_HAS_NVBOARD 1

#endif