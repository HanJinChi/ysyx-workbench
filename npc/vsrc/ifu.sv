module ifu(
    input                 clk,
    input                 rst,
    input      [31:0]     pc_next,
    input                 ifu_receive_valid,
    output                ifu_send_valid,
    output     [31:0]     instruction
);

  // wire   [31:0]      data;
  // wire               ren;
  // wire               wen;
  // wire   [7: 0]      wmask;
  // wire   [31:0]      wdata;
  // wire               sram_valid;
  // wire   [31:0]      sram_addr;   
  // reg    [31:0]      reg_pc_next;
  // reg                reg_ren;

 
  // sram sr(
  //   .clk(clk),
  //   .rst(rst),
  //   .ren(ren),
  //   .wen(wen),
  //   .wmask(wmask),
  //   .sram_receive_valid(ifu_receive_valid),
  //   .addr(sram_addr),
  //   .wdata(wdata),
  //   .data(instruction),
  //   .sram_valid(sram_valid)
  // );

  // assign wen = 1'b0; // 写不使能
  // assign wmask = 8'b0;
  // assign wdata = 32'h0;
  // assign ren = reg_ren;
  // assign ifu_send_valid = sram_valid;
  // assign sram_addr = (reg_pc_next == 32'h0) ? 32'h80000000 : reg_pc_next;

  // always@(posedge clk) begin
  //   if(rst) begin
  //     reg_pc_next <= 32'h80000000;
  //     reg_ren <= 0;
  //   end else begin
  //     if(ifu_receive_valid) begin
  //       reg_pc_next <= pc_next;
  //       reg_ren <= 1;
  //     end else begin
  //       reg_ren <= 0;
  //     end
  //   end
  // end

  axi_sram axi(
    .aclk(clk),
    .areset(rst),
    .araddr(araddr),
    .arvalid(arvalid),
    .rready(rready),
    .arready(arready),
    .data(data),
    .rvalid(rvalid)
  );

  reg arvalid, rready;
  reg wait_for_read_address;
  reg [31:0] araddr;
  wire arready;
  wire rvalid;
  wire [31:0] data;
  always@(posedge clk) begin
    if(rst) begin
      arvalid <= 0;
      araddr <= 0;
      wait_for_read_address <=0 ;
    end else begin
      if(wait_for_read_address) begin
        if(arready) begin
          assert(arvalid == 1);
          wait_for_read_address <= 0;
          arvalid <= 0;
        end
      end else begin
        if(ifu_receive_valid) begin
          assert(arvalid == 0);
          arvalid <= 1;
          araddr <= pc_next;
          if(!arready) begin
            wait_for_read_address <= 1;
          end
        end else begin
          if(arvalid && arready) begin
            arvalid <= 0;
          end
        end
      end
    end
  end
  always@(posedge clk) begin
    if(rst) begin 
      rready <= 0;
    end else begin
      rready <= 1;
    end
  end
  reg [31:0] reg_data;
  always @(posedge clk) begin
    if(rst) begin
      reg_data <= 0;
    end else begin
      if(rvalid && rready) begin
        reg_data <= data;
      end
    end
  end
  assign instruction = reg_data;
  assign ifu_send_valid = rvalid;


endmodule