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
  input    wire  [31:0]  src2_input,
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
  output   wire          lsu_send_valid,
  output   reg           lsu_send_ready,
  output   wire  [31:0]  wd,
  output   wire  [31:0]  csr_wd,
  output   reg   [4 :0]  rd,
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
  output   reg   [7 :0]  wstrb
);
  reg         state;
  always @(posedge clk) begin
    if(rst) begin
      state <= 0;
      lsu_send_ready <= 1;
    end else begin
      if(state == 0) begin
        if(lsu_receive_valid && (ren_input || wen_input)) begin
          state <= 1;
          lsu_send_ready <= 0;
        end
      end else begin  // state = 1
        if(lsu_send_valid) begin
          assert(lsu_send_ready == 0);
          state <= 0;
          lsu_send_ready <= 1;
        end
      end
    end 
  end

  reg          ren;
  reg          wen;
  reg          memory_read_signed;
  reg  [7 :0]  wmask;
  reg  [31:0]  rmask;
  reg  [31:0]  exu_result;
  reg  [31:0]  src2;
  reg  [31:0]  pc;
  reg  [1 :0]  wdOp;
  reg          csrwdOp;
  wire [31:0]  memory_read_wd;

  always @(posedge clk) begin
    if(rst) begin
      ren                <= 0;
      wen                <= 0;
      memory_read_signed <= 0;
      wmask              <= 0;
      rmask              <= 0;
      exu_result         <= 0;
      pc                 <= 0;
      src2               <= 0;
      wdOp               <= 0;
      csrwdOp            <= 0;
      rd                 <= 0;
      csr_rd             <= 0;
      reg_write_en       <= 0;
      csreg_write_en     <= 0;
      ecall              <= 0;
      lsu_send_ready     <= 0;
    end
  end


  reg             wait_for_read_address;

  always @(posedge clk) begin
    if(rst) rready <= 0;
    else    rready <= 1;
  end 
  // arvalid
  always @(posedge clk) begin
    if(rst) begin
      arvalid <= 0;
      araddr <= 0;
      wait_for_read_address <= 0;
    end else begin
      if(wait_for_read_address) begin
        if(arready) begin
          assert(arvalid == 1);
          wait_for_read_address <= 0;
          arvalid <= 0;
        end 
      end else begin
        if(lsu_receive_valid && ren) begin
          assert(arvalid == 0);
          arvalid <= 1;
          araddr  <= exu_result;
          if(!arready) wait_for_read_address <= 1;
        end else begin
          if(arvalid && arready) arvalid <= 0;
        end
      end
    end
  end
  reg [31:0] reg_read_data;
  reg [1: 0] reg_rresp;
  always @(posedge clk) begin
    if(rst) begin
      reg_read_data <= 0;
      reg_rresp <= 2'b1;
    end else begin
      if(rvalid && rready) begin
        reg_read_data <= rdata;
        reg_rresp     <= rresp; 
      end else begin
        reg_rresp <= 2'b1;
      end
    end
  end
 
  MuxKeyWithDefault #(3, 32, 32) rwd(memory_read_wd, rmask, 32'h0, {
    32'h000000ff, memory_read_signed ? {{24{reg_read_data[7]}} , reg_read_data[7:0]}  : reg_read_data & rmask,
    32'h0000ffff, memory_read_signed ? {{16{reg_read_data[15]}}, reg_read_data[15:0]} : reg_read_data & rmask,
    32'hffffffff, reg_read_data
  });

  reg        wait_for_write_address;
  reg        wait_for_write_data;

  // 传输地址
  always @(posedge clk) begin
    if(rst) begin
      awaddr <= 0;;
      wait_for_write_address <= 0;
    end else begin
      if(wait_for_write_address) begin
        if(awready) begin
          assert(awvalid == 1);
          wait_for_write_address <= 0;
          awvalid <= 0;
        end
      end else begin
        if(lsu_receive_valid && wen) begin
          assert(awvalid == 0);
          awvalid <= 1;
          awaddr <= exu_result;
          if(!awready) wait_for_write_address <= 1;
        end else begin
          if(awvalid && awready) awvalid <= 0;
        end
      end
    end
  end
  // 传输数据
  always @(posedge clk) begin
    if(rst) begin
      wdata <= 0;
      wait_for_write_data <= 0;
      wstrb <= 0;
    end else begin
      if(wait_for_write_data) begin
        if(wready) begin
          assert(wvalid == 1);
          wait_for_write_data <= 0;
          wvalid <= 0;
        end 
      end else begin
        if(lsu_receive_valid && wen) begin
          assert(wvalid == 0);
          wvalid <= 1;
          wdata  <= src2;
          wstrb  <= wmask;
          if(!wready) wait_for_write_data <= 1;
        end else begin
          if(wvalid && wready) wvalid <= 0;
        end
      end
    end
  end

  // // bready
  // reg bready;
  always @(posedge clk) begin
    if(rst) bready <= 0;
    else    bready <= 1;
  end
  // bresp
  reg [1:0] reg_bresp;
  always @(posedge clk) begin
    if(rst) reg_bresp <= 1;
    else begin
      if(bready && bvalid) begin
        reg_bresp <= bresp;
      end else
        reg_bresp <= 1;
    end
  end

  assign lsu_send_valid = (lsu_receive_valid == 1) ? (((ren == 1)||(wen == 1)) ? ((reg_rresp == 0) || (reg_bresp == 0)) : 1) : ((reg_rresp == 0) || (reg_bresp == 0)); // 只有取值命令才需要等待sram返回值

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

endmodule