module ysyx_23060059_clint(
    input   wire         clock,
    input   wire         reset,
    // xbar <-> clint
    // ar channel
    input    wire          arready,
    output   wire  [31:0]  araddr,
    output   wire          arvalid,
    output   wire  [3 :0]  arid,
    output   wire  [7 :0]  arlen,
    output   wire  [2 :0]  arsize,
    output   wire  [1 :0]  arburst,
    // r channel
    input    wire          rvalid,
    input    wire  [1 :0]  rresp,
    input    wire  [63:0]  rdata,
    input    wire          rlast,
    input    wire  [3 :0]  rid,
    output   wire          rready,
    // aw channel
    input    wire          awready,
    output   wire  [31:0]  awaddr,
    output   wire          awvalid,
    output   wire  [3 :0]  awid,
    output   wire  [7 :0]  awlen,
    output   wire  [2 :0]  awsize,
    output   wire  [1 :0]  awburst,
    // w channel
    input    wire          wready,
    output   wire          wvalid,
    output   wire  [63:0]  wdata,
    output   wire  [7 :0]  wstrb,
    output   wire          wlast,
    // b channel
    input    wire          bvalid,
    input    wire  [1 :0]  bresp,
    input    wire  [3 :0]  bid,
    output   wire          bready
);

  reg [63:0] time_r;
  always @(posedge clock) begin
    if(reset) begin
      time_r <= 0;    
    end else begin
      time_r <= time_r + 1;
    end
  end

    


endmodule