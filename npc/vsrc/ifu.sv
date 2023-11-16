module ifu(
    input                 clk,
    input                 rst,
    input      [31:0]     pc_next,
    input                 ifu_receive_valid,
    output                ifu_send_valid,
    output     [31:0]     instruction
);

  wire awready, wready;

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
    .awready(awready),
    .wready(wready),
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
  reg r_ifu_send_valid;
  always @(posedge clk) begin
    if(rst) begin
      reg_data <= 0;
      r_ifu_send_valid <= 0;
    end else begin
      if(rvalid && rready) begin
        reg_data <= data;
        r_ifu_send_valid <= 1;
      end else begin
        r_ifu_send_valid <= 0;
      end
    end
  end
  assign instruction = reg_data;
  assign ifu_send_valid = r_ifu_send_valid;


endmodule