#include <memory/paddr.h>

static const uint32_t img [] = {
  0x00000297,  // auipc t0,0
  0x00a00713,  // li  a4,10     
  // 0x00028823,   // sb  zero,16(t0)
  // 0x0102c503,   // lbu a0,16(t0)
  0x00050793,  // mv	a5,a0
  0x00058693,  // mv	a3,a1
  0x00028823,  // sb  zero,16(t0)
  0x00060713,  // mv	a2,a4
  0x00100073,  // ebreak (used as nemu_trap)
  0xdeadbeef,  // some data
};

void init_isa(){
  /* Load built-in image. */
  memcpy(guest_to_host(RESET_VECTOR), img, sizeof(img));
}