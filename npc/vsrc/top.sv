`define YSYX_23060059_IMM   5'b00000
`define YSYX_23060059_ADD   5'b00001
`define YSYX_23060059_SUB   5'b00010
`define YSYX_23060059_AND   5'b00011
`define YSYX_23060059_XOR   5'b00100
`define YSYX_23060059_OR    5'b00101
`define YSYX_23060059_SL    5'b00110 // <<, unsigned
`define YSYX_23060059_SR    5'b00111 // >>, unsigned 
`define YSYX_23060059_DIV   5'b01000 // >=, unsigned
`define YSYX_23060059_SSR   5'b01001 // >>, signed
`define YSYX_23060059_SLES  5'b01010 // <, signed
`define YSYX_23060059_ULES  5'b01011 // <, unsigned
`define YSYX_23060059_REMU  5'b01100 // %, unsigned
`define YSYX_23060059_MUL   5'b01101 // *, unsigned 
`define YSYX_23060059_DIVU  5'b01110 // /, unsigned
`define YSYX_23060059_REM   5'b01111 
`define YSYX_23060059_SRC   5'b10000 
`define YSYS_23060059_MULHU 5'b10001 // *, unsigned, mulhu


// define ALU TYPE
import "DPI-C" function void end_sim (input int endflag);
import "DPI-C" function void set_decode_inst (input int pc, input int instruction);
import "DPI-C" function void n_pmem_read(input int raddr, output int rdata);
import "DPI-C" function void n_pmem_write(input int waddr, input int wdata, input byte wmask);

module top(
    input                 clk,
    input                 rst,
    output reg  [31:0]    pc_next,
    output reg  [31:0]    pc
);

  wire                  endflag; 
  wire   [31:0]         instruction;
  wire   [31:0]         instruction_idu;
  wire   [31:0]         instruction_exu;
  wire   [31:0]         instruction_lsu;
  wire   [4 :0]         rs1;
  wire   [4 :0]         rs2;
  wire   [1 :0]         csr_rs;
  wire   [4 :0]         rd;
  wire   [4 :0]         rd_exu;
  wire   [4 :0]         rd_lsu;
  wire   [1 :0]         csr_rd;
  wire   [1 :0]         csr_rd_exu;
  wire   [1 :0]         csr_rd_lsu;
  wire   [31:0]         imm;
  wire   [31:0]         imm_exu;
  wire   [1 :0]         pcOp;
  wire   [1 :0]         pcOp_exu;
  wire   [1 :0]         pcOpI;
  wire                  zero;
  wire   [1 :0]         wdOp;
  wire   [1 :0]         wdOp_exu;
  wire   [31:0]         src1;
  wire   [31:0]         src1_exu;
  wire   [31:0]         src2;
  wire   [31:0]         src2_exu;
  wire   [4 :0]         aluOp;
  wire   [2 :0]         BOp;
  wire   [2 :0]         BOp_exu;
  wire                  exu_state;
  wire                  lsu_state;
  wire                  Bjump;
  wire                  ren;
  wire                  ren_exu;
  wire                  wen;
  wire                  wen_exu;
  wire   [7:0]          wmask;
  wire   [7:0]          wmask_exu;
  wire   [31:0]         rmask;
  wire   [31:0]         rmask_exu;
  wire                  memory_read_signed;
  wire                  memory_read_signed_exu;
  wire                  reg_write_en;
  wire                  reg_write_en_exu;
  wire                  reg_write_en_lsu;
  wire                  csreg_write_en;
  wire                  csreg_write_en_exu;
  wire                  csreg_write_en_lsu;
  wire                  ecall;
  wire                  ecall_exu;
  wire                  ecall_lsu;
  wire                  csrwdOp;
  wire                  csrwdOp_exu;
  wire   [31:0]         rsa;
  wire   [31:0]         rsb;
  wire   [31:0]         rsb_exu;
  wire   [31:0]         pc_idu;
  wire   [31:0]         pc_next_idu;
  wire   [31:0]         pc_exu;
  wire   [31:0]         pc_next_exu;
  wire   [31:0]         pc_lsu;
  wire   [31:0]         pc_next_lsu;
  wire   [31:0]         exu_result;
  wire   [31:0]         wd;
  wire   [31:0]         csr_wd;
  wire   [31:0]         csra;
  wire   [31:0]         memory_read_wd;
  wire                  pc_write_enable;
  wire                  ifu_send_valid;
  wire                  ifu_send_ready;
  wire                  idu_send_valid;
  wire                  idu_send_ready;
  wire                  lsu_send_valid;
  wire                  lsu_send_ready;
  wire                  exu_send_valid;
  wire                  exu_send_ready;
  wire                  ifu_receive_valid;
  wire   [31:0]         araddrA;
  wire   [31:0]         araddrB;
  wire                  arvalidA;
  wire                  arvalidB;
  wire                  rreadyA;
  wire                  rreadyB;
  wire                  arreadyA;
  wire                  arreadyB;
  wire   [31:0]         rdataA;
  wire   [31:0]         rdataB;
  wire                  rvalidA;
  wire                  rvalidB;
  wire   [1 :0]         rrespA;
  wire   [1 :0]         rrespB;
  wire   [31:0]         awaddrA;
  wire   [31:0]         awaddrB;
  wire                  awvalidA;
  wire                  awvalidB;
  wire   [31:0]         wdataA;
  wire   [31:0]         wdataB;
  wire   [7 :0]         wstrbA;
  wire   [7 :0]         wstrbB;
  wire                  wvalidA;
  wire                  wvalidB;
  wire                  breadyA;
  wire                  breadyB;
  wire                  awreadyA;
  wire                  awreadyB;
  wire                  wreadyA;
  wire                  wreadyB;
  wire   [1 :0]         brespA;
  wire   [1 :0]         brespB;
  wire                  bvalidA;
  wire                  bvalidB;


  Reg #(32, 32'h80000000) regd(clk, rst, pc_next_idu, pc,  pc_write_enable); // assign pc value


  // instruction fetch Unit
  ifu ifufetch(
    .clk(clk),
    .rst(rst),
    .pc_next(pc_next),
    .ifu_receive_valid(ifu_receive_valid),
    .ifu_send_valid(ifu_send_valid),
    .ifu_send_ready(ifu_send_ready),
    .ifu_receive_ready(idu_send_ready),
    .instruction(instruction),
    .arready(arreadyA),
    .rdata(rdataA),
    .rvalid(rvalidA),
    .rresp(rrespA),
    .araddr(araddrA),
    .arvalid(arvalidA),
    .rready(rreadyA)
  );

  // instruction Decode Unit
  idu id(
    .clk(clk),
    .rst(rst),
    .instruction_input(instruction),
    .pc_input(pc),
    .rsa(rsa),
    .rsb(rsb),
    .csra(csra),
    .exu_state(exu_state),
    .rd_lsu(rd_exu), // rd_exu是rd_lsu的输入
    .csr_rd_lsu(csr_rd_exu),
    .lsu_state(lsu_state),
    .rd_wbu(rd_lsu),
    .csr_rd_wbu(csr_rd_lsu),
    .wd_wbu(wd),
    .csr_wd_wbu(csr_wd),
    .wbu_state(lsu_send_valid),
    .idu_receive_valid(ifu_send_valid),
    .rs1(rs1),
    .rs2(rs2),
    .csr_rs(csr_rs),
    .rd(rd),
    .csr_rd(csr_rd),
    .imm(imm),
    .pcOp(pcOp),
    .aluOp(aluOp),
    .src1(src1),
    .src2(src2),
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
    .ebreak(endflag),
    .pc(pc_idu),
    .pc_next(pc_next_idu),
    .instruction(instruction_idu),
    .pc_write_enable(pc_write_enable),
    .idu_send_valid(idu_send_valid),
    .idu_send_ready(idu_send_ready),
    .idu_receive_ready(exu_send_ready),
    .idu_send_to_ifu_valid(ifu_receive_valid)
  );

  // Reg Array Unit
  wbu wb(
    .clk(clk),
    .rst(rst),
    .wbu_receive_valid(lsu_send_valid),
    .rs1(rs1),
    .rs2(rs2),
    .csr_rs(csr_rs),
    .rd(rd_lsu)  ,
    .csr_rd(csr_rd_lsu),
    .wd(wd)  ,
    .csr_wd(csr_wd),
    .pc_next_input(pc_next_lsu),
    .pc_input(pc_lsu),
    .instruction_input(instruction_lsu),
    .reg_write_en(reg_write_en_lsu),
    .csreg_write_en(csreg_write_en_lsu),
    .ecall(ecall_lsu),
    .rsa(rsa),
    .rsb(rsb),
    .csra(csra)
  );

  // Exection Unit  
  exu ex(
    .clk(clk),
    .rst(rst),
    .exu_receive_valid(idu_send_valid),
    .exu_receive_ready(lsu_send_ready),
    .src1_input(src1),
    .src2_input(src2),
    .rsb_input(rsb),
    .aluOp_input(aluOp),
    .imm_input(imm),
    .pcOp_input(pcOp),
    .wdOp_input(wdOp),
    .csrwdOp_input(csrwdOp),
    .BOp_input(BOp),
    .ren_input(ren),
    .wen_input(wen),
    .wmask_input(wmask),
    .rmask_input(rmask),
    .memory_read_signed_input(memory_read_signed),
    .reg_write_en_input(reg_write_en),
    .csreg_write_en_input(csreg_write_en),
    .ecall_input(ecall),
    .pc_input(pc_idu),
    .pc_next_input(pc_next_idu),
    .instruction_input(instruction_idu),
    .rd_input(rd),
    .csr_rd_input(csr_rd),
    .zero(zero),
    .alu_result(exu_result),
    .src1(src1_exu),
    .src2(src2_exu),
    .imm(imm_exu),
    .pcOp(pcOp_exu),
    .wdOp(wdOp_exu),
    .csrwdOp(csrwdOp_exu),
    .BOp(BOp_exu),
    .ren(ren_exu),
    .wen(wen_exu),
    .wmask(wmask_exu),
    .rmask(rmask_exu),
    .memory_read_signed(memory_read_signed_exu),
    .reg_write_en(reg_write_en_exu),
    .csreg_write_en(csreg_write_en_exu),
    .ecall(ecall_exu),
    .pc(pc_exu),
    .rsb(rsb_exu),
    .rd(rd_exu),
    .pc_next(pc_next_exu),
    .instruction(instruction_exu),
    .csr_rd(csr_rd_exu),
    .exu_send_valid(exu_send_valid),
    .exu_send_ready(exu_send_ready),
    .exu_state(exu_state)
  );

  lsu ls(
    .clk(clk),
    .rst(rst),
    .lsu_receive_valid(exu_send_valid),
    .ren_input(ren_exu),
    .wen_input(wen_exu),
    .memory_read_signed_input(memory_read_signed_exu),
    .wmask_input(wmask_exu),
    .rmask_input(rmask_exu),
    .exu_result_input(exu_result),
    .pc_input(pc_exu),
    .pc_next_input(pc_next_exu),
    .instruction_input(instruction_exu),
    .src2_input(src2_exu),
    .rsb_input(rsb_exu),
    .wdOp_input(wdOp_exu),
    .csrwdOp_input(csrwdOp_exu),
    .rd_input(rd_exu),
    .csr_rd_input(csr_rd_exu),
    .reg_write_en_input(reg_write_en_exu),
    .csreg_write_en_input(csreg_write_en_exu),
    .ecall_input(ecall_exu),
    .lsu_send_valid(lsu_send_valid),
    .wd(wd),
    .csr_wd(csr_wd),
    .rd(rd_lsu),
    .csr_rd(csr_rd_lsu),
    .reg_write_en(reg_write_en_lsu),
    .csreg_write_en(csreg_write_en_lsu),
    .ecall(ecall_lsu),
    .pc_next(pc_next_lsu),
    .pc(pc_lsu),
    .instruction(instruction_lsu),
    .lsu_send_ready(lsu_send_ready),
    .lsu_state(lsu_state),
    .arready(arreadyB),
    .rdata(rdataB),
    .rresp(rrespB),
    .rvalid(rvalidB),
    .awready(awreadyB),
    .wready(wreadyB),
    .bvalid(bvalidB),
    .bresp(brespB),
    .araddr(araddrB),
    .arvalid(arvalidB),
    .rready(rreadyB),
    .awaddr(awaddrB),
    .awvalid(awvalidB),
    .wvalid(wvalidB),
    .bready(breadyB),
    .wdata(wdataB),
    .wstrb(wstrbB)
  );

  arbiter arb(
    .clk(clk),
    .rst(rst),
    .araddrA(araddrA),
    .araddrB(araddrB),
    .arvalidA(arvalidA),
    .arvalidB(arvalidB),
    .rreadyA(rreadyA),
    .rreadyB(rreadyB),
    .arreadyA(arreadyA),
    .arreadyB(arreadyB),
    .rdataA(rdataA),
    .rdataB(rdataB),
    .rvalidA(rvalidA),
    .rvalidB(rvalidB),
    .rrespA(rrespA),
    .rrespB(rrespB),
    .awaddrA(awaddrA),
    .awaddrB(awaddrB),
    .awvalidA(awvalidA),
    .awvalidB(awvalidB),
    .wdataA(wdataA),
    .wdataB(wdataB),
    .wstrbA(wstrbA),
    .wstrbB(wstrbB),
    .wvalidA(wvalidA),
    .wvalidB(wvalidB),
    .breadyA(breadyA),
    .breadyB(breadyB),
    .awreadyA(awreadyA),
    .awreadyB(awreadyB),
    .wreadyA(wreadyA),
    .wreadyB(wreadyB),
    .bvalidA(bvalidA),
    .bvalidB(bvalidB),
    .brespA(brespA),
    .brespB(brespB)
  );

  reg [31:0] set_pc;

  // assign pc_next = (pc_write_enable == 1) ? pc_next_idu : ((pc == 32'h80000000) ? 32'h80000000 : pc_next_idu);

  always @(*) begin
    if(pc_write_enable) begin
      pc_next = pc_next_idu; 
    end else begin
      if(set_pc != 0) begin
        pc_next = set_pc;
      end else begin
        if(pc == 32'h80000000) pc_next = 32'h80000000;
        else                   pc_next = pc_next_idu;
      end
    end
  end
 
  always@(*) begin
    end_sim({32{endflag}});
    set_decode_inst(pc_idu, instruction);
  end

endmodule

