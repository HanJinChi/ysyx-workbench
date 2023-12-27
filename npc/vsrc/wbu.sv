module wbu(
    input           clk,
    input           rst,
    input           receive_valid,
    input   [4 :0]  rs1,
    input   [4 :0]  rs2,
    input   [1 :0]  csr_rs, // read csr reg
    input   [4 :0]  rd,     // write reg 
    input   [1 :0]  csr_rd, // write csr reg
    input   [31:0]  wd,
    input   [31:0]  csr_wd, 
    input           ebreak_i,
    input           reg_en,
    input           csreg_en,
    input           ecall,
    input   [31:0]  pc_i,
    input   [31:0]  pc_next_i,
    input   [31:0]  instruction_i,
    output  [31:0]  rsa,
    output  [31:0]  rsb,
    output  [31:0]  csra,
    output  [2 :0]  state_o,
    output          ebreak_o
);


  reg ebreak_o_r;
  always @(posedge clk) begin
    if(rst) ebreak_o_r <= 0;
    else  if(receive_valid) ebreak_o_r <= ebreak_i;
  end

  assign ebreak_o = ebreak_o_r;


  reg  ecall_r;
  always @(posedge clk) begin
    if(rst) ecall_r <= 0;
    else    ecall_r <= ecall;
  end

  reg  [31:0] instruction;
  wire [31:0] instruction_subsequent;
  wire [31:0] instruction_previous;

  Reg #(32, 32'b0) regp0(clk, rst, instruction_subsequent, instruction, receive_valid);

  assign instruction_previous = instruction;
  assign instruction_subsequent = instruction_i;

  reg  [31:0] pc;
  wire [31:0] pc_subsequent;
  wire [31:0] pc_previous;

  Reg #(32, 32'b0) regp1(clk, rst, pc_subsequent, pc, receive_valid);

  assign pc_previous = pc;
  assign pc_subsequent = pc_i;


  reg  [31:0] pc_next;
  wire [31:0] pc_next_subsequent;
  wire [31:0] pc_next_previous;

  Reg #(32, 32'b0) regp(clk, rst, pc_next_subsequent, pc_next, receive_valid);

  assign pc_next_previous = pc_next;
  assign pc_next_subsequent = pc_next_i;

  
  reg  [31:0] regarray [31:0];
  wire [31:0] w_regarray_subsequent[31:0]; // directly modify
  wire [31:0] w_regarray_previous[31:0];

  // reg 0: mcause, 1: mepc, 2: mstatus, 3: mtvec
  reg  [31:0] csrarray [3:0];
  wire [31:0] w_csrarray_subsequent[3:0];
  wire [31:0] w_csrarray_previous[3:0];

  genvar i;
  generate
      for(i = 0; i < 32; i = i+1) begin
        Reg #(32, 32'b0) regx(clk, rst, w_regarray_subsequent[i], regarray[i], receive_valid);
      end
  endgenerate

  generate
      for(i = 0; i < 4; i = i+1) begin
        Reg #(32, 32'b0) regx(clk, rst, w_csrarray_subsequent[i], csrarray[i], receive_valid);
      end
  endgenerate

  generate
    for(i = 0; i < 32; i = i+1) begin
      assign w_regarray_previous[i] = regarray[i];
    end
  endgenerate

  generate
    for(i = 0; i < 4; i = i+1) begin
      assign w_csrarray_previous[i] = csrarray[i];
    end
  endgenerate

  generate
    for(i = 1; i < 32; i = i+1) begin
      assign w_regarray_subsequent[i] = (reg_en == 1) ? ((rd == i) ? wd : w_regarray_previous[i]) : w_regarray_previous[i];
    end
  endgenerate

  generate
    for(i = 1; i < 4; i = i+1) begin
      assign w_csrarray_subsequent[i] = (csreg_en == 1) ? ((csr_rd == i) ? csr_wd : w_csrarray_previous[i]) : w_csrarray_previous[i];
    end
  endgenerate

  assign w_csrarray_subsequent[0] = (ecall == 1) ? (w_regarray_previous[15]) : ((csreg_en == 1) ? ((csr_rd == 0) ? csr_wd : w_csrarray_previous[0]) : w_csrarray_previous[0]);

  assign w_regarray_subsequent[0] = 32'b0;

  assign rsa  = regarray[rs1   ] ;
  assign rsb  = regarray[rs2   ] ;
  assign csra = csrarray[csr_rs] ;

  reg [2:0] state_o_r;
  always @(*) begin
    if(!receive_valid) begin
      state_o_r = 0;
    end else 
      state_o_r = {csreg_en, reg_en, 1'b1};
  end 
  
  assign state_o = state_o_r;


endmodule