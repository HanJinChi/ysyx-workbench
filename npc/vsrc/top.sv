`define YSYX_23060059_IMM  4'b0000
`define YSYX_23060059_ADD  4'b0001
`define YSYX_23060059_SUB  4'b0010
`define YSYX_23060059_AND  4'b0011
`define YSYX_23060059_XOR  4'b0100
`define YSYX_23060059_OR   4'b0101
`define YSYX_23060059_SL   4'b0110 // <<, unsigned
`define YSYX_23060059_SR   4'b0111 // >>, unsigned 
`define YSYX_23060059_DIV 4'b1000 // >=, unsigned
`define YSYX_23060059_SSR  4'b1001 // >>, signed
`define YSYX_23060059_SLES 4'b1010 // <, signed
`define YSYX_23060059_ULES 4'b1011 // <, unsigned
`define YSYX_23060059_REMU 4'b1100 // %, unsigned
`define YSYX_23060059_MUL  4'b1101 // *, unsigned 
`define YSYX_23060059_DIVU 4'b1110 // /, unsigned
`define YSYX_23060059_REM  4'b1111 

// define ALU TYPE
import "DPI-C" function void end_sim (input int end_simluation);
import "DPI-C" function void set_decode_inst (input int pc, input int inst);
import "DPI-C" function void n_pmem_read(input int raddr, output int rdata);
import "DPI-C" function void n_pmem_write(input int waddr, input int wdata, input byte wmask);

module top(
    input clk,
    input rst,
    output [31:0] pc_next,
    output reg [31:0] pc
);

  Reg #(32, 32'h80000000-32'h4) regd(clk, rst, pc_next, pc, 1); // assign pc value

  wire end_simluation;
  wire [31:0] inst;
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [4:0] rd;
  wire [31:0] imm;
  wire [1:0] pcOp;
  wire [1:0] pcOpActual;
  wire src1Op;
  wire src2Op;
  wire zero;
  wire [1:0] wdOp;
  wire [31:0] src1;
  wire [31:0] src2;
  wire [3:0] aluOp;
  wire [2:0] BOp;
  wire Bjump;
  wire ren;
  wire wen;
  wire [7:0] wmask;
  wire [31:0] rmask;
  wire rwd_signed;
  wire rwEnable;


  // Instruction Decode Unit
  idu id(
    .inst(inst),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .imm(imm),
    .pcOp(pcOp),
    .aluOp(aluOp),
    .src1Op(src1Op),
    .src2Op(src2Op),
    .BOp(BOp),
    .wdOp(wdOp),
    .ren(ren),
    .wen(wen),
    .wmask(wmask),
    .rmask(rmask),
    .rwd_signed(rwd_signed),
    .rwEnable(rwEnable),
    .ebreak(end_simluation)
  );

  // Reg Array Unit
  wire [31:0] rsa;
  wire [31:0] rsb;
  wire [31:0] rdd;
  wire [31:0] eResult;
  wire [31:0] wd;
  reg [31:0] r_wd;
  RegArray ra(
    .clk(clk),
    .rst(rst),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd)  ,
    .wd(wd)  ,
    .rwEnable(rwEnable),
    .rsa(rsa),
    .rsb(rsb),
    .rdd(rdd)
  );

  // Exection Unit
  MuxKeyWithDefault #(2, 1, 32) exsrc1(src1, src1Op, rsa, {
    1'b0, rsa,
    1'b1, pc
  });

  MuxKeyWithDefault #(2, 1, 32) exsrc2(src2, src2Op, rsb, {
    1'b0, rsb,
    1'b1, imm
  });  
  exu ex(
    .src1(src1),
    .src2(src2),
    .aluOp(aluOp),
    .zero(zero),
    .alu_result(eResult)
  );

  always @(*) begin
    if(ren) n_pmem_read(eResult, r_wd);
    else       r_wd = 0;
    if(wen) n_pmem_write(eResult, rsb, wmask);
    else n_pmem_write(eResult, rsb, 0);
  end

  wire [31:0] r_wdActual;
  MuxKeyWithDefault #(3, 32, 32) rwd(r_wdActual, rmask, 32'h0, {
    32'hff, rwd_signed ? {{24{r_wd[7]}}, r_wd[7:0]} : r_wd & rmask,
    32'hffff, rwd_signed ? {{16{r_wd[15]}}, r_wd[15:0]} : r_wd & rmask,
    32'hffffffff, r_wd
  });

  // wd choose
  MuxKeyWithDefault #(3, 2, 32) wdc (wd, wdOp, eResult, {
    2'b00, eResult,
    2'b01, r_wdActual,
    2'b10, pc+4
  });

  assign Bjump = (BOp == 3'b111) & (eResult == 32'h0) | 
                 (BOp == 3'b000) & (zero == 1)    | 
                 (BOp == 3'b101) & (eResult == 32'h0) |
                 (BOp == 3'b100) & (eResult == 32'h1)  |
                 (BOp == 3'b110) & (eResult == 32'h1)  |
                 (BOp == 3'b001) & (zero == 0)   ;
  assign pcOpActual = (BOp == 3'b010) ? pcOp : ((Bjump == 1) ? pcOp : 2'b00); 

  // pc choose
  MuxKeyWithDefault #(3, 2, 32) pcc (pc_next, pcOpActual, pc+4, {
    2'b00, pc+4,
    2'b01, pc+imm,
    2'b10, eResult&(~1)
  });

  always@(posedge clk) begin
    end_sim({32{end_simluation}});
    set_decode_inst(pc, inst);
  end

  always@(posedge clk) begin
    if(!rst) begin
      n_pmem_read(pc_next, inst);
    end
  end


endmodule

