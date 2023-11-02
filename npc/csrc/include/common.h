#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdint.h>
#include <string.h>
#include <macro.h>
#include <stdlib.h>
#include <stdio.h>
#include <debug.h>
#include <define.h>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <Vtop.h>
#include <Vtop___024root.h>
#include <Vtop__Syms.h>

#include <assert.h>

#define MBASE 0x80000000
#define MSIZE 0x8000000
#define PC_RESET_OFFSET 0x0


typedef uint32_t word_t;
typedef int32_t  sword_t;
#define FMT_WORD "0x%08x"

typedef word_t   vaddr_t;

typedef uint32_t paddr_t;



#endif