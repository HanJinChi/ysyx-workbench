#include "common.h"
#include <memory/paddr.h>

static const uint32_t img [] = {
  0x00000297,  // auipc t0,0
  0x00000297,  // auipc t0,0
  0x00100073,  // ebreak (used as nemu_trap)
  0xdeadbeef,  // some data
};

void init_isa(){
  /* Load built-in image. */
  memcpy(flash_guest_to_host(FLASH_BASE), img, sizeof(img));
}