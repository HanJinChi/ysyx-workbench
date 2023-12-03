
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
  input    wire  [31:0]  instruction,
  input    wire  [31:0]  pc_input,
  input    wire  [31:0]  rsa,
  input    wire  [31:0]  rsb,
  input    wire  [31:0]  csra,
  input    wire          exu_state,
  input    wire  [31:0]  wd_exu,  // may be wd or csr_wd
  input    wire  [4 :0]  rd_lsu,
  input    wire  [1 :0]  csr_rd_lsu,
  input    wire          lsu_state,
  input    wire          wbu_state,
  input    wire  [4 :0]  rd_wbu,
  input    wire  [1 :0]  csr_rd_wbu,
  input    wire  [31:0]  wd_wbu,
  input    wire  [31:0]  csr_wd_wbu,
  input    wire          idu_receive_valid,
  input    wire          idu_receive_ready,
  output   wire  [4 :0]  rs1,
  output   wire  [4 :0]  rs2,
  output   wire  [1 :0]  csr_rs, 
  output   wire  [4 :0]  rd_o,
  output   wire  [1 :0]  csr_rd_o,
  output   wire  [31:0]  imm_o,
  output   wire  [1 :0]  pcOp_o,
  output   wire  [4 :0]  aluOp_o,
  output   wire  [31:0]  src1_o,
  output   wire  [31:0]  src2_o,
  output   wire  [1 :0]  wdOp_o,
  output   wire          csrwdOp_o,
  output   wire  [2 :0]  BOp_o,
  output   wire          ren_o,
  output   wire          wen_o,
  output   wire  [7 :0]  wmask_o,
  output   wire  [31:0]  rmask_o,
  output   wire          memory_read_signed_o,
  output   wire          reg_write_en_o,
  output   wire          csreg_write_en_o,
  output   wire          ecall_o, 
  output   wire          ebreak_o,
  output   wire  [31:0]  pc_next_o,
  output   wire          pc_write_enable,
  output   wire  [31:0]  pc_o,
  output   wire  [31:0]  instruction_o,
  output   wire          idu_send_to_ifu_valid,
  output   wire          idu_send_valid,
  output   wire          idu_send_ready
);

  parameter   IDLE = 0, DECODE = 1;
  reg         state, next_state;
  reg         idu_send_to_ifu_valid_r;
  reg         idu_send_valid_r;
  reg         idu_send_ready_r;
  reg  [31:0] instruction_o_r;
  reg  [31:0] pc_o_r;
  reg  [31:0] src1_o_r;
  reg  [31:0] src2_o_r;
  reg  [4 :0] rd_o_r;
  reg  [1 :0] csr_rd_o_r;
  reg  [31:0] imm_o_r;
  reg  [1 :0] pcOp_o_r;
  reg  [4 :0] aluOp_o_r;
  reg  [1 :0] wdOp_o_r;
  reg         csrwdOp_o_r;
  reg  [2 :0] BOp_o_r;
  reg         ren_o_r;
  reg         wen_o_r;
  reg  [7 :0] wmask_o_r;
  reg  [31:0] rmask_o_r;
  reg         memory_read_signed_o_r;
  reg         reg_write_en_o_r;
  reg         csreg_write_en_o_r;
  reg         ecall_o_r;
  reg         ebreak_o_r;
  reg  [31:0] pc_next_o_r;

  always @(posedge clk) begin
    if(rst) state <= IDLE;
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
      state                    <= 0;
      idu_send_ready_r         <= 0;
      instruction_o_r          <= 0;
      pc_o_r                   <= 0;
      idu_send_valid_r         <= 0;
      idu_send_to_ifu_valid_r  <= 1;
      src1_o_r                 <= 0;
      src2_o_r                 <= 0;
      rd_o_r                   <= 0;
      csr_rd_o_r               <= 0;
      imm_o_r                  <= 0;
      pcOp_o_r                 <= 0;
      aluOp_o_r                <= 0;
      wdOp_o_r                 <= 0;
      csrwdOp_o_r              <= 0;
      BOp_o_r                  <= 0;
      ren_o_r                  <= 0;
      wen_o_r                  <= 0;
      wmask_o_r                <= 0;
      rmask_o_r                <= 0;
      memory_read_signed_o_r   <= 0;
      reg_write_en_o_r         <= 0;
      csreg_write_en_o_r       <= 0;
      ecall_o_r                <= 0;
      ebreak_o_r               <= 0;
      pc_next_o_r              <= 0;
    end else begin
      if(next_state == DECODE) begin
        if(idu_send_ready_r == 0) begin
          idu_send_ready_r <= 1;
          instruction_o_r  <= instruction;
          pc_o_r           <= pc_input;
        end
        if(!conflict) begin
          idu_send_valid_r        <= 1;
          idu_send_to_ifu_valid_r <= 1;
          src1_o_r                <= src1_i_r;
          src2_o_r                <= src2_i_r;
          rd_o_r                  <= rd;
          csr_rd_o_r              <= csr_rd;
          imm_o_r                 <= imm;
          pcOp_o_r                <= pcOp;
          aluOp_o_r               <= aluOp;
          wdOp_o_r                <= wdOp;
          csrwdOp_o_r             <= csrwdOp;
          BOp_o_r                 <= BOp;
          ren_o_r                 <= ren;
          wen_o_r                 <= wen;
          wmask_o_r               <= wmask;
          rmask_o_r               <= rmask;
          memory_read_signed_o_r  <= memory_read_signed;
          reg_write_en_o_r        <= reg_write_en;
          csreg_write_en_o_r      <= csreg_write_en;
          ecall_o_r               <= ecall;
          ebreak_o_r              <= ebreak;
          pc_next_o_r             <= pc_next;
        end
      end else begin  // next_state == IDLE
        if(idu_send_valid_r) begin
          idu_send_valid_r        <= 0;
          idu_send_to_ifu_valid_r <= 0;
          idu_send_ready_r        <= 0;
        end
      end
    end
  end
  assign idu_send_ready         = idu_send_ready_r;
  assign instruction_o          = instruction_o_r;
  assign idu_send_to_ifu_valid  = idu_send_to_ifu_valid_r;
  assign idu_send_valid         = idu_send_valid_r;
  assign pc_o                   = pc_o_r;
  assign src1_o                 = src1_o_r;
  assign src2_o                 = src2_o_r;
  assign rd_o                   = rd_o_r;
  assign csr_rd_o               = csr_rd_o_r;
  assign imm_o                  = imm_o_r;
  assign pcOp_o                 = pcOp_o_r;
  assign aluOp_o                = aluOp_o_r;
  assign wdOp_o                 = wdOp_o_r;
  assign csrwdOp_o              = csrwdOp_o_r;
  assign BOp_o                  = BOp_o_r;
  assign ren_o                  = ren_o_r;
  assign wen_o                  = wen_o_r;
  assign wmask_o                = wmask_o_r;
  assign rmask_o                = rmask_o_r;
  assign memory_read_signed_o   = memory_read_signed_o_r;
  assign reg_write_en_o         = reg_write_en_o_r;
  assign csreg_write_en_o       = csreg_write_en_o_r;
  assign ecall_o                = ecall_o_r;
  assign ebreak_o               = ebreak_o_r;
  assign pc_next_o              = pc_next_o_r;

  wire  [2: 0]  instruction_type;
  wire  [31:0]  immI, immU, immS, immJ, immB, immV;
  wire  [31:0]  immJa, immJb;
  wire  [4 :0]  rd;
  wire  [1 :0]  csr_rd;
  wire  [31:0]  imm;
  wire  [1 :0]  pcOp;
  wire  [4 :0]  aluOp;
  wire  [31:0]  src1;
  wire  [31:0]  src2;
  wire  [1 :0]  wdOp;
  wire          csrwdOp;
  wire  [2 :0]  BOp;
  wire          ren;
  wire          wen;
  wire  [7 :0]  wmask;
  wire  [31:0]  rmask;
  wire          memory_read_signed;
  wire          reg_write_en;
  wire          csreg_write_en;
  wire          ecall;
  wire          ebreak;
  wire  [31:0]  pc_next;

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
    1'b1, pc_input
  });

  MuxKeyWithDefault #(3, 2, 32) exsrc2(src2, src2Op, rsb, {
    2'b00, rsb,
    2'b01, imm,
    2'b10, csra
  });

  reg  [31:0]   src1_i_r;
  reg  [31:0]   src2_i_r;
  reg  [31:0]   csra_i_a;

  always @(*) begin
    if(exu_state && csr_rs == csr_rd_o) begin
      csra_i_a = wd_exu;
    end else if(wbu_state && csr_rs == csr_rd_wbu) begin
      csra_i_a = csr_wd_wbu;
    end else begin
      csra_i_a = csra;
    end
  end

  always @(*) begin
    if(exu_state && rs1 == rd_o) begin
      src1_i_r = wd_exu;
    end else if(wbu_state && (rs1 == rd_wbu)) begin
      src1_i_r = wd_wbu;
    end else begin
      case(src1Op)
        1'b0:
          src1_i_r = rsa;
        1'b1:
          src1_i_r = pc_input;
        default: begin end
      endcase
    end
  end

  always @(*) begin
    if(exu_state && rs2 == rd_o) begin
      src2_i_r = wd_exu;
    end else if(wbu_state && (rs2 == rd_wbu)) begin
      src2_i_r = wd_wbu;
    end else begin
      case(src2Op) 
        2'b00:
          src2_i_r = rsb;
        2'b01:
          src2_i_r = imm;
        2'b10:
          src2_i_r = csra;
        default:
          src2_i_r = rsb;
      endcase
    end
  end


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
  MuxKeyWithDefault #(4, 2, 32) pcc (pc_next, pcOpI, pc_input+4, {
    2'b00, pc_input+4,
    2'b01, pc_input+imm,
    2'b10, result_arr[3]&(~1),
    2'b11, csra_i_a
  });

  assign pc_write_enable = idu_send_valid && idu_receive_ready;


  // wire   exu_conflict;
  wire   lsu_conflict;
  wire   conflict;


  // assign exu_conflict = (exu_state == 0) ? 0 : ((rs1_input == rd) || (rs2_input == rd) || (csr_rs_input == csr_rd));
  assign lsu_conflict = (lsu_state == 0) ? 0 : ((rs1 == rd_lsu) || (rs2 == rd_lsu) || (csr_rs == csr_rd_lsu));
  assign conflict = lsu_conflict ;

endmodule
