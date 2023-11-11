module exu(
  input [31:0] src1,
  input [31:0] src2,
  input [4:0] aluOp,
  output [31:0] alu_result,
  output zero
);

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

  // DIV
  assign result_arr[8] = $signed(src1) / $signed(src2);
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
  assign result_arr[12] = src1 % src2;
  assign zero_arr[12] = 0;

  wire[63:0] MUL_res;
  // MUL
  assign MUL_res = src1 * src2;
  assign result_arr[13] = MUL_res[31:0];
  assign zero_arr[13] = 0; 

  // DIVU
  assign result_arr[14] = src1 / src2;
  assign zero_arr[14] = 0;

  // REM
  assign result_arr[15] = $signed(src1) % $signed(src2);
  assign zero_arr[15] = 0;

  // SRC
  assign result_arr[16] = src1;
  assign zero_arr[16] = 0;

  // MULHU
  assign result_arr[17] = MUL_res[63:32];
  assign zero_arr[17] = 0;


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
