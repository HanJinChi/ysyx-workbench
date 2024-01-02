module lsu (
  input    wire          clk,
  input    wire          rst,
  input    wire          receive_valid,
  input    wire          ren_i,
  input    wire          wen_i,
  input    wire          m_signed_i,
  input    wire  [7 :0]  wmask_i,
  input    wire  [31:0]  rmask_i,
  input    wire  [31:0]  result_i,
  input    wire  [31:0]  pc_i,
  input    wire  [31:0]  pc_next_i,
  input    wire  [31:0]  instruction_i,
  input    wire  [31:0]  src2_i,
  input    wire  [31:0]  rsb_i,
  input    wire  [1 :0]  wdOp_i,
  input    wire          csrwdOp_i,
  input    wire  [4 :0]  rd_i,
  input    wire  [1 :0]  csr_rd_i,
  input    wire          reg_en_i,
  input    wire          csreg_en_i,
  input    wire          ecall_i,
  input    wire          ebreak_i,
  input    wire          arready,
  input    wire  [31:0]  rdata,
  input    wire  [1 :0]  rresp,
  input    wire          rvalid,
  input    wire          awready,
  input    wire          wready,
  input    wire          bvalid,
  input    wire  [1 :0]  bresp,
  output   wire          send_valid,
  output   wire          send_ready,
  output   wire  [31:0]  wd_o,
  output   wire  [31:0]  csr_wd_o,
  output   wire  [4 :0]  rd_o,
  output   wire  [4 :0]  rd_lsu_to_idu,
  output   wire  [31:0]  pc_o,
  output   wire  [31:0]  instruction_o,
  output   wire  [31:0]  pc_next_o,
  output   wire  [1 :0]  csr_rd_o,
  output   wire  [1 :0]  csr_rd_lsu_to_idu,
  output   wire          reg_en_o,
  output   wire          csreg_en_o,
  output   wire          ecall_o,
  output   wire          ebreak_o,
  output   wire          skip_d_o,
  output   wire  [31:0]  araddr,
  output   wire          arvalid,
  output   wire          rready,
  output   wire  [31:0]  awaddr,
  output   wire          awvalid,
  output   wire          wvalid,
  output   wire          bready,
  output   wire  [31:0]  wdata,
  output   wire  [7 :0]  wstrb,
  output   wire          lsu_state
);
  reg [2:0]  state, next_state;
  parameter  IDLE = 0, MEM_READ_A = 1, MEM_READ_B = 2, MEM_WRITE_A = 3, MEM_WRITE_B = 4, MEM_NULL = 5;

  always @(posedge clk) begin
    if(rst) state <= IDLE;
    else    state <= next_state;
  end

  always @(*) begin
    case(state)
      IDLE:
        if(receive_valid || buffer) begin
          if(ren_v) 
            next_state = MEM_READ_A;
          else if(wen_v)
            next_state = MEM_WRITE_A;
          else
            next_state = MEM_NULL;
        end
      MEM_READ_A:
        if(arvalid && arready) 
          next_state = MEM_READ_B;
        else 
          next_state = MEM_READ_A;
      MEM_READ_B:
        if(rvalid && rready && (rresp == 0))
          next_state = MEM_NULL;
        else 
          next_state = MEM_READ_B;
      MEM_WRITE_A:
        if(awvalid && awready)
          next_state = MEM_WRITE_B;
        else
          next_state = MEM_WRITE_A;
      MEM_WRITE_B:
        if(bvalid && bready && (bresp == 0))
          next_state = MEM_NULL;
        else
          next_state = MEM_WRITE_B;
      MEM_NULL:
        if(send_valid)
          next_state = IDLE;
        else
          next_state = MEM_NULL;
    endcase
  end


  reg buffer_en;
  reg buffer;

  always @(posedge clk) begin
    if(rst) begin
      buffer <= 0;
    end else begin
      if(buffer == 0) begin
        if(receive_valid && (state != IDLE)) begin
          buffer  <= 1;
        end
      end
    end
  end

  always @(*) begin
    if(buffer == 0 && receive_valid && (state != IDLE)) 
      buffer_en = 1;
    else 
      buffer_en = 0; 
  end


  wire  [31:0] exu_result_b;
  wire  [31:0] pc_b;
  wire  [31:0] pc_next_b;
  wire  [31:0] instruction_b;
  wire         m_signed_b;
  wire  [31:0] rmask_b;
  wire         ecall_b;
  wire         ebreak_b;
  wire  [31:0] src2_b;
  wire  [31:0] rsb_b;
  wire  [1 :0] wdOp_b;
  wire         csrwdOp_b;
  wire  [4 :0] rd_b;
  wire  [1 :0] csr_rd_b;
  wire         reg_en_b;
  wire         csreg_en_b;
  wire  [7 :0] wmask_b;   
  wire         ren_b;
  wire         wen_b;

  Reg #(32, 32'h0) regd0 (clk, rst, result_i,  exu_result_b,  buffer_en);
  Reg #(32, 32'h0) regd1 (clk, rst, pc_i,          pc_b,          buffer_en);
  Reg #(32, 32'h0) regd2 (clk, rst, pc_next_i,     pc_next_b,     buffer_en);
  Reg #(32, 32'h0) regd3 (clk, rst, instruction_i, instruction_b, buffer_en);
  Reg #(1,  1 'h0) regd4 (clk, rst, m_signed_i,    m_signed_b,    buffer_en);
  Reg #(32, 32'h0) regd5 (clk, rst, rmask_i,       rmask_b,       buffer_en);
  Reg #(1,  1 'h0) regd6 (clk, rst, ecall_i,       ecall_b,       buffer_en);
  Reg #(1,  1 'h0) regd7 (clk, rst, ebreak_i,      ebreak_b,      buffer_en);
  Reg #(32, 32'h0) regd8 (clk, rst, src2_i,        src2_b,        buffer_en);
  Reg #(32, 32'h0) regd9 (clk, rst, rsb_i,         rsb_b,         buffer_en);
  Reg #(2,  2 'h0) regd10(clk, rst, wdOp_i,        wdOp_b,        buffer_en);
  Reg #(1,  1 'h0) regd11(clk, rst, csrwdOp_i,     csrwdOp_b,     buffer_en);
  Reg #(5,  5 'h0) regd12(clk, rst, rd_i,          rd_b,          buffer_en);
  Reg #(2,  2 'h0) regd13(clk, rst, csr_rd_i,      csr_rd_b,      buffer_en);
  Reg #(1,  1 'h0) regd14(clk, rst, reg_en_i,      reg_en_b,      buffer_en);
  Reg #(1,  1 'h0) regd15(clk, rst, csreg_en_i,    csreg_en_b,    buffer_en);
  Reg #(8,  8 'h0) regd16(clk, rst, wmask_i,       wmask_b,       buffer_en);
  Reg #(1,  1 'h0) regd30(clk, rst, ren_i,         ren_b,         buffer_en);
  Reg #(1,  1 'h0) regd31(clk, rst, wen_i,         wen_b,         buffer_en);


  wire  [31:0]  exu_result;
  wire  [31:0]  src2;
  wire  [1 :0]  wdOp;
  wire          csrwdOp;
  wire  [31:0]  mread;
  wire          ren;
  wire          wen;

  reg           m_signed;
  reg  [31:0]   rmask;
  reg  [31:0]   reg_rdata;

  reg          send_valid_r;
  reg  [31:0]  araddr_r;
  reg          arvalid_r;
  reg          rready_r;
  reg  [31:0]  awaddr_r;
  reg          awvalid_r;
  reg          wvalid_r;
  reg          bready_r;
  reg  [31:0]  wdata_r;
  reg  [7 :0]  wstrb_r;    

  always @(posedge clk) begin
    if(rst) begin
      send_valid_r   <= 0;
      m_signed           <= 0;
      rmask              <= 0;
      araddr_r           <= 0;
      arvalid_r          <= 0;
      wdata_r            <= 0;
      wstrb_r            <= 0;
      awaddr_r           <= 0;
      awvalid_r          <= 0;
      wvalid_r           <= 0;
    end else begin
      if(next_state == IDLE) begin
        if(send_valid_r) begin
          send_valid_r <= 0;
        end
      end else begin
        if(next_state == MEM_READ_A) begin
          if(arvalid_r == 0) begin
            arvalid_r            <= 1;
            araddr_r             <= exu_result_v;
            m_signed             <= m_signed_v;
            rmask                <= rmask_v;
            if(buffer)
              buffer             <= 0;
          end
        end else if(next_state == MEM_READ_B) begin
          arvalid_r <= 0;
        end else if(next_state == MEM_WRITE_A) begin
          if(awvalid_r == 0) begin
            awvalid_r           <= 1;
            awaddr_r            <= exu_result_v; 
            wvalid_r            <= 1;
            wstrb_r             <= wmask_v;
            wdata_r             <= rsb_v;
            if(buffer)
              buffer            <= 0;
          end
        end else if(next_state == MEM_WRITE_B) begin
          awvalid_r <= 0;
          wvalid_r  <= 0; 
        end else begin  // MEM_NULL 
          if(send_valid_r == 0) begin
            send_valid_r <= 1;
            if(rvalid) begin
              reg_rdata <= rdata;  // MEM_READ_B -> MEM_NULL
            end else if(!bvalid) begin  // IDLE -> MEM_NULL
              if(buffer)
                buffer             <= 0;
            end
          end
        end
      end
    end
  end

  assign send_valid   = send_valid_r;
  assign send_ready   = !buffer;

  reg lsu_to_wbu_en;
  always @(*) begin
    if(next_state == MEM_NULL && send_valid_r == 0) begin
      lsu_to_wbu_en = 1;
    end else
      lsu_to_wbu_en = 0;
  end

  Reg #(32, 32'h0) regd17 (clk, rst, pc_v,          pc_o,          lsu_to_wbu_en);
  Reg #(32, 32'h0) regd18 (clk, rst, pc_next_v,     pc_next_o,     lsu_to_wbu_en);
  Reg #(32, 32'h0) regd19 (clk, rst, instruction_v, instruction_o, lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd20 (clk, rst, ecall_v,       ecall_o,       lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd21 (clk, rst, ebreak_v,      ebreak_o,      lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd22 (clk, rst, reg_en_v,      reg_en_o,      lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd23 (clk, rst, csreg_en_v,    csreg_en_o,    lsu_to_wbu_en);
  Reg #(5,  5 'h0) regd27 (clk, rst, rd_v,          rd_o,          lsu_to_wbu_en);
  Reg #(2,  2 'h0) regd28 (clk, rst, csr_rd_v,      csr_rd_o,      lsu_to_wbu_en);

  Reg #(32, 32'h0) regd24 (clk, rst, src2_v,        src2,          lsu_to_wbu_en);
  Reg #(2,  2 'h0) regd25 (clk, rst, wdOp_v,        wdOp,          lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd26 (clk, rst, csrwdOp_v,     csrwdOp,       lsu_to_wbu_en);
  Reg #(32, 32'h0) regd29 (clk, rst, exu_result_v,  exu_result,    lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd32 (clk, rst, ren_v,         ren,           lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd33 (clk, rst, wen_v,         wen,           lsu_to_wbu_en);

  MuxKeyWithDefault #(3, 32, 32) rwd(mread, rmask, 32'h0, {
    32'h000000ff, m_signed ? {{24{reg_rdata[7]}} , reg_rdata[7:0]}  : reg_rdata & rmask,
    32'h0000ffff, m_signed ? {{16{reg_rdata[15]}}, reg_rdata[15:0]} : reg_rdata & rmask,
    32'hffffffff, reg_rdata
  });
  // wd choose
  MuxKeyWithDefault #(4, 2, 32) wdc (wd_o, wdOp, exu_result, {
    2'b00, exu_result,
    2'b01, mread,
    2'b10, pc_o+4,
    2'b11, src2
  });

  MuxKeyWithDefault #(2, 1, 32) csrwdc (csr_wd_o, csrwdOp, exu_result, {
    1'b0, exu_result,
    1'b1, pc_o
  });

  assign skip_d_o = (exu_result == 32'ha00003f8) && (ren || wen);

  wire  [31:0] exu_result_v;
  wire  [31:0] pc_v;
  wire  [31:0] pc_next_v;
  wire  [31:0] instruction_v;
  wire         m_signed_v;
  wire  [31:0] rmask_v;
  wire         ecall_v;
  wire         ebreak_v;
  wire  [31:0] src2_v;
  wire  [31:0] rsb_v;
  wire  [1 :0] wdOp_v;
  wire         csrwdOp_v;
  wire  [4 :0] rd_v;
  wire  [1 :0] csr_rd_v;
  wire         reg_en_v;
  wire         csreg_en_v;
  wire  [7 :0] wmask_v;
  wire         ren_v;
  wire         wen_v;

  assign exu_result_v  = buffer ? exu_result_b  : result_i;
  assign pc_v          = buffer ? pc_b          : pc_i;
  assign pc_next_v     = buffer ? pc_next_b     : pc_next_i;
  assign instruction_v = buffer ? instruction_b : instruction_i;
  assign m_signed_v    = buffer ? m_signed_b    : m_signed_i;
  assign rmask_v       = buffer ? rmask_b       : rmask_i;
  assign ecall_v       = buffer ? ecall_b       : ecall_i;
  assign ebreak_v      = buffer ? ebreak_b      : ebreak_i;
  assign src2_v        = buffer ? src2_b        : src2_i;
  assign rsb_v         = buffer ? rsb_b         : rsb_i;
  assign wdOp_v        = buffer ? wdOp_b        : wdOp_i;
  assign csrwdOp_v     = buffer ? csrwdOp_b     : csrwdOp_i;
  assign rd_v          = buffer ? rd_b          : rd_i;
  assign csr_rd_v      = buffer ? csr_rd_b      : csr_rd_i;
  assign reg_en_v      = buffer ? reg_en_b      : reg_en_i;
  assign csreg_en_v    = buffer ? csreg_en_b    : csreg_en_i;
  assign wmask_v       = buffer ? wmask_b       : wmask_i;
  assign ren_v         = buffer ? ren_b         : ren_i;
  assign wen_v         = buffer ? wen_b         : wen_i; 


  assign send_valid   = send_valid_r;
  assign send_ready   = !buffer; // buffer

  assign araddr         = araddr_r;
  assign arvalid        = arvalid_r;
  assign rready         = rready_r;
  assign awaddr         = awaddr_r;
  assign awvalid        = awvalid_r;
  assign wvalid         = wvalid_r;
  assign bready         = bready_r;
  assign wdata          = wdata_r;
  assign wstrb          = wstrb_r;

  always @(posedge clk) begin
    if(rst) rready_r <= 0;
    else    rready_r <= 1;
  end

  always @(posedge clk) begin
    if(rst) bready_r <= 0;
    else    bready_r <= 1;
  end 

  assign  lsu_state = (next_state != IDLE);
  assign  rd_lsu_to_idu = (state == IDLE) ? rd_v : rd_o;
  assign  csr_rd_lsu_to_idu = (state == IDLE) ? csr_rd_v : csr_rd_o;


endmodule