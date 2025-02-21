`include "defines.v"

module ysyx_23060059_idu(
  input    wire          clock,
  input    wire          reset,
  input    wire  [31:0]  instruction_i,
  input    wire  [31:0]  pc_i,
  input    wire  [31:0]  rsa,
  input    wire  [31:0]  rsb,
  input    wire  [31:0]  csra,
  input    wire  [3 :0]  exu_state,
  input    wire  [31:0]  wd_exu,  // may be wd or csr_wd
  input    wire  [4 :0]  rd_lsu,
  input    wire  [1 :0]  csr_rd_lsu,
  input    wire          lsu_state,
  input    wire  [2 :0]  wbu_state,
  input    wire  [4 :0]  rd_wbu,
  input    wire  [1 :0]  csr_rd_wbu,
  input    wire  [31:0]  wd_wbu,
  input    wire  [31:0]  csr_wd_wbu,
  input    wire          reg_en_wbu,
  input    wire          csreg_en_wbu,
  input    wire          receive_valid,
  input    wire          receive_ready,
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
  output   wire  [31:0]  rsb_o,
  output   wire  [1 :0]  wdOp_o,
  output   wire          csrwdOp_o,
  output   wire  [2 :0]  BOp_o,
  output   wire          ren_o,
  output   wire          wen_o,
  output   wire  [7 :0]  wmask_o,
  output   wire  [31:0]  rmask_o,
  output   wire          m_signed_o,
  output   wire          reg_en_o,
  output   wire          csreg_en_o,
  output   wire          ecall_o, 
  output   wire          ebreak_o,
  output   wire  [31:0]  pc_next_o,
  output   wire          pc_write_enable,
  output   wire  [31:0]  pc_o,
  output   wire  [31:0]  instruction_o,
  output   wire          send_to_ifu_valid,
  output   wire          send_valid,
  output   wire          send_ready,
  // idu <-> dcache, icache
  input    wire          icache_bvalid,
  input    wire          dcache_bvalid,
  output   wire          cache_flush_valid,
  output   wire          cache_bready
);

  typedef enum [2:0] {IDLE, DECODE, WAIT, FENCE_I_A, FENCE_I_B} state_t;
  reg  [2:0]  state, next_state;
  reg         send_to_ifu_valid_r;
  reg         send_valid_r;


  always @(posedge clock) begin
    if(reset) state <= IDLE;
    else      state <= next_state;
  end

  always@(*) begin
    case(state)
      IDLE:
        if(receive_valid || buffer)
          if(fence_i)
            next_state = WAIT;
          else
            next_state = DECODE;
        else
          next_state = IDLE;
      DECODE:
        if(send_valid && receive_ready)
          next_state = IDLE;
        else
          next_state = DECODE;
      WAIT: // 等待lsu、wbu、exu的指令都执行完毕
        if(components_idle)
          next_state = FENCE_I_A;
        else
          next_state = WAIT;
      FENCE_I_A:
        if(icache_bvalid && dcache_bvalid)
          next_state = FENCE_I_B;
        else
          next_state = FENCE_I_A;
      FENCE_I_B:
        if(send_valid && receive_ready)
          next_state = IDLE;
        else
          next_state = FENCE_I_B;
      default: next_state = IDLE;
    endcase
  end

  reg  [31:0]  instruction_b;
  reg  [31:0]  pc_b;
  reg  [31:0]  instruction_t;
  reg  [31:0]  pc_t;
  reg          buffer;
  wire [31:0]  instruction;
  wire [31:0]  pc;
  always @(posedge clock) begin
    if(reset) begin
      instruction_b  <=  0;
    end else begin
      if(buffer == 0) begin
        if(receive_valid && (state != IDLE)) begin
          instruction_b <= instruction_i;
        end
      end
    end
  end

  always @(posedge clock) begin
    if(reset) begin
      pc_b  <=  0;
    end else begin
      if(buffer == 0) begin
        if(receive_valid && (state != IDLE)) begin
          pc_b <= pc_i;
        end
      end
    end
  end

  assign send_ready   = !buffer; // buffer长度为1时则不能再接受数据
  // assign instruction  = (next_state == DECODE && state == DECODE) ? instruction_t : (buffer ? instruction_b : instruction_i);
  // assign pc           = (next_state == DECODE && state == DECODE) ? pc_t          : (buffer ? pc_b           : pc_i);
  assign instruction  = (state == IDLE) ? (buffer ? instruction_b : instruction_i) : instruction_t;
  assign pc           = (state == IDLE) ? (buffer ? pc_b          : pc_i)          : pc_t;

  reg cache_bready_r;
  always @(posedge clock) begin
    if(reset) cache_bready_r <= 0;
    else begin
      if(next_state == FENCE_I_B) 
        cache_bready_r <= 1;
      else
        cache_bready_r <= 0;
    end
  end
  assign cache_bready = cache_bready_r;

  always @(posedge clock) begin
    if(reset) send_valid_r <= 0;
    else begin
      if(next_state == DECODE) begin
        if(!conflict)  send_valid_r <= 1;
      end 
      else if(next_state == FENCE_I_B) begin
        send_valid_r <= 1;
      end else 
        send_valid_r <= 0;
    end
  end

  always @(posedge clock) begin
    if(reset) send_to_ifu_valid_r <= 0;
    else begin
      if(next_state == DECODE) begin
        if(!conflict) send_to_ifu_valid_r <= 1;
      end
      else if(next_state == FENCE_I_B) begin
        send_to_ifu_valid_r <= 1;
      end else 
        send_to_ifu_valid_r <= 0;
    end
  end

  always @(posedge clock) begin
    if(reset) instruction_t <= 0;
    else begin
      if(next_state == DECODE || next_state == WAIT) begin
        if(receive_valid) instruction_t <= instruction_i; 
        else begin
          if(buffer) instruction_t <= instruction_b;
        end       
      end
    end
  end

  always @(posedge clock) begin
    if(reset) pc_t <= 0;
    else begin
      if(next_state == DECODE || next_state == WAIT) begin
        if(receive_valid) pc_t <= pc_i; 
        else begin
          if(buffer) pc_t <= pc_b;
        end       
      end
    end
  end

  always @(posedge clock) begin
    if(reset) buffer <= 0;
    else      begin
      if(buffer == 0) begin
        if(receive_valid && state!=IDLE)
          buffer <= 1;
      end else begin // buffer == 1
        if(next_state == DECODE) begin
          if(send_valid == 0 && !conflict)
            buffer <= 0;
        end 
        else if(next_state == FENCE_I_B)
          buffer <= 0;
      end
    end
  end

  reg cache_flush_valid_r;
  always @(posedge clock) begin
    if(reset) cache_flush_valid_r <= 0;
    else begin
      if(next_state == FENCE_I_A)
        cache_flush_valid_r <= 1;
      else
        cache_flush_valid_r <= 0;
    end
  end
  assign cache_flush_valid = cache_flush_valid_r;

  reg idu_to_exu_en;
  always @(*) begin
    if(next_state == DECODE && (send_valid == 0) && !conflict) 
      idu_to_exu_en = 1;
    else
      if(next_state == FENCE_I_B && (send_valid == 0))
        idu_to_exu_en = 1;
      else
        idu_to_exu_en = 0;
  end

  assign send_valid           = send_valid_r;
  assign send_to_ifu_valid    = send_to_ifu_valid_r;

  Reg #(32, 32'h0) regd0 (clock, reset, instruction, instruction_o, idu_to_exu_en);
  Reg #(32, 32'h0) regd1 (clock, reset, pc,          pc_o         , idu_to_exu_en);
  Reg #(32, 32'h0) regd2 (clock, reset, src1_i_r,    src1_o       , idu_to_exu_en);
  Reg #(32, 32'h0) regd3 (clock, reset, src2_i_r,    src2_o       , idu_to_exu_en);
  Reg #(5,  5 'h0) regd4 (clock, reset, rd,          rd_o         , idu_to_exu_en);
  Reg #(2,  2 'h0) regd5 (clock, reset, csr_rd,      csr_rd_o     , idu_to_exu_en);
  Reg #(32, 32'h0) regd6 (clock, reset, imm,         imm_o        , idu_to_exu_en);
  Reg #(2,  2 'h0) regd7 (clock, reset, pcOp,        pcOp_o       , idu_to_exu_en);
  Reg #(5,  5 'h0) regd8 (clock, reset, aluOp,       aluOp_o      , idu_to_exu_en);
  Reg #(2,  2 'h0) regd9 (clock, reset, wdOp,        wdOp_o       , idu_to_exu_en);
  Reg #(1,  1 'h0) regd10(clock, reset, csrwdOp,     csrwdOp_o    , idu_to_exu_en);
  Reg #(3,  3 'h0) regd11(clock, reset, BOp,         BOp_o        , idu_to_exu_en);
  Reg #(1,  1 'h0) regd12(clock, reset, ren,         ren_o        , idu_to_exu_en);
  Reg #(1,  1 'h0) regd13(clock, reset, wen,         wen_o        , idu_to_exu_en);
  Reg #(8,  8 'h0) regd14(clock, reset, wmask,       wmask_o      , idu_to_exu_en);
  Reg #(32, 32'h0) regd15(clock, reset, rmask,       rmask_o      , idu_to_exu_en);
  Reg #(1,  1 'h0) regd16(clock, reset, m_signed,    m_signed_o   , idu_to_exu_en);
  Reg #(1,  1 'h0) regd17(clock, reset, reg_en,      reg_en_o     , idu_to_exu_en);
  Reg #(1,  1 'h0) regd18(clock, reset, csreg_en,    csreg_en_o   , idu_to_exu_en);
  Reg #(1,  1 'h0) regd19(clock, reset, ecall,       ecall_o      , idu_to_exu_en);
  Reg #(1,  1 'h0) regd20(clock, reset, ebreak,      ebreak_o     , idu_to_exu_en);
  Reg #(32, 32'h0) regd21(clock, reset, pc_next,     pc_next_o    , idu_to_exu_en);
  Reg #(32, 32'h0) regd22(clock, reset, rsb_i_r,     rsb_o        , idu_to_exu_en);

  reg    lsu_conflict;
  reg    exu_conflict;
  wire   conflict;
  always @(*) begin // 第0bit代表state, 第1bit代表next_state
    if(exu_state[0] == 0 && exu_state[1] == 1 && ((rs1 == rd_o)|| (rs2 == rd_o) || (csr_rs == csr_rd_o)))
      exu_conflict = 1;
    else
      exu_conflict = 0;
  end

  always @(*) begin
    if(lsu_state && ((rs1 == rd_lsu) || (rs2 == rd_lsu) || (csr_rs == csr_rd_lsu)))
      lsu_conflict = 1;
    else
      lsu_conflict = 0;
  end

  assign conflict = lsu_conflict | exu_conflict;

  reg  [31:0]   src1_i_r;
  reg  [31:0]   src2_i_r;
  reg  [31:0]   rsb_i_r;
  reg  [31:0]   csra_i_a;

  always @(*) begin
    if(exu_state[0] && exu_state[3] && (csr_rs == csr_rd_o)) begin
      csra_i_a = wd_exu;
    end else if(wbu_state[2] && csr_rs == csr_rd_wbu) begin
      csra_i_a = csr_wd_wbu;
    end else begin
      csra_i_a = csra;
    end
  end

  always @(*) begin
    if(exu_state[0] && exu_state[2] && (rs1 != 0) && (rs1 == rd_o) && src1Op == 0) begin
      if(exu_state[3])    // 比较特殊的情况为csrrs和csrrw指令，这时候 exu_state的第3bit和第4bit都为1,EXU输出的结果不是wd的结果而是csrwd的结果，exu的src2才是真正写入的结果
        src1_i_r = src2_o;
      else
        src1_i_r = wd_exu; 
    end else if(wbu_state[1] && (rs1 != 0) && (rs1 == rd_wbu) && src1Op == 0) begin
      src1_i_r = wd_wbu;
    end else begin
      case(src1Op)
        1'b0:
          src1_i_r = rsa;
        1'b1:
          src1_i_r = pc;
        default: begin end
      endcase
    end
  end

  always @(*) begin
    if(exu_state[0] && exu_state[2] && (rs2 != 0) && (rs2 == rd_o) && (src2Op == 2'b00)) begin 
      if(exu_state[3])
        src2_i_r = src2_o;
      else
        src2_i_r = wd_exu;
    end else if(wbu_state[1] && (rs2 != 0) && (rs2 == rd_wbu) && (src2Op == 2'b00)) begin
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

  always @(*) begin
    if(exu_state[0] && exu_state[2] && (rs2 != 0) && (rs2 == rd_o)) begin
      if(exu_state[3])
        rsb_i_r = src2_o;
      else
        rsb_i_r = wd_exu;
    end else if(wbu_state[1] && (rs2 != 0) && (rs2 == rd_wbu)) begin
      rsb_i_r = wd_wbu;
    end else begin
      rsb_i_r = rsb;
    end
  end

  wire   components_idle;
  assign components_idle = (exu_state[0]==0) && (exu_state[1]==0) && (lsu_state==0) && (wbu_state[0]==0);


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
  wire          m_signed;
  wire          reg_en;
  wire          csreg_en;
  wire          ecall;
  wire          ebreak;
  wire          fence_i;
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
  assign ecall   = (instruction == 32'h73);
  // mret
  wire   mret;
  assign mret    = (instruction == 32'h30200073);
  // fence
  assign fence_i = (instruction == 32'h100f); 

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
  MuxKeyWithDefault #(8, 3, 5) idu_i3 (aluOpIb, instruction[14:12], `YSYX_23060059_ADD, {
    3'b000, `YSYX_23060059_ADD ,
    3'b111, `YSYX_23060059_AND ,
    3'b100, `YSYX_23060059_XOR ,
    3'b101,  aluOpIba          , 
    3'b010, `YSYX_23060059_SLES,
    3'b011, `YSYX_23060059_ULES,
    3'b001, `YSYX_23060059_SL  ,
    3'b110, `YSYX_23060059_OR
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
    10'b0000001011, `YSYX_23060059_MULHU
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

  // reg_en
  wire reg_enA;
  wire reg_enB;
  MuxKeyWithDefault #(2, 3, 1) idu_i10 (reg_enA, instruction_type, 1'b1, {
    `YSYX_23060059_TYPE_S, 1'b0,
    `YSYX_23060059_TYPE_B, 1'b0
  });
  MuxKeyWithDefault #(2, 10, 1) idu_i24 (reg_enB, {instruction[14:12], instruction[6:0]}, 1'b0, {
    10'b0101110011, 1'b1,
    10'b0011110011, 1'b1
  }); 
  assign reg_en = (instruction[6:0] == 7'b1110011) ? reg_enB : reg_enA;

  wire csreg_enA;
  // csreg_enA
  MuxKeyWithDefault #(2, 10, 1) idu_i22(csreg_enA, {instruction[14:12], instruction[6:0]}, 1'b0, {
    10'b0101110011, 1'b1,
    10'b0011110011, 1'b1
  });
  assign csreg_en = csreg_enA | ecall; // csrrs | csrrw | ecall 

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

  // m_signed 
  MuxKeyWithDefault #(2, 3, 1) idu_i23(m_signed, instruction[14:12], 1'b0, {
    3'b000, 1'b1,
    3'b001, 1'b1
  });


  // wen
  assign wen    = (instruction_type == `YSYX_23060059_TYPE_S);

  assign ebreak = (instruction == 32'h100073); // if the instruction is ebreak, end the simluation

  wire            src1Op;
  wire   [1 :0]   src2Op;

  wire [31:0]  result_arr[3:0];
  wire         zero_arr[2:0];
  // ULES
  wire [32:0] ules_temp;
  assign ules_temp     = {1'b0, src1_i_r} - {1'b0, src2_i_r};
  assign result_arr[0] = {31'h0, ules_temp[32]};
  assign zero_arr[0]   = 0;

  // SUB
  assign result_arr[1] = src1_i_r -src2_i_r;
  assign zero_arr[1] = result_arr[1] == 0;

  // SLES
  assign result_arr[2] = {31'h0, $signed(src1_i_r) < $signed(src2_i_r) };
  assign zero_arr[2] = 0;

  // ADD
  assign result_arr[3] = src1_i_r + imm;

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
    2'b11, csra_i_a
  });

  assign pc_write_enable = send_valid;


endmodule