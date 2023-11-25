.section entry, "ax"
.globl _start
.type _start, @function

_start:
  mv s0, zero
  la sp, _stack_pointer
  jal _x
  nop
  nop
_x:
  nop
  jal _trm_init
