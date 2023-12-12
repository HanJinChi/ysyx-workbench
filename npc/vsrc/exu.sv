module exu(
  input   wire           clk,
  input   wire           rst,
  input   wire           exu_receive_valid,
  input   wire           exu_receive_ready,
  input   wire   [31:0]  src1_input,
  input   wire   [31:0]  src2_input,
  input   wire   [31:0]  rsb_input,
  input   wire   [4 :0]  aluOp_input,
  input   wire   [31:0]  imm_input,
  input   wire   [1 :0]  pcOp_input,
  input   wire   [1 :0]  wdOp_input,
  input   wire           csrwdOp_input,
  input   wire   [2 :0]  BOp_input,
  input   wire           ren_input,
  input   wire           wen_input,
  input   wire   [7 :0]  wmask_input,
  input   wire   [31:0]  rmask_input,
  input   wire           memory_read_signed_input,
  input   wire           reg_write_en_input,
  input   wire           csreg_write_en_input,
  input   wire           ecall_input,
  input   wire           ebreak_input,
  input   wire   [31:0]  pc_input,
  input   wire   [31:0]  pc_next_input,
  input   wire   [31:0]  instruction_input,
  input   wire   [4 :0]  rd_input,
  input   wire   [1 :0]  csr_rd_input,
  output  wire   [31:0]  alu_result,
  output  wire           zero,
  output  wire   [31:0]  src1,
  output  wire   [31:0]  src2,
  output  wire   [31:0]  imm,
  output  wire   [1 :0]  pcOp,
  output  wire   [1 :0]  wdOp,
  output  wire           csrwdOp,
  output  wire   [2 :0]  BOp,
  output  wire           ren,
  output  wire           wen,
  output  wire   [7 :0]  wmask,
  output  wire   [31:0]  rmask,
  output  wire           memory_read_signed,
  output  wire           reg_write_en,
  output  wire           csreg_write_en,
  output  wire           ecall,
  output  wire           ebreak,
  output  wire   [31:0]  pc,
  output  wire   [31:0]  pc_next,
  output  wire   [31:0]  instruction,
  output  wire   [31:0]  rsb,
  output  wire   [4 :0]  rd,
  output  wire   [1 :0]  csr_rd, 
  output  wire           exu_send_valid,
  output  wire           exu_send_ready,
  output  wire   [2 :0]  exu_state_o
);

  reg          state, next_state;
  reg          wait_for_exu_result;
  reg  [31:0]  src1_r;
  reg  [31:0]  src2_r;
  reg  [4: 0]  aluOp_r;
  reg  [31:0]  imm_r;
  reg  [1 :0]  pcOp_r;
  reg  [1 :0]  wdOp_r;
  reg          csrwdOp_r;
  reg  [2 :0]  BOp_r;
  reg          ren_r;
  reg          wen_r;
  reg  [7 :0]  wmask_r;
  reg  [31:0]  rmask_r;
  reg          memory_read_signed_r;
  reg          reg_write_en_r;
  reg          csreg_write_en_r;
  reg          ecall_r;
  reg          ebreak_r;
  reg  [31:0]  pc_r;
  reg  [31:0]  pc_next_r;
  reg  [31:0]  instruction_r;
  reg  [31:0]  rsb_r;
  reg  [4 :0]  rd_r;
  reg  [1 :0]  csr_rd_r; 
  reg          exu_send_valid_r;
  parameter    IDLE = 0, COMPUTE = 1;

  always @(posedge clk) begin
    if(rst)  state <= IDLE;
    else     state <= next_state;
  end

  always @(*) begin
    case(state)
      IDLE:
        if(exu_receive_valid || buffer)
          next_state = COMPUTE;
        else
          next_state = IDLE;
      COMPUTE:
        if(exu_send_valid && exu_receive_ready)
          next_state = IDLE;
        else
          next_state = COMPUTE;
    endcase
  end

  reg  [31:0]  src1_b;
  reg  [31:0]  src2_b;
  reg  [4 :0]  aluOp_b;
  reg  [31:0]  imm_b;
  reg  [1 :0]  pcOp_b;
  reg  [1 :0]  wdOp_b;
  reg          csrwdOp_b;
  reg  [2 :0]  BOp_b;
  reg          ren_b;
  reg          wen_b;
  reg  [7 :0]  wmask_b;
  reg  [31:0]  rmask_b;
  reg          memory_read_signed_b;
  reg          reg_write_en_b;
  reg          csreg_write_en_b;
  reg          ecall_b;
  reg          ebreak_b;
  reg  [31:0]  pc_b;
  reg  [31:0]  pc_next_b;
  reg  [31:0]  instruction_b;
  reg  [31:0]  rsb_b;
  reg  [4 :0]  rd_b;
  reg  [1 :0]  csr_rd_b;
  reg          buffer; 

  always @(posedge clk) begin
    if(rst) begin
      src1_b                 <= 0;
      src2_b                 <= 0;
      aluOp_b                <= 0;
      imm_b                  <= 0;
      pcOp_b                 <= 0;
      wdOp_b                 <= 0;
      csrwdOp_b              <= 0;
      BOp_b                  <= 0;
      ren_b                  <= 0;
      wen_b                  <= 0;
      wmask_b                <= 0;
      rmask_b                <= 0;
      memory_read_signed_b   <= 0;
      reg_write_en_b         <= 0;
      csreg_write_en_b       <= 0;
      ecall_b                <= 0;
      ebreak_b               <= 0;
      pc_b                   <= 0;
      pc_next_b              <= 0;
      instruction_b          <= 0;
      rsb_b                  <= 0;
      rd_b                   <= 0;
      csr_rd_b               <= 0;
      // control buffer reg 
      buffer                 <= 0;
    end else begin
        if(buffer == 0) begin
          if(exu_receive_valid && exu_send_valid) begin
            src1_b               <= src1_input;
            src2_b               <= src2_input;
            aluOp_b              <= aluOp_input;
            imm_b                <= imm_input;
            pcOp_b               <= pcOp_input;
            wdOp_b               <= wdOp_input;
            csrwdOp_b            <= csrwdOp_input;
            BOp_b                <= BOp_input;
            ren_b                <= ren_input;
            wen_b                <= wen_input;
            wmask_b              <= wmask_input;
            rmask_b              <= rmask_input;
            memory_read_signed_b <= memory_read_signed_input;
            reg_write_en_b       <= reg_write_en_input;
            csreg_write_en_b     <= csreg_write_en_input;
            ecall_b              <= ecall_input;
            ebreak_b             <= ebreak_input;
            pc_b                 <= pc_input;
            pc_next_b            <= pc_next_input;
            instruction_b        <= instruction_input;
            rsb_b                <= rsb_input;
            rd_b                 <= rd_input;
            csr_rd_b             <= csr_rd_input;
            buffer               <= 1;
          end 
      end
    end
  end 

  always @(posedge clk) begin
    if(rst) begin
      src1_r                <= 0;
      src2_r                <= 0;
      aluOp_r               <= 0;
      imm_r                 <= 0;
      pcOp_r                <= 0;
      wdOp_r                <= 0;
      csrwdOp_r             <= 0;
      BOp_r                 <= 0;
      ren_r                 <= 0;
      wen_r                 <= 0;
      wmask_r               <= 0;
      rmask_r               <= 0;
      pc_r                  <= 0;
      pc_next_r             <= 0;
      rd_r                  <= 0;
      csr_rd_r              <= 0;
      rsb_r                 <= 0;
      memory_read_signed_r  <= 0;
      reg_write_en_r        <= 0;
      csreg_write_en_r      <= 0;
      ecall_r               <= 0;
      ebreak_r              <= 0;
      exu_send_valid_r      <= 0;
      instruction_r         <= 0;
    end else begin
      if(next_state == COMPUTE) begin
        if(exu_send_valid_r == 0) begin
          exu_send_valid_r     <= 1;
          src1_r               <= src1_i_w;
          src2_r               <= src2_i_w;
          aluOp_r              <= aluOp_i_w;
          imm_r                <= imm_i_w;
          pcOp_r               <= pcOp_i_w;
          wdOp_r               <= wdOp_i_w;
          csrwdOp_r            <= csrwdOp_i_w;
          BOp_r                <= BOp_i_w;
          ren_r                <= ren_i_w;
          wen_r                <= wen_i_w;
          wmask_r              <= wmask_i_w;
          rmask_r              <= rmask_i_w;
          memory_read_signed_r <= memory_read_signed_i_w;
          reg_write_en_r       <= reg_write_en_i_w;
          csreg_write_en_r     <= csreg_write_en_i_w;
          ecall_r              <= ecall_i_w;
          ebreak_r             <= ebreak_i_w;
          pc_r                 <= pc_i_w;
          pc_next_r            <= pc_next_i_w;
          rd_r                 <= rd_i_w;
          csr_rd_r             <= csr_rd_i_w;
          rsb_r                <= rsb_i_w;
          instruction_r        <= instruction_i_w;
          if(buffer)
            buffer             <= 0;
        end
      end else begin
        if(exu_send_valid_r == 1) exu_send_valid_r <= 0;
      end
    end
  end

  assign src1               = src1_r;
  assign src2               = src2_r;
  assign imm                = imm_r;
  assign pcOp               = pcOp_r;
  assign wdOp               = wdOp_r;
  assign csrwdOp            = csrwdOp_r;
  assign BOp                = BOp_r;
  assign ren                = ren_r;
  assign wen                = wen_r;
  assign wmask              = wmask_r;
  assign rmask              = rmask_r;
  assign memory_read_signed = memory_read_signed_r;
  assign reg_write_en       = reg_write_en_r;
  assign csreg_write_en     = csreg_write_en_r;
  assign ecall              = ecall_r;
  assign pc                 = pc_r;
  assign pc_next            = pc_next_r;
  assign instruction        = instruction_r;
  assign rsb                = rsb_r;
  assign rd                 = rd_r;
  assign csr_rd             = csr_rd_r;
  assign exu_send_valid     = exu_send_valid_r;
  assign ebreak             = ebreak_r;

  wire [31:0] result_arr [17:0];
  wire zero_arr [17:0];
  // IMM 
  assign result_arr[0] = src2;
  assign zero_arr[0] = 0;
  // ADD
  assign result_arr[1] = src1 + src2;
  assign zero_arr[1] = result_arr[1] == 0;
  // SUB
  assign result_arr[2] = src1 - src2;
  assign zero_arr[2] = result_arr[2] == 0;
  // AND
  assign result_arr[3] = src1 & src2;
  assign zero_arr[3] = 0;
  // XOR
  assign result_arr[4] = src1 ^ src2;
  assign zero_arr[4] = 0;
  // OR
  assign result_arr[5] = src1 | src2;
  assign zero_arr[5] = 0;
  // SL
  assign result_arr[6] = src1 << (src2 & 32'h1F);
  assign zero_arr[6] = 0;
  // SR 
  assign result_arr[7] = src1 >> (src2 & 32'h1F);
  assign zero_arr[7] = 0;

  // // DIV
  assign result_arr[8] = 0;
  assign zero_arr[8] = 0;

  // SSR 
  assign result_arr[9] = $signed(src1) >>> (src2 & 32'h1F);
  assign zero_arr[9] = 0;

  // SLES
  assign result_arr[10] = {31'h0, $signed(src1) < $signed(src2) };
  assign zero_arr[10] = 0;

  // ULES
  wire [32:0] ules_temp;
  assign ules_temp = {1'b0, src1} - {1'b0, src2};
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
  assign result_arr[16] = src1;
  assign zero_arr[16] = 0;

  // MULHU
  assign result_arr[17] = 0;
  assign zero_arr[17] = 0;


  MuxKeyWithDefault #(18, 5, 32) exu_m0 (alu_result, aluOp_r, 32'b0, {
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
    `YSYS_23060059_MULHU,  result_arr[17]
  });

  MuxKeyWithDefault #(18, 5, 1) exu_m1 (zero, aluOp_r, 0, {
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
    `YSYS_23060059_MULHU, zero_arr[17]
  });

  // 第1bit代表是否出于工作状态
  // 第2bit代表处于exu的指令是否要写通用寄存器
  // 第3bit代表处于exu的指令是否要写csr寄存器
  reg  [2:0]  exu_state_o_r;
  always@(*) begin
    if(next_state == IDLE)
      exu_state_o_r = 0;
    else begin
      exu_state_o_r = {csreg_write_en_input, reg_write_en_input, 1'b1};
    end
  end
  assign exu_state_o = exu_state_o_r;

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
  wire          memory_read_signed_i_w;
  wire          reg_write_en_i_w;
  wire          csreg_write_en_i_w;
  wire          ecall_i_w;
  wire          ebreak_i_w;
  wire  [31:0]  pc_i_w;
  wire  [31:0]  pc_next_i_w;
  wire  [31:0]  instruction_i_w;
  wire  [31:0]  rsb_i_w;
  wire  [4 :0]  rd_i_w;
  wire  [1 :0]  csr_rd_i_w;

  assign exu_send_ready = !buffer;
  assign src1_i_w    = buffer ? src1_b : src1_input;
  assign src2_i_w    = buffer ? src2_b : src2_input;
  assign aluOp_i_w   = buffer ? aluOp_b: aluOp_input;
  assign imm_i_w     = buffer ? imm_b  : imm_input;
  assign pcOp_i_w    = buffer ? pcOp_b : pcOp_input;
  assign wdOp_i_w    = buffer ? wdOp_b : wdOp_input;
  assign csrwdOp_i_w = buffer ? csrwdOp_b : csrwdOp_input;  
  assign BOp_i_w     = buffer ? BOp_b  : BOp_input;
  assign ren_i_w     = buffer ? ren_b  : ren_input;
  assign wen_i_w     = buffer ? wen_b  : wen_input;
  assign wmask_i_w   = buffer ? wmask_b : wmask_input;
  assign rmask_i_w   = buffer ? rmask_b : rmask_input;
  assign memory_read_signed_i_w = buffer ? memory_read_signed_b : memory_read_signed_input;
  assign csreg_write_en_i_w = buffer ? csreg_write_en_b : csreg_write_en_input;
  assign reg_write_en_i_w = buffer ? reg_write_en_b : reg_write_en_input;
  assign ecall_i_w   = buffer ? ecall_b : ecall_input;
  assign ebreak_i_w  = buffer ? ebreak_b : ebreak_input;
  assign pc_i_w      = buffer ? pc_b : pc_input;
  assign pc_next_i_w = buffer ? pc_next_b : pc_next_input;
  assign instruction_i_w = buffer ? instruction_b : instruction_input;
  assign rsb_i_w     = buffer ? rsb_b : rsb_input;
  assign rd_i_w      = buffer ? rd_b  : rd_input;
  assign csr_rd_i_w  = buffer ? csr_rd_b : csr_rd_input;



endmodule