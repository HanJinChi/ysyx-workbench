module ysyx_23060059_xbar(
  input    wire          clock,
  input    wire          reset,
  // xbar <-> arbiter
  // ar channel
  input    wire  [31:0]  araddr,
  input    wire          arvalid,
  input    wire  [3 :0]  arid,
  input    wire  [7 :0]  arlen,
  input    wire  [2 :0]  arsize,
  input    wire  [1 :0]  arburst,
  output   wire          arready_o,
  // r channel
  input    wire          rready,
  output   wire  [63:0]  rdata_o,
  output   wire          rvalid_o,
  output   wire  [1 :0]  rresp_o,
  output   wire  [3 :0]  rid_o,
  output   wire          rlast_o,
  // aw channel 
  input    wire  [31:0]  awaddr,
  input    wire          awvalid,
  input    wire  [3 :0]  awid,
  input    wire  [7 :0]  awlen,
  input    wire  [2 :0]  awsize,
  input    wire  [1 :0]  awburst,
  output   wire          awready_o,
  // w channel
  input    wire  [63:0]  wdata,
  input    wire  [7 :0]  wstrb,
  input    wire          wvalid,
  input    wire          wlast,
  output   wire          wready_o,
  // b channel
  input    wire          bready,
  output   wire          bvalid_o,
  output   wire  [1 :0]  bresp_o
);



endmodule