
// define instruction TYPE
`define YSYX_23060059_TYPE_I 3'b000
`define YSYX_23060059_TYPE_U 3'b001
`define YSYX_23060059_TYPE_S 3'b010
`define YSYX_23060059_TYPE_J 3'b011
`define YSYX_23060059_TYPE_B 3'b100
`define YSYX_23060059_TYPE_R 3'b101
`define YSYX_23060059_TYPE_V 3'b110


module idu(
  input    wire          clk,
  input    wire          rst,
  input    wire  [31:0]  instruction_input,
  input    wire  [31:0]  pc_input,
  input    wire  [31:0]  rsa,
  input    wire  [31:0]  rsb,
  input    wire  [31:0]  csra,
  input    wire          exu_state,
  input    wire  [4 :0]  rd_lsu,
  input    wire  [1 :0]  csr_rd_lsu,
  input    wire          lsu_state,
  input    wire  [4 :0]  rd_wbu,
  input    wire  [1 :0]  csr_rd_wbu,
  input    wire          wbu_state,
  input    wire          idu_receive_valid,
  input    wire          idu_receive_ready,
  output   wire  [4 :0]  rs1,
  output   wire  [4 :0]  rs2,
  output   wire  [1 :0]  csr_rs, 
  output   wire  [4 :0]  rd,
  output   wire  [1 :0]  csr_rd,
  output   wire  [31:0]  imm,
  output   wire  [1 :0]  pcOp,
  output   wire  [4 :0]  aluOp,
  output   wire  [31:0]  src1,
  output   wire  [31:0]  src2,
  output   wire  [1 :0]  wdOp,
  output   wire          csrwdOp,
  output   wire  [2 :0]  BOp,
  output   wire          ren,
  output   wire          wen,
  output   wire  [7 :0]  wmask,
  output   wire  [31:0]  rmask,
  output   wire          memory_read_signed,
  output   wire          reg_write_en,
  output   wire          csreg_write_en,
  output   wire          ecall, 
  output   wire          ebreak,
  output   wire  [31:0]  pc_next,
  output   wire          pc_write_enable,
  output   reg   [31:0]  pc,
  output   reg   [31:0]  instruction,
  output   reg           idu_send_to_ifu_valid,
  output   reg           idu_send_valid,
  output   reg           idu_send_ready
);

  parameter   IDLE = 0, DECODE = 1;
  reg         state, next_state;
  always @(posedge clk) begin
    if(clk) state <= IDLE;
    else    state <= next_state;
  end

  always@(*) begin
    case(state)
      IDLE:
        if(idu_receive_valid)
          next_state = DECODE;
        else
          next_state = IDLE;
      DECODE:
        if(idu_send_valid && idu_receive_ready)
          next_state = IDLE;
        else
          next_state = DECODE;
    endcase
  end

  always @(posedge clk) begin
    if(rst) begin
      state                  <= 0;
      idu_send_ready         <= 0;
      instruction            <= 0;
      pc                     <= 0;
      idu_send_valid         <= 0;
      idu_send_to_ifu_valid  <= 1;
    end else begin
      if(next_state == DECODE) begin
        if(idu_send_ready == 0) begin
          idu_send_ready <= 1;
          instruction    <= instruction_input;
          pc             <= pc_input;
        end
        if(!conflict) begin
          idu_send_valid        <= 1;
          idu_send_to_ifu_valid <= 1;
        end else begin
          idu_send_valid        <= 0;
          idu_send_to_ifu_valid <= 0;
        end
      end else begin  // next_state == IDLE
        if(idu_send_valid) begin
          idu_send_valid        <= 0;
          idu_send_to_ifu_valid <= 0;
          idu_send_ready        <= 0;
        end
      end
    end
  end

  // reg         wait_for_decode_info;
  // always @(posedge clk) begin
  //   if(rst) begin
  //     state <= 0;
  //     idu_send_ready <= 0;
  //     instruction    <= 0;
  //     pc             <= 0;
  //   end
  //   else begin
  //     if(state == 0) begin
  //       if(idu_receive_valid) begin
  //         state          <= 1;
  //         idu_send_ready <= 1;
  //         instruction    <= instruction_input;
  //         pc             <= pc_input;
  //       end else  
  //         idu_send_ready <= 0;
  //     end else begin // state == 1
  //       if(idu_send_valid && idu_receive_ready) 
  //         state <= 0;
  //       else 
  //         idu_send_ready <= 0;
  //     end
  //   end
  // end

  // always @(posedge clk) begin
  //   if(rst) begin
  //     wait_for_decode_info   <= 0;
  //     idu_send_valid         <= 0;
  //     idu_send_to_ifu_valid  <= 1;
  //   end else begin
  //     if(wait_for_decode_info) begin
  //       if(idu_receive_ready) begin
  //         assert(idu_send_valid == 1);
  //         idu_send_valid <= 0;
  //         wait_for_decode_info <= 0;
  //       end
  //     end else begin
  //       if(((state == 0) && idu_receive_valid) || (state == 1)) begin
  //         if(!conflict) begin
  //           idu_send_valid <= 1;
  //           idu_send_to_ifu_valid <= 1;
  //           if(!idu_receive_ready) wait_for_decode_info <= 1;
  //         end else begin 
  //           idu_send_valid <= 0;
  //           idu_send_to_ifu_valid <= 0;
  //         end
  //       end else begin
  //         if(idu_send_valid && idu_receive_ready) idu_send_valid <= 0;
  //       end
  //     end
  //   end
  // end


  wire [2: 0] instruction_type;
  wire [31:0] immI, immU, immS, immJ, immB, immV;
  wire [31:0] immJa, immJb;

  MuxKeyWithDefault #(10, 7, 3) idu_i0 (instruction_type, instruction[6:0], 3'b0, {
    7'b0010111, `YSYX_23060059_TYPE_U,
    7'b0110111, `YSYX_23060059_TYPE_U,
    7'b0010011, `YSYX_23060059_TYPE_I,
    7'b0000011, `YSYX_23060059_TYPE_I,
    7'b1100111, `YSYX_23060059_TYPE_I,
    7'b1101111, `YSYX_23060059_TYPE_J,
    7'b0100011, `YSYX_23060059_TYPE_S,
    7'b0110011, `YSYX_23060059_TYPE_R,
    7'b1100011, `YSYX_23060059_TYPE_B,
    7'b1110011, `YSYX_23060059_TYPE_V
  });
  assign immI = {{20{instruction[31]}}, instruction[31:20]}; 
  assign immU = {{12{instruction[31]}}, instruction[31:12]} << 12;
  assign immS = ({{25{instruction[31]}}, instruction[31:25]} << 5) | {{27{1'b0}}, instruction[11:7]};
  assign immJa = {{31{instruction[31]}}, instruction[31:31]} << 20;
  assign immJb = {{12{1'b0}},instruction[19:12], instruction[20:20], instruction[30:21], 1'b0};
  assign immJ = immJa | immJb;
  assign immB = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
  assign immV = {{20{1'b0}}, instruction[31:20]};

  MuxKeyWithDefault #(6, 3, 32) idu_i1 (imm, instruction_type, 32'b0, {
    `YSYX_23060059_TYPE_U, immU,
    `YSYX_23060059_TYPE_I, immI,
    `YSYX_23060059_TYPE_J, immJ,
    `YSYX_23060059_TYPE_S, immS,
    `YSYX_23060059_TYPE_B, immB,
    `YSYX_23060059_TYPE_V, immV
  });

  // ecall 
  assign ecall = (instruction == 32'h73);
  // mret
  wire   mret;
  assign mret = (instruction == 32'h30200073);

  wire [1:0] csr_rsA;
  MuxKeyWithDefault #(4, 32, 2) idu_i25(csr_rsA, immV, 2'b11, {
    32'h342, 2'b00,
    32'h341, 2'b01,
    32'h300, 2'b10,
    32'h305, 2'b11    
  });
  assign csr_rs = (ecall == 1'b1) ? (2'b11) : ((mret == 1'b1) ? (2'b01) : csr_rsA); 
  assign csr_rd = (ecall == 1'b1) ? (2'b01) : csr_rsA;

  assign rs1  = instruction[19:15];
  assign rs2  = instruction[24:20];
  assign rd   = instruction[11:7];


  wire[4:0] aluOpU, aluOpI, aluOpIa, aluOpIb, aluOpIba,aluOpIc, aluOpJ, aluOpR, aluOpRa, aluOpRb, aluOpB, aluOpS, aluOpV;
  // aluOpU
  MuxKeyWithDefault #(2, 7, 5) idu_i2 (aluOpU, instruction[6:0], 5'b0, {
    7'b0010111, `YSYX_23060059_ADD,
    7'b0110111, `YSYX_23060059_IMM
  });
  // aluOpIa, aluOpIb, aluOpIc
  // aluOpIa
  assign aluOpIa = `YSYX_23060059_ADD;
  // aluOpIba
  MuxKeyWithDefault #(2, 6, 5) idu_i18(aluOpIba, instruction[31:26], `YSYX_23060059_SR, {
    6'b010000, `YSYX_23060059_SSR,
    6'b000000, `YSYX_23060059_SR
  });
  // aluOpIb
  MuxKeyWithDefault #(7, 3, 5) idu_i3 (aluOpIb, instruction[14:12], `YSYX_23060059_ADD, {
    3'b000, `YSYX_23060059_ADD ,
    3'b111, `YSYX_23060059_AND ,
    3'b100, `YSYX_23060059_XOR ,
    3'b101,  aluOpIba          , 
    3'b010, `YSYX_23060059_SLES,
    3'b011, `YSYX_23060059_ULES,
    3'b001, `YSYX_23060059_SL
  });
  // aluOpIc
  assign aluOpIc = `YSYX_23060059_ADD;
  // aluOpI
  MuxKeyWithDefault #(3, 7, 5) idu_i4 (aluOpI, instruction[6:0], aluOpIa, {
    7'b0000011, aluOpIa,
    7'b0010011, aluOpIb, 
    7'b1100111, aluOpIc
  });
  // aluOpJ
  assign aluOpJ = `YSYX_23060059_ADD;

  // aluOpS 
  assign aluOpS = `YSYX_23060059_ADD;

  MuxKeyWithDefault #(16, 10, 5) idu_i12(aluOpR, {instruction[31:25], instruction[14:12]}, 5'b0, {
    10'b0000000000, `YSYX_23060059_ADD,
    10'b0100000000, `YSYX_23060059_SUB,
    10'b0000001000, `YSYX_23060059_MUL,
    10'b0000001111, `YSYX_23060059_REMU,
    10'b0000000010, `YSYX_23060059_SLES,
    10'b0000000011, `YSYX_23060059_ULES,
    10'b0000000111, `YSYX_23060059_AND,
    10'b0000000100, `YSYX_23060059_XOR,
    10'b0000000110, `YSYX_23060059_OR,
    10'b0000000001, `YSYX_23060059_SL,
    10'b0100000101, `YSYX_23060059_SSR,
    10'b0000000101, `YSYX_23060059_SR,
    10'b0000001101, `YSYX_23060059_DIVU,
    10'b0000001110, `YSYX_23060059_REM,
    10'b0000001100, `YSYX_23060059_DIV,
    10'b0000001011, `YSYS_23060059_MULHU
  });

  // aluOpB 
  MuxKeyWithDefault #(5, 3, 5) idu_i17(aluOpB, instruction[14:12], `YSYX_23060059_SUB, {
    3'b111, `YSYX_23060059_ULES,
    3'b000, `YSYX_23060059_SUB,
    3'b101, `YSYX_23060059_SLES,
    3'b100, `YSYX_23060059_SLES,
    3'b110, `YSYX_23060059_ULES
  });

  // aluOpV
  MuxKeyWithDefault #(2, 3, 5) idu_i20(aluOpV, instruction[14:12], `YSYX_23060059_IMM, {
    3'b010, `YSYX_23060059_OR,
    3'b001, `YSYX_23060059_SRC
  });

  // aluOp
  MuxKeyWithDefault #(7, 3, 5) idu_i5 (aluOp, instruction_type, aluOpI, {
    `YSYX_23060059_TYPE_U, aluOpU,
    `YSYX_23060059_TYPE_I, aluOpI,
    `YSYX_23060059_TYPE_J, aluOpJ,
    `YSYX_23060059_TYPE_S, aluOpS,
    `YSYX_23060059_TYPE_R, aluOpR,
    `YSYX_23060059_TYPE_B, aluOpB,
    `YSYX_23060059_TYPE_V, aluOpV
  });

  // BOp
  MuxKeyWithDefault #(1, 7, 3) idu_i16 (BOp, instruction[6:0], 3'b010, {
    7'b1100011, instruction[14:12]
  });


  wire [1:0] pcOpA;
  // pcOp
  MuxKeyWithDefault #(3, 7, 2) idu_i6 (pcOpA, instruction[6:0], 2'b0, {
    7'b1100011, 2'b01,
    7'b1101111, 2'b01,
    7'b1100111, 2'b10
  });
  assign pcOp = ((mret | ecall) == 1'b1) ? 2'b11 : pcOpA;
  
  // src1Op
  MuxKeyWithDefault #(2, 7, 1) idu_i7(src1Op, instruction[6:0], 1'b0, {
    7'b0010111, 1'b1,
    7'b1101111, 1'b1
  });

  // src2Op
  MuxKeyWithDefault #(6, 7, 2) idu_i8 (src2Op, instruction[6:0], 2'b00, {
    7'b0010111, 2'b01,
    7'b0110111, 2'b01,
    7'b0000011, 2'b01,
    7'b0010011, 2'b01,
    7'b0100011, 2'b01,
    7'b1110011, 2'b10
  });

  // wdOpA
  wire [1:0] wdOpA;
  wire [1:0] wdOpB;
  MuxKeyWithDefault #(3, 7, 2) idu_i9 (wdOpA, instruction[6:0], 2'b0, {
    7'b0000011, 2'b01,
    7'b1101111, 2'b10,
    7'b1100111, 2'b10
  });
  // wdOpB
  MuxKeyWithDefault #(2, 10, 2) idu_i21 (wdOpB, {instruction[14:12], instruction[6:0]}, 2'b0, {
    10'b0101110011, 2'b11,
    10'b0011110011, 2'b11
  });
  assign wdOp = (instruction[6:0] == 7'b1110011) ? wdOpB : wdOpA;  

  // reg_write_en
  wire reg_write_enA;
  wire reg_write_enB;
  MuxKeyWithDefault #(2, 3, 1) idu_i10 (reg_write_enA, instruction_type, 1'b1, {
    `YSYX_23060059_TYPE_S, 1'b0,
    `YSYX_23060059_TYPE_B, 1'b0
  });
  MuxKeyWithDefault #(2, 10, 1) idu_i24 (reg_write_enB, {instruction[14:12], instruction[6:0]}, 1'b0, {
    10'b0101110011, 1'b1,
    10'b0011110011, 1'b1
  }); 
  assign reg_write_en = (instruction[6:0] == 7'b1110011) ? reg_write_enB : reg_write_enA;

  wire csreg_write_enA;
  // csreg_write_enA
  MuxKeyWithDefault #(2, 10, 1) idu_i22(csreg_write_enA, {instruction[14:12], instruction[6:0]}, 1'b0, {
    10'b0101110011, 1'b1,
    10'b0011110011, 1'b1
  });
  assign csreg_write_en = csreg_write_enA | ecall; // csrrs | csrrw | ecall 

  assign csrwdOp = ecall; // ecall : 1, csrwd choose pc, else choose exu_result;

  // ren
  MuxKeyWithDefault #(1, 7, 1) idu_i11(ren, instruction[6:0], 1'b0, {
    7'b0000011, 1'b1
  });

  // wmask 
  MuxKeyWithDefault #(3, 3, 8) idu_i15(wmask, instruction[14:12], 8'b00001111, {
    3'b000, 8'b00000001,
    3'b001, 8'b00000011,
    3'b010, 8'b00001111
  });

  // rmask 
  MuxKeyWithDefault #(5, 3, 32) idu_i19(rmask, instruction[14:12], 32'hffffffff, {
    3'b000, 32'hff,
    3'b100, 32'hff,
    3'b001, 32'hffff,
    3'b101, 32'hffff,
    3'b010, 32'hffffffff
  });

  // memory_read_signed 
  MuxKeyWithDefault #(2, 3, 1) idu_i23(memory_read_signed, instruction[14:12], 1'b0, {
    3'b000, 1'b1,
    3'b001, 1'b1
  });


  // wen
  assign wen = (instruction_type == `YSYX_23060059_TYPE_S);

  assign ebreak = (instruction == 32'h100073); // if the instruction is ebreak, end the simluation

  wire            src1Op;
  wire   [1 :0]   src2Op;

  MuxKeyWithDefault #(2, 1, 32) exsrc1(src1, src1Op, rsa, {
    1'b0, rsa,
    1'b1, pc
  });

  MuxKeyWithDefault #(3, 2, 32) exsrc2(src2, src2Op, rsb, {
    2'b00, rsb,
    2'b01, imm,
    2'b10, csra
  });


  wire [31:0]  Bresult;
  wire [31:0]  result_arr[3:0];
  wire         zero_arr[2:0];
  // ULES
  wire [32:0] ules_temp;
  assign ules_temp     = {1'b0, src1} - {1'b0, src2};
  assign result_arr[0] = {31'h0, ules_temp[32]};
  assign zero_arr[0]   = 0;

  // SUB
  assign result_arr[1] = src1 -src2;
  assign zero_arr[1] = result_arr[1] == 0;

  // SLES
  assign result_arr[2] = {31'h0, $signed(src1) < $signed(src2) };
  assign zero_arr[2] = 0;

  // ADD
  assign result_arr[3] = src1 + imm;

  wire       Bjump;
  wire [1:0] pcOpI;

  assign Bjump = (BOp == 3'b111) & (result_arr[0] == 32'h0)   |  // ULES
                 (BOp == 3'b000) & (zero_arr  [1] == 1)       |  // SUB
                 (BOp == 3'b101) & (result_arr[2] == 32'h0)   |  // SLES
                 (BOp == 3'b100) & (result_arr[2] == 32'h1)   |  // SLES
                 (BOp == 3'b110) & (result_arr[0] == 32'h1)   |  // ULES
                 (BOp == 3'b001) & (zero_arr  [1] == 0)  ;       // SUB
  // BOp = 3'b010 代表着不是一条B指令
  assign pcOpI = (BOp == 3'b010) ? pcOp : ((Bjump == 1) ? pcOp : 2'b00); 

  // pc choose
  MuxKeyWithDefault #(4, 2, 32) pcc (pc_next, pcOpI, pc+4, {
    2'b00, pc+4,
    2'b01, pc+imm,
    2'b10, result_arr[3]&(~1),
    2'b11, csra
  });

  assign pc_write_enable = idu_send_valid && idu_receive_ready;


  // ecall 
  wire   ecall_input;
  assign ecall_input = (instruction_input == 32'h73);
  // mret
  wire   mret_input;
  assign mret_input = (instruction_input == 32'h30200073);

  wire [1:0] csr_rsA_input;
  wire [31:0] immV_input;
  MuxKeyWithDefault #(4, 32, 2) idu_i26(csr_rsA_input, immV_input, 2'b11, {
    32'h342, 2'b00,
    32'h341, 2'b01,
    32'h300, 2'b10,
    32'h305, 2'b11    
  });

  wire   [1:0]  csr_rs_input;
  assign csr_rs_input = (ecall_input == 1'b1) ? (2'b11) : ((mret_input == 1'b1) ? (2'b01) : csr_rsA_input);

  wire   [4:0]  rs1_input;
  wire   [4:0]  rs2_input;
  wire   [4:0]  rd_input;
  assign rs1_input  = instruction_input[19:15];
  assign rs2_input  = instruction_input[24:20];
  assign rd_input   = instruction_input[11:7];

  wire   exu_conflict;
  wire   lsu_conflict;
  wire   wbu_conflict;
  wire   conflict;


  assign exu_conflict = (exu_state == 0) ? 0 : ((rs1_input == rd) || (rs2_input == rd) || (csr_rs_input == csr_rd));
  assign lsu_conflict = (lsu_state == 0) ? 0 : ((rs1_input == rd_lsu) || (rs2_input == rd_lsu) || (csr_rs_input == csr_rd_lsu));
  assign wbu_conflict = (wbu_state == 0) ? 0 : ((rs1_input == rd_lsu) || (rs2_input == rd_lsu) || (csr_rs_input == csr_rd_lsu));
  assign conflict = exu_conflict || lsu_conflict || wbu_conflict;

endmodule
