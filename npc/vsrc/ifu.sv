module ifu(
    input                 clk,
    input                 rst,
    input      [31:0]     pc_next,
    input                 ifu_receive_valid,
    output                ifu_send_valid,
    output     [31:0]     instruction
);

  wire awready, wready;
  wire bvalid;
  wire [1:0] bresp, rresp;
  axi_sram axi(
    .aclk(clk),
    .areset(rst),
    .araddr(araddr),
    .arvalid(arvalid),
    .rready(rready),
    .awaddr(0),
    .awvalid(0),
    .wdata(0),
    .wstrb(0),
    .wvalid(0),
    .rresp(rresp),
    .bready(0),
    .awready(awready),
    .wready(wready),
    .arready(arready),
    .rdata(rdata),
    .rvalid(rvalid),
    .bvalid(bvalid),
    .bresp(bresp)
  );

  reg arvalid, rready;
  reg wait_for_read_address;
  reg [31:0] araddr;
  wire arready;
  wire rvalid;
  wire [31:0] rdata;
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
          if(!arready) wait_for_read_address <= 1;
        end else begin
          if(arvalid && arready) arvalid <= 0;
        end
      end
    end
  end
  always@(posedge clk) begin
    if(rst) rready <= 0;
    else    rready <= 1;
  end
  reg [31:0] reg_data;
  reg [1:0] reg_rresp;
  always @(posedge clk) begin
    if(rst) begin
      reg_data <= 0;
      reg_rresp <= 1;
    end else begin
      if(rvalid && rready) begin
        reg_data <= rdata;
        reg_rresp <= rresp;
      end else begin
        reg_rresp <= 1;
      end
    end
  end

  assign instruction = reg_data;
  assign ifu_send_valid = (reg_rresp == 0);


endmodule