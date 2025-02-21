#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>

extern char _heap_start;
extern char _boot_begin;
extern char _boot_end;
extern char _ssbl;
int main(const char *args);

// #define PMEM_SIZE (8 * 1024 * 1024)
// #define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

#define HEAP_SIZE (2 * 1024 * 1024)
#define HEAP_END ((uintptr_t)&_heap_start- (SDRAM_BASE - FLASH_BASE) + HEAP_SIZE)

Area heap = RANGE((uintptr_t)&_heap_start - (SDRAM_BASE - FLASH_BASE), HEAP_END);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

void putch(char ch) {
  while((inb(SERIAL_BASE+SERIAL_LS) & 0x20) != (0x20)); // wait fifo is empty
  outb(SERIAL_BASE+SERIAL_RB, ch);
}

void uart_init(){
  uint8_t init_value = inb(SERIAL_BASE+SERIAL_LC);
  outb(SERIAL_BASE+SERIAL_LC, init_value | 0x80); // 最高位设为1,代表可以设置除数（波特率）
  outb(SERIAL_BASE+SERIAL_IE, 0x00);              // 设置波特率
  outb(SERIAL_BASE+SERIAL_TR, 0x1);               // 设置波特率
  outb(SERIAL_BASE+SERIAL_FC, 0b11000110);      // 设置fifo深度
  outb(SERIAL_BASE+SERIAL_LC, init_value);        // 恢复初始位
}


// 在flash中执行，负责将bootloader从flash迁移至psram中
void fsbl(){
  char* src = &_boot_begin;
  char* dst = (char*)((uintptr_t)&_boot_begin - FLASH_BASE + SDRAM_BASE);

  for(int i = 0; i < (uintptr_t)&_boot_end - (uintptr_t)&_boot_begin; i++){
    dst[i] = src[i];
  }
  asm volatile("fence.i"); // sync icache and dcache
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code)); // ebreak
  // never run here
  while (1);
}

void _trm_init() {
  fsbl();
  ((void (*)())((uintptr_t)&_ssbl-FLASH_BASE+SDRAM_BASE))();
  uart_init();
  int ret = (*(int(*)(const char *args))((uintptr_t)&main+SDRAM_BASE-FLASH_BASE))(mainargs);
  halt(ret);
}
