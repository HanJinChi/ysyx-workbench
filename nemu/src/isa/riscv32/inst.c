/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include "local-include/reg.h"
#include <cpu/cpu.h>
#include <cpu/ifetch.h>
#include <cpu/difftest.h>
#include <cpu/decode.h>

#define Reg(i) gpr(i)
#define Mr vaddr_read
#define Mw vaddr_write

enum {
  TYPE_I, TYPE_U, TYPE_S,TYPE_J,TYPE_R,
  TYPE_N, TYPE_B// none
};

void csrrwrs(word_t dest, word_t src1, word_t imm, bool temp){
	word_t t, *ptr = &gpr(0);
	if ( imm == 773 ) {
		ptr = &cpu.csr.mtvec;
	} else if ( imm == 768 ) {
		ptr = &cpu.csr.mstatus;
	} else if ( imm == 833 ) {
		ptr = &cpu.csr.mepc;
	} else if ( imm == 834 ) {
		ptr = &cpu.csr.mcause;
	}

	t = *ptr;
	if ( temp ) {
		*ptr = src1;
	} else {
		*ptr = t | src1;
	}
	gpr(dest) = t;
}

#define src1R()  *src1 = Reg(rs1);
#define src2R()  *src2 = Reg(rs2);
#define immI()  *imm = SEXT(BITS(i, 31, 20), 12); 
#define immU()  *imm = SEXT(BITS(i, 31, 12), 20) << 12; 
#define immS()  *imm = (SEXT(BITS(i, 31, 25), 7) << 5) | BITS(i, 11, 7);
#define immJ()  *imm = SEXT(BITS(i, 31, 31), 1) << 20 | BITS(i, 19, 12) << 12 | BITS(i, 20, 20) << 11 | BITS(i, 30, 21) << 1; 
#define immB()  *imm = SEXT(BITS(i, 31, 31), 1) << 12 | BITS(i, 7, 7) << 11 | BITS(i, 30, 25) << 5 | BITS(i, 11, 8) << 1;

static void decode_operand(Decode *s, int *rd, word_t *src1, word_t *src2, word_t *imm, int type) {
  uint32_t i = s->isa.inst.val;
  int rs1 = BITS(i, 19, 15);
  int rs2 = BITS(i, 24, 20);
  *rd     = BITS(i, 11, 7);
  
  switch (type) {
    case TYPE_I: src1R();          immI(); break;
    case TYPE_U:                   immU(); break;
    case TYPE_S: src1R(); src2R(); immS(); break;
    case TYPE_J:                   immJ(); break;
    case TYPE_R: src1R(); src2R();         break;
    case TYPE_B: src1R(); src2R(); immB(); break;
  }
}

static int decode_exec(Decode *s) {
  int rd = 0;
  word_t src1 = 0, src2 = 0, imm = 0;
  s->dnpc = s->snpc;

#define INSTPAT_INST(s) ((s)->isa.inst.val)
#define INSTPAT_MATCH(s, name, type, ... /* execute body */ ) { \
  decode_operand(s, &rd, &src1, &src2, &imm, concat(TYPE_, type)); \
  __VA_ARGS__ ; \
}

  INSTPAT_START();
  INSTPAT("??????? ????? ????? ??? ????? 00101 11", auipc  , U, Reg(rd) = s->pc + imm); // I
  INSTPAT("??????? ????? ????? ??? ????? 01101 11", lui    , U, Reg(rd) = imm);
  INSTPAT("0000000 ????? ????? 000 ????? 01100 11", add    , R, Reg(rd) = src1 + src2);
  INSTPAT("0100000 ????? ????? 000 ????? 01100 11", sub    , R, Reg(rd) = src1 - src2);
  INSTPAT("0000001 ????? ????? 000 ????? 01100 11", mul    , R, Reg(rd) = src1 * src2); // m
  INSTPAT("0000001 ????? ????? 011 ????? 01100 11", mulhu  , R, Reg(rd) = ((uint64_t)src1 * (uint64_t)src2) >> 32); // m
  INSTPAT("0000001 ????? ????? 100 ????? 01100 11", divx   , R, Reg(rd) = (sword_t)src1 / (sword_t)src2); // m
  INSTPAT("0000001 ????? ????? 101 ????? 01100 11", divu   , R, Reg(rd) = src1 / src2); // m
  INSTPAT("0000001 ????? ????? 110 ????? 01100 11", rem    , R, Reg(rd) = (sword_t)src1 % (sword_t)src2); // m
  INSTPAT("0000001 ????? ????? 111 ????? 01100 11", remu   , R, Reg(rd) = src1 % src2); // m
  INSTPAT("0000000 ????? ????? 010 ????? 01100 11", slt    , R, Reg(rd) = (sword_t)src1 < (sword_t)src2;);
  INSTPAT("0000000 ????? ????? 011 ????? 01100 11", sltu   , R, Reg(rd) = (src1 < src2));
  INSTPAT("0000000 ????? ????? 111 ????? 01100 11", and    , R, Reg(rd) = (src1 & src2));
  INSTPAT("0000000 ????? ????? 100 ????? 01100 11", xor    , R, Reg(rd) = (src1 ^ src2));
  INSTPAT("0000000 ????? ????? 110 ????? 01100 11", or     , R, Reg(rd) = (src1 | src2));
  INSTPAT("0000000 ????? ????? 001 ????? 01100 11", sll    , R, Reg(rd) = src1 << (src2 & 0x1F));
  INSTPAT("0100000 ????? ????? 101 ????? 01100 11", sra    , R, Reg(rd) = (sword_t)src1 >> (src2 & 0x1F));
  INSTPAT("0000000 ????? ????? 101 ????? 01100 11", srl    , R, Reg(rd) = src1 >> (src2 & 0x1F));
  INSTPAT("??????? ????? ????? 000 ????? 01000 11", sb     , S, Mw(src1 + imm, 1, src2));
  INSTPAT("??????? ????? ????? 001 ????? 01000 11", sh     , S, Mw(src1 + imm, 2, src2));
  INSTPAT("??????? ????? ????? 010 ????? 01000 11", sw     , S, Mw(src1 + imm, 4, src2));
  INSTPAT("010000? ????? ????? 101 ????? 00100 11", srai   , I, if(((imm >> 5) & 1) == 0) Reg(rd) = ((sword_t)src1) >> (imm & 0x1F););
  INSTPAT("000000? ????? ????? 001 ????? 00100 11", slli   , I, if(((imm >> 5) & 1) == 0) Reg(rd) = src1 << (imm & 0x1F););
  INSTPAT("000000? ????? ????? 101 ????? 00100 11", srli   , I, if(((imm >> 5) & 1) == 0) Reg(rd) = src1 >> (imm & 0x1F););
  INSTPAT("??????? ????? ????? 010 ????? 00100 11", slti   , I, Reg(rd) = (sword_t)src1 < (sword_t)imm;);
  INSTPAT("??????? ????? ????? 011 ????? 00100 11", sltiu  , I, Reg(rd) = src1 < imm;);
  INSTPAT("??????? ????? ????? 000 ????? 00100 11", addi   , I, Reg(rd) = src1 + imm);
  INSTPAT("??????? ????? ????? 110 ????? 00100 11", ori    , I, Reg(rd) = (src1 | imm));
  INSTPAT("??????? ????? ????? 111 ????? 00100 11", andi   , I, Reg(rd) = src1 & imm);
  INSTPAT("??????? ????? ????? 100 ????? 00100 11", xori   , I, Reg(rd) = src1 ^ imm);
  INSTPAT("??????? ????? ????? 010 ????? 00000 11", lw     , I, Reg(rd) = Mr(src1 + imm, 4));
  INSTPAT("??????? ????? ????? 000 ????? 00000 11", lb     , I, Reg(rd) = SEXT(Mr(src1 + imm, 1), 8));
  INSTPAT("??????? ????? ????? 001 ????? 00000 11", lh     , I, Reg(rd) = SEXT(Mr(src1 + imm, 2), 16));
  INSTPAT("??????? ????? ????? 101 ????? 00000 11", lhu    , I, Reg(rd) = Mr(src1 + imm, 2));
  INSTPAT("??????? ????? ????? 100 ????? 00000 11", lbu    , I, Reg(rd) = Mr(src1 + imm, 1));
  INSTPAT("??????? ????? ????? 111 ????? 11000 11", bgeu   , B, if(src1 >= src2) s->dnpc = s->pc + imm);
  INSTPAT("??????? ????? ????? 000 ????? 11000 11", beq    , B, if(src1 == src2) s->dnpc = s->pc + imm);
  INSTPAT("??????? ????? ????? 101 ????? 11000 11", bge    , B, if((sword_t)src1 >= (sword_t)src2) s->dnpc = s->pc + imm);
  INSTPAT("??????? ????? ????? 100 ????? 11000 11", blt    , B, if((sword_t)src1  < (sword_t)src2) s->dnpc = s->pc + imm);
  INSTPAT("??????? ????? ????? 110 ????? 11000 11", bltu   , B, if(src1  < src2) s->dnpc = s->pc + imm);
  INSTPAT("??????? ????? ????? 001 ????? 11000 11", bne    , B, if(src1 != src2) s->dnpc = s->pc + imm);
  INSTPAT("??????? ????? ????? ??? ????? 11011 11", jal    , J, Reg(rd) = s->pc + 4; s->dnpc = s->pc + imm);
  INSTPAT("??????? ????? ????? 000 ????? 11001 11", jalr   , I, Reg(rd) = s->pc + 4; s->dnpc = (src1 + imm)&(~1););
  INSTPAT("??????? ????? ????? 010 ????? 11100 11", csrrs  , I, csrrwrs(rd, src1, imm, false););
  INSTPAT("??????? ????? ????? 001 ????? 11100 11", csrrw  , I, csrrwrs(rd, src1, imm, true););
  INSTPAT("0000000 00000 00000 000 00000 11100 11", ecall  , I, s->dnpc = isa_raise_intr(Reg(17), s->pc); difftest_skip_ref();); // R(17) is $a17
  INSTPAT("0011000 00010 00000 000 00000 11100 11", mret   , R, s->dnpc = cpu.csr.mepc; difftest_skip_ref(););
  INSTPAT("0000000 00001 00000 000 00000 11100 11", ebreak , N, NEMUTRAP(s->pc, Reg(10))); // R(10) is $a0
  INSTPAT("??????? ????? ????? ??? ????? ????? ??", inv    , N, INV(s->pc));
  INSTPAT_END();

  Reg(0) = 0; // reset $zero to 0

  return 0;
}

int isa_exec_once(Decode *s) {
  s->isa.inst.val = inst_fetch(&s->snpc, 4);
  return decode_exec(s);
}
