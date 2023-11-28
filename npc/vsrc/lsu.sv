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
  input    wire          arready,
  input    wire  [31:0]  rdata,
  input    wire  [1 :0]  rresp,
  input    wire          rvalid,
  input    wire          awready,
  input    wire          wready,
  input    wire          bvalid,
  input    wire  [1 :0]  bresp,
  output   reg           lsu_send_valid,
  output   reg           lsu_send_ready,
  output   wire  [31:0]  wd,
  output   wire  [31:0]  csr_wd,
  output   reg   [4 :0]  rd,
  output   reg   [31:0]  pc,
  output   reg   [31:0]  instruction,
  output   reg   [31:0]  pc_next,
  output   reg   [1 :0]  csr_rd,
  output   reg           reg_write_en,
  output   reg           csreg_write_en,
  output   reg           ecall,
  output   reg   [31:0]  araddr,
  output   reg           arvalid,
  output   reg           rready,
  output   reg   [31:0]  awaddr,
  output   reg           awvalid,
  output   reg           wvalid,
  output   reg           bready,
  output   reg   [31:0]  wdata,
  output   reg   [7 :0]  wstrb,
  output   wire          lsu_state
);
  reg [2:0]  state, next_state;
  parameter  IDLE = 0, MEM_READ_A = 1, MEM_READ_B = 2, MEM_WRITE_A = 3, MEM_WRITE_B = 4, MEM_NULL = 5;

  always @(posedge clk) begin
    if(rst) state <= 0;
    else    state <= IDLE;
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

  always @(posedge clk) begin
    if(rst) begin
      state              <= 0;
      lsu_send_ready     <= 0;
      memory_read_signed <= 0;
      exu_result         <= 0;
      rmask              <= 0;
      pc                 <= 0;
      src2               <= 0;
      wdOp               <= 0;
      csrwdOp            <= 0;
      rd                 <= 0;
      csr_rd             <= 0;
      reg_write_en       <= 0;
      csreg_write_en     <= 0;
      ecall              <= 0;
      pc                 <= 0;
      instruction        <= 0;
      pc_next            <= 0;
      rsb                <= 0;
    end else begin
      if(next_state == IDLE) begin
        if(lsu_send_valid) lsu_send_valid <= 0;
      end else begin
        if(next_state == MEM_READ_A) begin
          if(arvalid == 0) begin
            arvalid            <= 1;
            araddr             <= exu_result_input;
            pc                 <= pc_input;
            pc_next            <= pc_next_input;
            instruction        <= instruction_input;
            memory_read_signed <= memory_read_signed_input;
            rmask              <= rmask_input;
            ecall              <= ecall_input;
            src2               <= src2_input;
            rsb                <= rsb_input;
            wdOp               <= wdOp_input;
            csrwdOp            <= csrwdOp_input;
            rd                 <= rd_input;
            csr_rd             <= csr_rd_input;
            reg_write_en       <= reg_write_en_input;
            csreg_write_en     <= csreg_write_en_input;
          end
        end else if(next_state == MEM_READ_B) begin
          arvalid <= 0;
        end else if(next_state == MEM_WRITE_A) begin
          if(awvalid == 0) begin
            awvalid         <= 1;
            awaddr          <= exu_result_input; 
            wvalid          <= 1;
            wstrb           <= wmask_input;
            pc              <= pc_input;
            pc_next         <= pc_next_input;
            instruction     <= instruction_input;
            ecall           <= ecall_input;
            reg_write_en    <= reg_write_en_input;
            csreg_write_en  <= csreg_write_en_input;
          end
        end else if(next_state == MEM_WRITE_B) begin
          awvalid <= 0;
          wvalid  <= 0; 
        end else begin  // MEM_NULL 
          if(lsu_send_valid == 0) begin
            lsu_send_valid <= 1;
            if(rvalid) begin
              reg_read_data <= rdata;
            end else if(!bvalid) begin
              pc                 <= pc_input;
              pc_next            <= pc_next_input;
              instruction        <= instruction_input;
              ecall           <= ecall_input;
              reg_write_en    <= reg_write_en_input;
              csreg_write_en  <= csreg_write_en_input;
            end
          end
        end
      end
    end
  end

  always @(posedge clk) begin
    if(rst) rready <= 0;
    else    rready <= 1;
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