module ifu(
    input    wire          clk,
    input    wire          rst,
    input    wire  [31:0]  pc_next,
    input    wire          ifu_receive_valid,
    input    wire          arready,
    input    wire  [31:0]  rdata,
    input    wire          rvalid,
    input    wire  [1 :0]  rresp,
    output   wire          ifu_send_valid,
    output   wire  [31:0]  instruction,
    output   reg   [31:0]  araddr,
    output   reg           arvalid,
    output   reg           rready
);


  reg wait_for_read_address;
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