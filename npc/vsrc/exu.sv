module exu(
  input   wire           clk,
  input   wire           rst,
  input   wire           exu_receive_valid,
  input   wire           exu_receive_ready,
  input   wire   [31:0]  src1_input,
  input   wire   [31:0]  src2_input,
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
  input   wire   [31:0]  pc_input,
  input   wire   [4 :0]  rd_input,
  input   wire   [1 :0]  csr_rd_input,
  output  wire   [31:0]  alu_result,
  output  wire           zero,
  output  reg    [31:0]  src1,
  output  reg    [31:0]  src2,
  output  reg    [31:0]  imm,
  output  reg    [1 :0]  pcOp,
  output  reg    [1 :0]  wdOp,
  output  reg            csrwdOp,
  output  reg    [2 :0]  BOp,
  output  reg            ren,
  output  reg            wen,
  output  reg    [7 :0]  wmask,
  output  reg    [31:0]  rmask,
  output  reg            memory_read_signed,
  output  reg            reg_write_en,
  output  reg            csreg_write_en,
  output  reg            ecall,
  output  reg    [31:0]  pc,
  output  reg    [4 :0]  rd,
  output  reg    [1 :0]  csr_rd, 
  output  reg            exu_send_valid,
  output  reg            exu_send_ready
);

  reg  [4:0]  aluOp;
  reg         state;
  reg         wait_for_exu_result;
  always @(posedge clk) begin
    if(rst) begin
      src1    <= 0;
      src2    <= 0;
      aluOp   <= 0;
      imm     <= 0;
      pcOp    <= 0;
      wdOp    <= 0;
      csrwdOp <= 0;
      BOp     <= 0;
      ren     <= 0;
      wen     <= 0;
      wmask   <= 0;
      rmask   <= 0;
      pc      <= 0;
      rd      <= 0;
      csr_rd  <= 0;
      memory_read_signed <= 0;
      reg_write_en       <= 0;
      csreg_write_en     <= 0;
      ecall              <= 0;
      exu_send_valid     <= 0;
    end else if(state == 0) begin
        if(exu_receive_valid) begin
          state              <= 1;
          exu_send_ready     <= 1;
          src1               <= src1_input;
          src2               <= src2_input;
          aluOp              <= aluOp_input;
          imm                <= imm_input;
          pcOp               <= pcOp_input;
          wdOp               <= wdOp_input;
          csrwdOp            <= csrwdOp_input;
          BOp                <= BOp_input;
          ren                <= ren_input;
          wen                <= wen_input;
          wmask              <= wmask_input;
          rmask              <= rmask_input;
          memory_read_signed <= memory_read_signed_input;
          reg_write_en       <= reg_write_en_input;
          csreg_write_en     <= csreg_write_en_input;
          ecall              <= ecall_input;
          exu_send_valid     <= 1;
          pc                 <= pc_input;
          rd                 <= rd_input;
          csr_rd             <= csr_rd_input;
        end else
          exu_send_ready <= 0;
    end else begin
      if(exu_send_valid && exu_send_ready)
        state <= 0;
      else
        exu_send_ready <= 0;
    end
  end

  always @(posedge clk) begin
    if(rst) begin
      wait_for_exu_result <= 0;
      exu_send_valid      <= 0;
    end else begin
      if(wait_for_exu_result) begin
        if(exu_receive_ready) begin
          assert(exu_send_valid == 1);
          exu_send_valid <= 0;
          wait_for_exu_result <= 0;
        end
      end else begin
        if((state == 0) && exu_receive_valid) begin
          exu_send_valid <= 1;
          if(!exu_receive_ready) wait_for_exu_result <= 1;
        end else begin
          if(exu_send_valid && exu_receive_ready) exu_send_valid <= 0;
        end
      end
    end

  end



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
  // assign result_arr[8] = $signed(src1) / $signed(src2);
  // assign zero_arr[8] = 0;

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

  // // REMU 
  // assign result_arr[12] = src1 % src2;
  // assign zero_arr[12] = 0;

  // wire[63:0] MUL_res;
  // // MUL
  // assign MUL_res = src1 * src2;
  // assign result_arr[13] = MUL_res[31:0];
  // assign zero_arr[13] = 0; 

  // // DIVU
  // assign result_arr[14] = src1 / src2;
  // assign zero_arr[14] = 0;

  // // REM
  // assign result_arr[15] = $signed(src1) % $signed(src2);
  // assign zero_arr[15] = 0;

  // SRC
  assign result_arr[16] = src1;
  assign zero_arr[16] = 0;

  // // MULHU
  // assign result_arr[17] = MUL_res[63:32];
  // assign zero_arr[17] = 0;


  MuxKeyWithDefault #(18, 5, 32) exu_m0 (alu_result, aluOp, 32'b0, {
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

  MuxKeyWithDefault #(18, 5, 1) exu_m1 (zero, aluOp, 0, {
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

endmodule
