#include <am.h>
#include <klib-macros.h>
#include <nemusoc.h>

extern char _heap_start;
extern char _sram_data_begin;
extern char _data_begin;
extern char _data_end;
extern char _rom_data_begin;
int main(const char *args);

// #define PMEM_SIZE (8 * 1024 * 1024)
// #define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

#define HEAP_SIZE (4 * 1024)
#define HEAP_END ((uintptr_t)&_heap_start + HEAP_SIZE)

Area heap = RANGE(&_heap_start, HEAP_END);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

void putch(char ch) {
  outb(SERIAL_PORT, ch);
}

void bootloader(){
  char* dst = &_sram_data_begin;
  char* src = &_rom_data_begin;

  for(int i = 0; i < (uintptr_t)&_data_end - (uintptr_t)&_data_begin; i++){
    dst[i] = src[i];
  }
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code)); // ebreak
  // never run here
  while (1);
}

void _trm_init() {
  bootloader();
  int ret = main(mainargs);
  halt(ret);
}
