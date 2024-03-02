.section boot, "ax"
.globl _ssbl
.type _ssbl, @function

_ssbl:
  addi sp, sp, -28
  sw a0,0(sp)
  sw a1,4(sp)
  sw a2,8(sp)
  sw a3,12(sp)
  sw a4,16(sp)
  sw s0,20(sp)
  sw s1,24(sp)

  la s0, _boot_begin
  la s1, _boot_end
  la a0, _data_begin
  la a1, _data_begin
  la a2, _data_end
  li a3, 0xa0000000
  li a4, 0x30000000

  sub a0,a0,a3
  add a0,a0,a4
loopA:
  lw a3, 0(a0)
  addi a1,a1,4
  addi a0,a0,4
  sw  a3, -4(a1)

  bleu a1,a2,loopA

  la a0, _text_begin
  la a1, _text_begin
  la a2, _text_end
  li a3, 0xa0000000
  sub a0,a0,a3
  add a0,a0,a4

loopB:
  bleu a1,s0,lw
  bleu s1,a1,lw
  beqz zero,skip
lw:

  lw  a3, 0(a0)
  sw  a3, 0(a1)
skip:
  addi a1,a1,4
  addi a0,a0,4
  bne a1,a2,loopB

  lw a0,0(sp)
  lw a1,4(sp)
  lw a2,8(sp)
  lw a3,12(sp)
  lw a4,16(sp)
  lw s0,20(sp)
  lw s1,24(sp)

  addi sp,sp,28
  ret