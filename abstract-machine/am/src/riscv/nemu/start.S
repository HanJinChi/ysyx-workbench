.section entry, "ax"
.globl _start
.type _start, @function

_start:
  mv s0, zero
  sb  zero,18(t0)
  la sp, _stack_pointer
  jal _trm_init
