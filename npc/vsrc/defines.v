// define alu TYPE

`define YSYX_23060059_IMM         5'b00000
`define YSYX_23060059_ADD         5'b00001
`define YSYX_23060059_SUB         5'b00010
`define YSYX_23060059_AND         5'b00011
`define YSYX_23060059_XOR         5'b00100
`define YSYX_23060059_OR          5'b00101
`define YSYX_23060059_SL          5'b00110 // <<, unsigned
`define YSYX_23060059_SR          5'b00111 // >>, unsigned 
`define YSYX_23060059_DIV         5'b01000 // >=, unsigned
`define YSYX_23060059_SSR         5'b01001 // >>, signed
`define YSYX_23060059_SLES        5'b01010 // <, signed
`define YSYX_23060059_ULES        5'b01011 // <, unsigned
`define YSYX_23060059_REMU        5'b01100 // %, unsigned
`define YSYX_23060059_MUL         5'b01101 // *, unsigned 
`define YSYX_23060059_DIVU        5'b01110 // /, unsigned
`define YSYX_23060059_REM         5'b01111 
`define YSYX_23060059_SRC         5'b10000 
`define YSYX_23060059_MULHU       5'b10001 // *, unsigned, mulhu


// define instruction TYPE
`define YSYX_23060059_TYPE_I      3'b000
`define YSYX_23060059_TYPE_U      3'b001
`define YSYX_23060059_TYPE_S      3'b010
`define YSYX_23060059_TYPE_J      3'b011
`define YSYX_23060059_TYPE_B      3'b100
`define YSYX_23060059_TYPE_R      3'b101
`define YSYX_23060059_TYPE_V      3'b110

`define YSYX_23060059_CLINT_L     32'h0200_0000 
`define YSYX_23060059_CLINT_H     32'h0200_0004 

`define YSYX_23060059_UART_L      32'h1000_0000
`define YSYX_23060059_UART_H      32'h1000_0010

`define YSYX_23060059_GPIO_LED    32'h1000_2000
`define YSYX_23060059_GPIO_SWITCH 32'h1000_2004
`define YSYX_23060059_GPIO_SEG    32'h1000_2008

`define YSYX_23060059_GPIO_L    32'h1000_2000
`define YSYX_23060059_GPIO_H    32'h1000_2008


`define YSYX_23060059_KEY_L    32'h1001_1000
`define YSYX_23060059_KEY_H    32'h1001_1007

// 
`define YSYX_23060059_ADDR_WIDTH  32


// // icache config 
// `define YSYX_23060059_CA_NSET        8    // 2**3 = 8
// `define YSYX_23060059_CA_NWAY        8
// `define YSYX_23060059_CA_DATA_SIZE   512  // 512bit,64Byte
// `define YSYX_23060059_CA_DATA_NUM    64   // NSET*NWAY = 8*8 = 64
// `define YSYX
// `define YSYX_23060059_CA_TAG_BUS     22:0 
// `define YSYX_23060059_CA_VALID_BUS   23:22
// `define YSYX_23060059_CA_DIRTY_BUS   24:23
// `define YSYX_23060059_CA_META_SIZE   25   // 23(tag) + 1(valid) + 1(dirty)  