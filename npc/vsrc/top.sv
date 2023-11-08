`define YSYX_23060059_IMM  5'b00000
`define YSYX_23060059_ADD  5'b00001
`define YSYX_23060059_SUB  5'b00010
`define YSYX_23060059_AND  5'b00011
`define YSYX_23060059_XOR  5'b00100
`define YSYX_23060059_OR   5'b00101
`define YSYX_23060059_SL   5'b00110 // <<, unsigned
`define YSYX_23060059_SR   5'b00111 // >>, unsigned 
`define YSYX_23060059_DIV  5'b01000 // >=, unsigned
`define YSYX_23060059_SSR  5'b01001 // >>, signed
`define YSYX_23060059_SLES 5'b01010 // <, signed
`define YSYX_23060059_ULES 5'b01011 // <, unsigned
`define YSYX_23060059_REMU 5'b01100 // %, unsigned
`define YSYX_23060059_MUL  5'b01101 // *, unsigned 
`define YSYX_23060059_DIVU 5'b01110 // /, unsigned
`define YSYX_23060059_REM  5'b01111 
`define YSYX_23060059_SRC  5'b10000 


// define ALU TYPE
import "DPI-C" function void end_sim (input int endflag);
import "DPI-C" function void set_decode_inst (input int pc, input int instruction);
import "DPI-C" function void n_pmem_read(input int raddr, output int rdata);
import "DPI-C" function void n_pmem_write(input int waddr, input int wdata, input byte wmask);

module top(
    input                 clk,
    input                 rst,
    output      [31:0]    pc_next,
    output reg  [31:0]    pc
);

  wire                  endflag; 
  wire   [31:0]         instruction;
  wire   [4 :0]         rs1;
  wire   [4 :0]         rs2;
  wire   [1 :0]         csr_rs;
  wire   [4 :0]         rd;
  wire   [1 :0]         csr_rd;
  wire   [31:0]         imm;
  wire   [1 :0]         pcOp;
  wire   [1 :0]         pcOpI;
  wire                  src1Op;
  wire   [1 :0]         src2Op;
  wire                  zero;
  wire   [1 :0]         wdOp;
  wire   [31:0]         src1;
  wire   [31:0]         src2;
  wire   [4 :0]         aluOp;
  wire   [2 :0]         BOp;
  wire                  Bjump;
  wire                  ren;
  wire                  wen;
  wire   [7:0]          wmask;
  wire   [31:0]         rmask;
  wire                  memory_read_signed;
  wire                  reg_write_en;
  wire                  csreg_write_en;
  wire                  ecall;
  wire                  csrwdOp;
  wire   [31:0]         rsa;
  wire   [31:0]         rsb;
  wire   [31:0]         exu_result;
  wire   [31:0]         wd;
  wire   [31:0]         csr_wd;
  wire   [31:0]         csra;
  reg    [31:0]         memory_read;
  wire   [31:0]         memory_read_wd;


  Reg #(32, 32'h80000000-32'h4) regd(clk, rst, pc_next, pc, 1); // assign pc value

  // instruction fetch Unit
  ifu ifufetch(
    .clk(clk),
    .rst(rst),
    .pc_next(pc_next),
    .instruction(instruction)
  );

  // instruction Decode Unit
  idu id(
    .instruction(instruction),
    .rs1(rs1),
    .rs2(rs2),
    .csr_rs(csr_rs),
    .rd(rd),
    .csr_rd(csr_rd),
    .imm(imm),
    .pcOp(pcOp),
    .aluOp(aluOp),
    .src1Op(src1Op),
    .src2Op(src2Op),
    .BOp(BOp),
    .wdOp(wdOp),
    .csrwdOp(csrwdOp),
    .ren(ren),
    .wen(wen),
    .wmask(wmask),
    .rmask(rmask),
    .memory_read_signed(memory_read_signed),
    .reg_write_en(reg_write_en),
    .csreg_write_en(csreg_write_en),
    .ecall(ecall),
    .ebreak(endflag)
  );

  // Reg Array Unit
  RegArray ra(
    .clk(clk),
    .rst(rst),
    .rs1(rs1),
    .rs2(rs2),
    .csr_rs(csr_rs),
    .rd(rd)  ,
    .csr_rd(csr_rd),
    .wd(wd)  ,
    .csr_wd(csr_wd),
    .reg_write_en(reg_write_en),
    .csreg_write_en(csreg_write_en),
    .ecall(ecall),
    .rsa(rsa),
    .rsb(rsb),
    .csra(csra)
  );

  // Exection Unit
  MuxKeyWithDefault #(2, 1, 32) exsrc1(src1, src1Op, rsa, {
    1'b0, rsa,
    1'b1, pc
  });

  MuxKeyWithDefault #(3, 2, 32) exsrc2(src2, src2Op, rsb, {
    2'b00, rsb,
    2'b01, imm,
    2'b10, csra
  });  
  exu ex(
    .src1(src1),
    .src2(src2),
    .aluOp(aluOp),
    .zero(zero),
    .alu_result(exu_result)
  );

  always @(*) begin
    if(ren)    n_pmem_read(exu_result, memory_read);
    else       memory_read = 0;
    if(wen)    n_pmem_write(exu_result, rsb, wmask);
    else       n_pmem_write(exu_result, rsb, 0);
  end


  MuxKeyWithDefault #(3, 32, 32) rwd(memory_read_wd, rmask, 32'h0, {
    32'hff,       memory_read_signed ? {{24{memory_read[7]}} , memory_read[7:0]}  : memory_read & rmask,
    32'hffff,     memory_read_signed ? {{16{memory_read[15]}}, memory_read[15:0]} : memory_read & rmask,
    32'hffffffff, memory_read
  });

  // wd choose
  MuxKeyWithDefault #(4, 2, 32) wdc (wd, wdOp, exu_result, {
    2'b00, exu_result,
    2'b01, memory_read_wd,
    2'b10, pc+4,
    2'b11, src2
  });

  MuxKeyWithDefault #(2, 1, 32) csrwdc (csr_wd, csrwdOp, exu_result, {
    1'b0, exu_result,
    1'b1, pc
  });

  assign Bjump = (BOp == 3'b111) & (exu_result == 32'h0) | 
                 (BOp == 3'b000) & (zero == 1)    | 
                 (BOp == 3'b101) & (exu_result == 32'h0) |
                 (BOp == 3'b100) & (exu_result == 32'h1)  |
                 (BOp == 3'b110) & (exu_result == 32'h1)  |
                 (BOp == 3'b001) & (zero == 0)   ;
  // Bop = 3'b010 代表着不是一条B指令
  assign pcOpI = (BOp == 3'b010) ? pcOp : ((Bjump == 1) ? pcOp : 2'b00); 

  // pc choose
  MuxKeyWithDefault #(4, 2, 32) pcc (pc_next, pcOpI, pc+4, {
    2'b00, pc+4,
    2'b01, pc+imm,
    2'b10, exu_result&(~1),
    2'b11, csra
  });

  always@(posedge clk) begin
    end_sim({32{endflag}});
    set_decode_inst(pc, instruction);
  end

  // always@(posedge clk) begin
  //   if(!rst) begin
  //     n_pmem_read(pc_next, instruction);
  //   end
  // end


endmodule

