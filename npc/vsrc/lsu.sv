module lsu (
  input    wire          clk,
  input    wire          rst,
  input    wire          lsu_receive_valid,
  input    wire          ren_input,
  input    wire          wen_input,
  input    wire          memory_read_signed_input,
  input    wire  [7 :0]  wmask_input,
  input    wire  [31:0]  rmask_input,
  input    wire  [31:0]  exu_result_input,
  input    wire  [31:0]  pc_input,
  input    wire  [31:0]  pc_next_input,
  input    wire  [31:0]  instruction_input,
  input    wire  [31:0]  src2_input,
  input    wire  [31:0]  rsb_input,
  input    wire  [1 :0]  wdOp_input,
  input    wire          csrwdOp_input,
  input    wire  [4 :0]  rd_input,
  input    wire  [1 :0]  csr_rd_input,
  input    wire          reg_write_en_input,
  input    wire          csreg_write_en_input,
  input    wire          ecall_input,
  input    wire          ebreak_input,
  input    wire          arready,
  input    wire  [31:0]  rdata,
  input    wire  [1 :0]  rresp,
  input    wire          rvalid,
  input    wire          awready,
  input    wire          wready,
  input    wire          bvalid,
  input    wire  [1 :0]  bresp,
  output   wire          lsu_send_valid,
  output   wire          lsu_send_ready,
  output   wire  [31:0]  wd,
  output   wire  [31:0]  csr_wd,
  output   wire  [4 :0]  rd,
  output   wire  [31:0]  pc,
  output   wire  [31:0]  instruction,
  output   wire  [31:0]  pc_next,
  output   wire  [1 :0]  csr_rd,
  output   wire          reg_write_en,
  output   wire          csreg_write_en,
  output   wire          ecall,
  output   wire          ebreak,
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
        if(lsu_receive_valid) begin
          if(ren_input) 
            next_state = MEM_READ_A;
          else if(wen_input)
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
        if(lsu_send_valid)
          next_state = IDLE;
        else
          next_state = MEM_NULL;
    endcase
  end

  reg          memory_read_signed;
  reg  [31:0]  exu_result;
  reg  [31:0]  src2;
  reg  [31:0]  rsb;
  reg  [1 :0]  wdOp;
  reg          csrwdOp;
  reg  [31:0]  rmask;
  wire [31:0]  memory_read_wd;
  reg  [31:0]  reg_read_data;

  reg          lsu_send_valid_r;
  reg          lsu_send_ready_r;
  reg  [4 :0]  rd_r;
  reg  [31:0]  pc_r;
  reg  [31:0]  instruction_r;
  reg  [31:0]  pc_next_r;
  reg  [1 :0]  csr_rd_r;
  reg          reg_write_en_r;
  reg          csreg_write_en_r;
  reg          ecall_r;
  reg          ebreak_r;
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
      state              <= 0;
      lsu_send_ready_r   <= 0;
      lsu_send_valid_r   <= 0;
      memory_read_signed <= 0;
      exu_result         <= 0;
      rmask              <= 0;
      pc_r               <= 0;
      src2               <= 0;
      wdOp               <= 0;
      csrwdOp            <= 0;
      rd_r               <= 0;
      csr_rd_r           <= 0;
      reg_write_en_r     <= 0;
      csreg_write_en_r   <= 0;
      ecall_r            <= 0;
      ebreak_r           <= 0;
      instruction_r      <= 0;
      pc_next_r          <= 0;
      rsb                <= 0;
      araddr_r           <= 0;
      arvalid_r          <= 0;
      wdata_r            <= 0;
      wstrb_r            <= 0;
      awaddr_r           <= 0;
      awvalid_r          <= 0;
      wvalid_r           <= 0;
    end else begin
      if(next_state == IDLE) begin
        if(lsu_send_valid_r) begin
          lsu_send_valid_r <= 0;
          lsu_send_ready_r <= 0;
        end
      end else begin
        if(next_state == MEM_READ_A) begin
          if(arvalid_r == 0) begin
            lsu_send_ready_r     <= 1;
            arvalid_r            <= 1;
            araddr_r             <= exu_result_input;
            pc_r                 <= pc_input;
            pc_next_r            <= pc_next_input;
            instruction_r        <= instruction_input;
            memory_read_signed   <= memory_read_signed_input;
            rmask                <= rmask_input;
            ecall_r              <= ecall_input;
            ebreak_r             <= ebreak_input;
            src2                 <= src2_input;
            rsb                  <= rsb_input;
            wdOp                 <= wdOp_input;
            csrwdOp              <= csrwdOp_input;
            rd_r                 <= rd_input;
            csr_rd_r             <= csr_rd_input;
            reg_write_en_r       <= reg_write_en_input;
            csreg_write_en_r     <= csreg_write_en_input;
          end
          else
            lsu_send_ready_r <= 0;
        end else if(next_state == MEM_READ_B) begin
          arvalid_r <= 0;
          lsu_send_ready_r <= 0;
        end else if(next_state == MEM_WRITE_A) begin
          if(awvalid_r == 0) begin
            lsu_send_ready_r    <= 1;
            awvalid_r           <= 1;
            awaddr_r            <= exu_result_input; 
            wvalid_r            <= 1;
            wstrb_r             <= wmask_input;
            wdata_r             <= rsb_input;
            pc_r                <= pc_input;
            pc_next_r           <= pc_next_input;
            instruction_r       <= instruction_input;
            ecall_r             <= ecall_input;
            ebreak_r            <= ebreak_input;
            reg_write_en_r      <= reg_write_en_input;
            csreg_write_en_r    <= csreg_write_en_input;
          end
          else
            lsu_send_ready_r <= 0;
        end else if(next_state == MEM_WRITE_B) begin
          awvalid_r <= 0;
          wvalid_r  <= 0; 
        end else begin  // MEM_NULL 
          if(lsu_send_valid_r == 0) begin
            lsu_send_valid_r <= 1;
            if(rvalid) begin
              reg_read_data <= rdata;  // MEM_READ_B -> MEM_NULL
            end else if(!bvalid) begin  // IDLE -> MEM_NULL
              lsu_send_ready_r     <= 1;
              pc_r                 <= pc_input;
              pc_next_r            <= pc_next_input;
              instruction_r        <= instruction_input;
              ecall_r              <= ecall_input;
              ebreak_r             <= ebreak_input;
              reg_write_en_r       <= reg_write_en_input;
              csreg_write_en_r     <= csreg_write_en_input;
              src2                 <= src2_input;
              rsb                  <= rsb_input;
              wdOp                 <= wdOp_input;
              csrwdOp              <= csrwdOp_input;
              rd_r                 <= rd_input;
              csr_rd_r             <= csr_rd_input;
              exu_result           <= exu_result_input;
            end
          end
        end
      end
    end
  end

  assign lsu_send_valid = lsu_send_valid_r;
  assign lsu_send_ready = lsu_send_ready_r;
  assign rd             = rd_r;
  assign pc             = pc_r;
  assign instruction    = instruction_r;
  assign pc_next        = pc_next_r;
  assign csr_rd         = csr_rd_r;
  assign reg_write_en   = reg_write_en_r;
  assign csreg_write_en = csreg_write_en_r;
  assign ecall          = ecall_r;
  assign araddr         = araddr_r;
  assign arvalid        = arvalid_r;
  assign rready         = rready_r;
  assign awaddr         = awaddr_r;
  assign awvalid        = awvalid_r;
  assign wvalid         = wvalid_r;
  assign bready         = bready_r;
  assign wdata          = wdata_r;
  assign wstrb          = wstrb_r;
  assign ebreak         = ebreak_r;

  always @(posedge clk) begin
    if(rst) rready_r <= 0;
    else    rready_r <= 1;
  end

  always @(posedge clk) begin
    if(rst) bready_r <= 0;
    else    bready_r <= 1;
  end 
 
  MuxKeyWithDefault #(3, 32, 32) rwd(memory_read_wd, rmask, 32'h0, {
    32'h000000ff, memory_read_signed ? {{24{reg_read_data[7]}} , reg_read_data[7:0]}  : reg_read_data & rmask,
    32'h0000ffff, memory_read_signed ? {{16{reg_read_data[15]}}, reg_read_data[15:0]} : reg_read_data & rmask,
    32'hffffffff, reg_read_data
  });
  // wd choose
  MuxKeyWithDefault #(4, 2, 32) wdc (wd, wdOp, exu_result, {
    2'b00, exu_result,
    2'b01, memory_read_wd,
    2'b10, pc+4,
    2'b11, src2
  });

  MuxKeyWithDefault #(2, 1, 32) csrwdc (csr_wd, csrwdOp, exu_result, {
    1'b0, exu_result,
    1'b1, pc
  });

  assign  lsu_state = (next_state != IDLE);

endmodule