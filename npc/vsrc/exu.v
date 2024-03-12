module ysyx_23060059_exu(
  input   wire           clock,
  input   wire           reset,
  input   wire           receive_valid,
  input   wire           receive_ready,
  input   wire   [31:0]  src1_i,
  input   wire   [31:0]  src2_i,
  input   wire   [31:0]  rsb_i,
  input   wire   [4 :0]  aluOp_i,
  input   wire   [31:0]  imm_i,
  input   wire   [1 :0]  pcOp_i,
  input   wire   [1 :0]  wdOp_i,
  input   wire           csrwdOp_i,
  input   wire   [2 :0]  BOp_i,
  input   wire           ren_i,
  input   wire           wen_i,
  input   wire   [7 :0]  wmask_i,
  input   wire   [31:0]  rmask_i,
  input   wire           m_signed_i,
  input   wire           reg_en_i,
  input   wire           csreg_en_i,
  input   wire           ecall_i,
  input   wire           ebreak_i,
  input   wire   [31:0]  pc_i,
  input   wire   [31:0]  pc_next_i,
  input   wire   [31:0]  instruction_i,
  input   wire   [4 :0]  rd_i,
  input   wire   [1 :0]  csr_rd_i,
  output  wire   [31:0]  result_o,
  output  wire           zero_o,
  output  wire   [31:0]  src1_o,
  output  wire   [31:0]  src2_o,
  output  wire   [31:0]  imm_o,
  output  wire   [1 :0]  pcOp_o,
  output  wire   [1 :0]  wdOp_o,
  output  wire           csrwdOp_o,
  output  wire   [2 :0]  BOp_o,
  output  wire           ren_o,
  output  wire           wen_o,
  output  wire   [7 :0]  wmask_o,
  output  wire   [31:0]  rmask_o,
  output  wire           m_signed_o,
  output  wire           reg_en_o,
  output  wire           csreg_en_o,
  output  wire           ecall_o,
  output  wire           ebreak_o,
  output  wire   [31:0]  pc_o,
  output  wire   [31:0]  pc_next_o,
  output  wire   [31:0]  instruction_o,
  output  wire   [31:0]  rsb_o,
  output  wire   [4 :0]  rd_o,
  output  wire   [1 :0]  csr_rd_o, 
  output  wire           send_valid,
  output  wire           send_ready,
  output  wire   [3 :0]  state_o
);

  reg          state, next_state;
  reg          send_valid_r;
  parameter    IDLE = 0, COMPUTE = 1;

  always @(posedge clock) begin
    if(reset)  state <= IDLE;
    else     state <= next_state;
  end

  always @(*) begin
    case(state)
      IDLE:
        if(receive_valid || buffer)
          next_state = COMPUTE;
        else
          next_state = IDLE;
      COMPUTE:
        if(send_valid && receive_ready)
          next_state = IDLE;
        else
          next_state = COMPUTE;
    endcase
  end

  wire  [31:0]  src1_b;
  wire  [31:0]  src2_b;
  wire  [4 :0]  aluOp_b;
  wire  [31:0]  imm_b;
  wire  [1 :0]  pcOp_b;
  wire  [1 :0]  wdOp_b;
  wire          csrwdOp_b;
  wire  [2 :0]  BOp_b;
  wire          ren_b;
  wire          wen_b;
  wire  [7 :0]  wmask_b;
  wire  [31:0]  rmask_b;
  wire          m_signed_b;
  wire          reg_en_b;
  wire          csreg_en_b;
  wire          ecall_b;
  wire          ebreak_b;
  wire  [31:0]  pc_b;
  wire  [31:0]  pc_next_b;
  wire  [31:0]  instruction_b;
  wire  [31:0]  rsb_b;
  wire  [4 :0]  rd_b;
  wire  [1 :0]  csr_rd_b;

  Reg #(32, 32'h0) regd0 (clock, reset, src1_i,        src1_b,       buffer_en);
  Reg #(32, 32'h0) regd1 (clock, reset, src2_i,        src2_b,       buffer_en);
  Reg #(5,  5 'h0) regd2 (clock, reset, aluOp_i,       aluOp_b,      buffer_en);
  Reg #(32, 32'h0) regd3 (clock, reset, imm_i,         imm_b,        buffer_en);
  Reg #(2,  2 'h0) regd4 (clock, reset, pcOp_i,        pcOp_b,       buffer_en);
  Reg #(2,  2 'h0) regd5 (clock, reset, wdOp_i,        wdOp_b,       buffer_en);
  Reg #(1,  1 'h0) regd6 (clock, reset, csrwdOp_i,     csrwdOp_b,    buffer_en);
  Reg #(3,  3 'h0) regd7 (clock, reset, BOp_i,         BOp_b,        buffer_en);
  Reg #(1,  1 'h0) regd8 (clock, reset, ren_i,         ren_b,        buffer_en);
  Reg #(1,  1 'h0) regd9 (clock, reset, wen_i,         wen_b,        buffer_en);
  Reg #(8,  8 'h0) regd10(clock, reset, wmask_i,       wmask_b,      buffer_en);
  Reg #(32, 32'h0) regd11(clock, reset, rmask_i,       rmask_b,      buffer_en);
  Reg #(1,  1 'h0) regd12(clock, reset, m_signed_i,    m_signed_b,   buffer_en);
  Reg #(1,  1 'h0) regd13(clock, reset, reg_en_i,      reg_en_b,     buffer_en);
  Reg #(1,  1 'h0) regd14(clock, reset, csreg_en_i,    csreg_en_b,   buffer_en);
  Reg #(1,  1 'h0) regd15(clock, reset, ecall_i,       ecall_b,      buffer_en);
  Reg #(1,  1 'h0) regd16(clock, reset, ebreak_i,      ebreak_b,     buffer_en);
  Reg #(32, 32'h0) regd17(clock, reset, pc_i,          pc_b,         buffer_en);
  Reg #(32, 32'h0) regd18(clock, reset, pc_next_i,     pc_next_b,    buffer_en);
  Reg #(32, 32'h0) regd19(clock, reset, instruction_i, instruction_b,buffer_en);
  Reg #(32, 32'h0) regd20(clock, reset, rsb_i,         rsb_b,        buffer_en);
  Reg #(5,  5 'h0) regd21(clock, reset, rd_i,          rd_b,         buffer_en);
  Reg #(2,  2 'h0) regd22(clock, reset, csr_rd_i,      csr_rd_b,     buffer_en);

  reg  buffer;
  always @(posedge clock) begin
    if(reset) buffer <= 0;
    else begin
      if(buffer == 0)
        if(receive_valid && send_valid)
          buffer <= 1;
    end
  end

  reg  buffer_en;
  always @(*) begin
    if(buffer == 0 && receive_valid && send_valid)
      buffer_en = 1;
    else
      buffer_en = 0;
  end

  reg  exu_to_lsu_en;
  wire [4 :0] aluOp_w;
  always @(*) begin
    if(next_state == COMPUTE && send_valid_r == 0)
      exu_to_lsu_en = 1;
    else 
      exu_to_lsu_en = 0;
  end

  Reg #(32, 32'h0) regd23 (clock, reset,  src1_i_w,        src1_o,       exu_to_lsu_en);
  Reg #(32, 32'h0) regd24 (clock, reset,  src2_i_w,        src2_o,       exu_to_lsu_en);
  Reg #(5,  5 'h0) regd25 (clock, reset,  aluOp_i_w,       aluOp_w,      exu_to_lsu_en);
  Reg #(32, 32'h0) regd26 (clock, reset,  imm_i_w,         imm_o,        exu_to_lsu_en);
  Reg #(2,  2 'h0) regd27 (clock, reset,  pcOp_i_w,        pcOp_o,       exu_to_lsu_en);
  Reg #(2,  2 'h0) regd28 (clock, reset,  wdOp_i_w,        wdOp_o,       exu_to_lsu_en);
  Reg #(1,  1 'h0) regd29 (clock, reset,  csrwdOp_i_w,     csrwdOp_o,    exu_to_lsu_en);
  Reg #(3,  3 'h0) regd30 (clock, reset,  BOp_i_w,         BOp_o,        exu_to_lsu_en);
  Reg #(1,  1 'h0) regd31 (clock, reset,  ren_i_w,         ren_o,        exu_to_lsu_en);
  Reg #(1,  1 'h0) regd32 (clock, reset,  wen_i_w,         wen_o,        exu_to_lsu_en);
  Reg #(8,  8 'h0) regd33 (clock, reset,  wmask_i_w,       wmask_o,      exu_to_lsu_en);
  Reg #(32, 32'h0) regd34 (clock, reset,  rmask_i_w,       rmask_o,      exu_to_lsu_en);
  Reg #(1,  1 'h0) regd35 (clock, reset,  m_signed_i_w,    m_signed_o,   exu_to_lsu_en);
  Reg #(1,  1 'h0) regd36 (clock, reset,  reg_en_i_w,      reg_en_o,     exu_to_lsu_en);
  Reg #(1,  1 'h0) regd37 (clock, reset,  csreg_en_i_w,    csreg_en_o,   exu_to_lsu_en);
  Reg #(1,  1 'h0) regd38 (clock, reset,  ecall_i_w,       ecall_o,      exu_to_lsu_en);
  Reg #(1,  1 'h0) regd39 (clock, reset,  ebreak_i_w,      ebreak_o,     exu_to_lsu_en);
  Reg #(32, 32'h0) regd40 (clock, reset,  pc_i_w,          pc_o,         exu_to_lsu_en);
  Reg #(32, 32'h0) regd41 (clock, reset,  pc_next_i_w,     pc_next_o,    exu_to_lsu_en);
  Reg #(32, 32'h0) regd42 (clock, reset,  instruction_i_w, instruction_o,exu_to_lsu_en);
  Reg #(32, 32'h0) regd43 (clock, reset,  rsb_i_w,         rsb_o,        exu_to_lsu_en);
  Reg #(5,  5 'h0) regd44 (clock, reset,  rd_i_w,          rd_o,         exu_to_lsu_en);
  Reg #(2,  2 'h0) regd45( clock, reset,  csr_rd_i_w,      csr_rd_o,     exu_to_lsu_en);

  always @(posedge clock) begin
    if(reset) begin
      send_valid_r <= 0;
    end else begin
      if(next_state == COMPUTE) begin
        if(send_valid_r == 0) begin
          send_valid_r <= 1;
          if(buffer) 
            buffer         <= 0;
        end
      end else begin
        if(send_valid_r) send_valid_r <= 0;
      end
    end
  end
  assign send_valid = send_valid_r;


  wire [31:0] result_arr [17:0];
  wire zero_arr [17:0];
  // IMM 
  assign result_arr[0] = src2_o;
  assign zero_arr[0] = 0;
  // ADD
  assign result_arr[1] = src1_o + src2_o;
  assign zero_arr[1] = result_arr[1] == 0;
  // SUB
  assign result_arr[2] = src1_o - src2_o;
  assign zero_arr[2] = result_arr[2] == 0;
  // AND
  assign result_arr[3] = src1_o & src2_o;
  assign zero_arr[3] = 0;
  // XOR
  assign result_arr[4] = src1_o ^ src2_o;
  assign zero_arr[4] = 0;
  // OR
  assign result_arr[5] = src1_o | src2_o;
  assign zero_arr[5] = 0;
  // SL
  assign result_arr[6] = src1_o << (src2_o & 32'h1F);
  assign zero_arr[6] = 0;
  // SR 
  assign result_arr[7] = src1_o >> (src2_o & 32'h1F);
  assign zero_arr[7] = 0;

  // // DIV
  assign result_arr[8] = 0;
  assign zero_arr[8] = 0;

  // SSR 
  assign result_arr[9] = $signed(src1_o) >>> (src2_o & 32'h1F);
  assign zero_arr[9] = 0;

  // SLES
  assign result_arr[10] = {31'h0, $signed(src1_o) < $signed(src2_o) };
  assign zero_arr[10] = 0;

  // ULES
  wire [32:0] ules_temp;
  assign ules_temp = {1'b0, src1_o} - {1'b0, src2_o};
  assign result_arr[11] = {31'h0, ules_temp[32]};
  assign zero_arr[11] = 0;

  // REMU 
  assign result_arr[12] = 0;
  assign zero_arr[12] = 0;

  wire[63:0] MUL_res;
  // MUL
  assign result_arr[13] = 0;
  assign zero_arr[13] = 0; 

  // DIVU
  assign result_arr[14] = 0;
  assign zero_arr[14] = 0;

  // REM
  assign result_arr[15] = 0;
  assign zero_arr[15] = 0;

  // SRC
  assign result_arr[16] = src1_o;
  assign zero_arr[16] = 0;

  // MULHU
  assign result_arr[17] = 0;
  assign zero_arr[17] = 0;


  MuxKeyWithDefault #(18, 5, 32) exu_m0 (result_o, aluOp_w, 32'b0, {
    `YSYX_23060059_IMM,  result_arr[0],
    `YSYX_23060059_ADD,  result_arr[1],
    `YSYX_23060059_SUB,  result_arr[2],
    `YSYX_23060059_AND,  result_arr[3],
    `YSYX_23060059_XOR,  result_arr[4],
    `YSYX_23060059_OR,   result_arr[5],
    `YSYX_23060059_SL,   result_arr[6],
    `YSYX_23060059_SR,   result_arr[7],
    `YSYX_23060059_DIV,  result_arr[8],
    `YSYX_23060059_SSR,  result_arr[9],
    `YSYX_23060059_SLES, result_arr[10],
    `YSYX_23060059_ULES, result_arr[11],
    `YSYX_23060059_REMU, result_arr[12],
    `YSYX_23060059_MUL , result_arr[13],
    `YSYX_23060059_DIVU, result_arr[14],
    `YSYX_23060059_REM,  result_arr[15],
    `YSYX_23060059_SRC,  result_arr[16],
    `YSYX_23060059_MULHU,  result_arr[17]
  });

  MuxKeyWithDefault #(18, 5, 1) exu_m1 (zero_o, aluOp_w, 0, {
    `YSYX_23060059_IMM,  zero_arr[0],
    `YSYX_23060059_ADD,  zero_arr[1],
    `YSYX_23060059_SUB,  zero_arr[2],
    `YSYX_23060059_AND,  zero_arr[3],
    `YSYX_23060059_XOR,  zero_arr[4],
    `YSYX_23060059_OR,   zero_arr[5],
    `YSYX_23060059_SL,   zero_arr[6],
    `YSYX_23060059_SR,   zero_arr[7],
    `YSYX_23060059_DIV,  zero_arr[8],
    `YSYX_23060059_SSR,  zero_arr[9],
    `YSYX_23060059_SLES, zero_arr[10],
    `YSYX_23060059_ULES, zero_arr[11],
    `YSYX_23060059_REMU, zero_arr[12],
    `YSYX_23060059_MUL,  zero_arr[13],
    `YSYX_23060059_DIVU, zero_arr[14],
    `YSYX_23060059_REM,  zero_arr[15],
    `YSYX_23060059_SRC,  zero_arr[16],
    `YSYX_23060059_MULHU, zero_arr[17]
  });

  // 第1bit指示当前的状态
  // 第2bit指示next state
  // 第3bit代表处于exu的指令是否要写通用寄存器
  // 第4bit代表处于exu的指令是否要写csr寄存器
  assign state_o = {csreg_en_i_w, reg_en_i_w, next_state, state};

  wire  [31:0]  src1_i_w;
  wire  [31:0]  src2_i_w;
  wire  [4 :0]  aluOp_i_w;
  wire  [31:0]  imm_i_w;
  wire  [1 :0]  pcOp_i_w;
  wire  [1 :0]  wdOp_i_w;
  wire          csrwdOp_i_w;
  wire  [2 :0]  BOp_i_w;
  wire          ren_i_w;
  wire          wen_i_w;
  wire  [7 :0]  wmask_i_w;
  wire  [31:0]  rmask_i_w;
  wire          m_signed_i_w;
  wire          reg_en_i_w;
  wire          csreg_en_i_w;
  wire          ecall_i_w;
  wire          ebreak_i_w;
  wire  [31:0]  pc_i_w;
  wire  [31:0]  pc_next_i_w;
  wire  [31:0]  instruction_i_w;
  wire  [31:0]  rsb_i_w;
  wire  [4 :0]  rd_i_w;
  wire  [1 :0]  csr_rd_i_w;

  assign send_ready  = !buffer;
  assign src1_i_w        = buffer ? src1_b        : src1_i;
  assign src2_i_w        = buffer ? src2_b        : src2_i;
  assign aluOp_i_w       = buffer ? aluOp_b       : aluOp_i;
  assign imm_i_w         = buffer ? imm_b         : imm_i;
  assign pcOp_i_w        = buffer ? pcOp_b        : pcOp_i;
  assign wdOp_i_w        = buffer ? wdOp_b        : wdOp_i;
  assign csrwdOp_i_w     = buffer ? csrwdOp_b     : csrwdOp_i;  
  assign BOp_i_w         = buffer ? BOp_b         : BOp_i;
  assign ren_i_w         = buffer ? ren_b         : ren_i;
  assign wen_i_w         = buffer ? wen_b         : wen_i;
  assign wmask_i_w       = buffer ? wmask_b       : wmask_i;
  assign rmask_i_w       = buffer ? rmask_b       : rmask_i;
  assign m_signed_i_w    = buffer ? m_signed_b    : m_signed_i;
  assign csreg_en_i_w    = buffer ? csreg_en_b    : csreg_en_i;
  assign reg_en_i_w      = buffer ? reg_en_b      : reg_en_i;
  assign ecall_i_w       = buffer ? ecall_b       : ecall_i;
  assign ebreak_i_w      = buffer ? ebreak_b      : ebreak_i;
  assign pc_i_w          = buffer ? pc_b          : pc_i;
  assign pc_next_i_w     = buffer ? pc_next_b     : pc_next_i;
  assign instruction_i_w = buffer ? instruction_b : instruction_i;
  assign rsb_i_w         = buffer ? rsb_b         : rsb_i;
  assign rd_i_w          = buffer ? rd_b          : rd_i;
  assign csr_rd_i_w      = buffer ? csr_rd_b      : csr_rd_i;


endmodule