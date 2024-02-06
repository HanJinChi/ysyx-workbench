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
  output   wire  [1 :0]  bresp_o,
  // xbar <-> soc
  // xbar <-> clint
  // ar channel
  output   wire  [31:0]  araddrA,
  output   wire  [31:0]  araddrB,
  output   wire          arvalidA,
  output   wire          arvalidB,
  output   wire  [3 :0]  aridA,
  output   wire  [3 :0]  aridB,
  output   wire  [7 :0]  arlenA,
  output   wire  [7 :0]  arlenB,
  output   wire  [2 :0]  arsizeA,
  output   wire  [2 :0]  arsizeB,
  output   wire  [1 :0]  arburstA,
  output   wire  [1 :0]  arburstB,
  input    wire          arready_A,
  input    wire          arready_B,
  // r channel
  output   wire          rreadyA,
  output   wire          rreadyB,
  input    wire  [63:0]  rdataA,
  input    wire  [63:0]  rdataB,
  input    wire          rvalidA,
  input    wire          rvalidB,
  input    wire  [1 :0]  rrespA,
  input    wire  [1 :0]  rrespB,
  input    wire  [3 :0]  ridA,
  input    wire  [3 :0]  ridB,
  input    wire          rlastA,
  input    wire          rlastB,
  // aw channel 
  output   wire  [31:0]  awaddrA,
  output   wire  [31:0]  awaddrB,
  output   wire          awvalidA,
  output   wire          awvalidB,
  output   wire  [3 :0]  awidA,
  output   wire  [3 :0]  awidB,
  output   wire  [7 :0]  awlenA,
  output   wire  [7 :0]  awlenB,
  output   wire  [2 :0]  awsizeA,
  output   wire  [2 :0]  awsizeB,
  output   wire  [1 :0]  awburstA,
  output   wire  [1 :0]  awburstB,
  input    wire          awreadyA,
  input    wire          awreadyB,
  // w channel
  output   wire  [63:0]  wdataA,
  output   wire  [63:0]  wdataB,
  output   wire  [7 :0]  wstrbA,
  output   wire  [7 :0]  wstrbB,
  output   wire          wvalidA,
  output   wire          wvalidB,
  output   wire          wlastA,
  output   wire          wlastB,
  input    wire          wreadyA,
  input    wire          wreadyB,
  // b channel
  output   wire          breadyA,
  output   wire          breadyB,
  input    wire          bvalidA,
  input    wire          bvalidB,
  input    wire  [1 :0]  brespA,
  input    wire  [1 :0]  brespB
);

  



endmodule