`include "defines.v"

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
  output   wire  [31:0]  araddrA_o,
  output   wire  [31:0]  araddrB_o,
  output   wire          arvalidA_o,
  output   wire          arvalidB_o,
  output   wire  [3 :0]  aridA_o,
  output   wire  [3 :0]  aridB_o,
  output   wire  [7 :0]  arlenA_o,
  output   wire  [7 :0]  arlenB_o,
  output   wire  [2 :0]  arsizeA_o,
  output   wire  [2 :0]  arsizeB_o,
  output   wire  [1 :0]  arburstA_o,
  output   wire  [1 :0]  arburstB_o,
  input    wire          arreadyA,
  input    wire          arreadyB,
  // r channel
  output   wire          rreadyA_o,
  output   wire          rreadyB_o,
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
  output   wire  [31:0]  awaddrA_o,
  output   wire  [31:0]  awaddrB_o,
  output   wire          awvalidA_o,
  output   wire          awvalidB_o,
  output   wire  [3 :0]  awidA_o,
  output   wire  [3 :0]  awidB_o,
  output   wire  [7 :0]  awlenA_o,
  output   wire  [7 :0]  awlenB_o,
  output   wire  [2 :0]  awsizeA_o,
  output   wire  [2 :0]  awsizeB_o,
  output   wire  [1 :0]  awburstA_o,
  output   wire  [1 :0]  awburstB_o,
  input    wire          awreadyA,
  input    wire          awreadyB,
  // w channel
  output   wire  [63:0]  wdataA_o,
  output   wire  [63:0]  wdataB_o,
  output   wire  [7 :0]  wstrbA_o,
  output   wire  [7 :0]  wstrbB_o,
  output   wire          wvalidA_o,
  output   wire          wvalidB_o,
  output   wire          wlastA_o,
  output   wire          wlastB_o,
  input    wire          wreadyA,
  input    wire          wreadyB,
  // b channel
  output   wire          breadyA_o,
  output   wire          breadyB_o,
  input    wire          bvalidA,
  input    wire          bvalidB,
  input    wire  [1 :0]  brespA,
  input    wire  [1 :0]  brespB
);

  parameter IDLE = 0, R_A = 1, R_B = 2;
  reg   [1 :0]  ar_state;
  reg   [1 :0]  ar_next_state;

  always @(posedge clock) begin
    if(reset) ar_state <= IDLE;
    else      ar_state <= ar_next_state;
  end

  always @(*) begin
    case(ar_state)
        IDLE:
          if(arvalid)
            ar_next_state = R_A;
          else
            ar_next_state = IDLE;
        R_A:
          if(rvalid && rready)
            ar_next_state = IDLE;
          else
            ar_next_state = R_A;
        default: begin end
    endcase
  end

  reg   [1 :0]  araddrMux_r;  
  reg   [1 :0]  araddrMux;
  // araddr
  always @(*) begin
    if(ar_state == IDLE) begin
      if(arvalid)
        if(araddr == `YSYX_23060059_CLINT_L || araddr == `YSYX_23060059_CLINT_H) 
          araddrMux = 2'b01;
        else 
          araddrMux = 2'b10;
      else begin
        araddrMux = araddrMux_r;  // waiting response
      end
    end else begin
      araddrMux = araddrMux_r;
    end
  end

  always @(posedge clock) begin
    if(reset) begin
      araddrMux_r  <= 0;
    end else begin
      if(ar_next_state == IDLE)
        araddrMux_r <= 0;
      else
        araddrMux_r <= araddrMux;
    end
  end

  reg           arready_r;
  reg   [63:0]  rdata_r;
  reg           rvalid_r;
  reg   [1 :0]  rresp_r;
  reg   [3 :0]  rid_r;
  reg           rlast_r;
  reg   [31:0]  araddrA_r;  reg   [31:0]  araddrB_r;
  reg           arvalidA_r; reg           arvalidB_r;
  reg   [3 :0]  aridA_r;    reg   [3 :0]  aridB_r;
  reg   [7 :0]  arlenA_r;   reg   [7 :0]  arlenB_r;
  reg   [2 :0]  arsizeA_r;  reg   [2 :0]  arsizeB_r;
  reg   [1 :0]  arburstA_r; reg   [1 :0]  arburstB_r;
  reg           rreadyA_r;  reg           rreadyB_r;
  
  always @(*) begin
    arready_r  = 0;
    rdata_r    = 0;
    rvalid_r   = 0;
    rresp_r    = 0;
    rid_r      = 0;
    rlast_r    = 0;
    araddrA_r  = 0; araddrB_r  = 0;
    arvalidA_r = 0; arvalidB_r = 0;
    aridA_r    = 0; aridB_r    = 0;
    arlenA_r   = 0; arlenB_r   = 0;
    arsizeA_r  = 0; arsizeB_r  = 0;
    arburstA_r = 0; arburstB_r = 0; 
    rreadyA_r  = 0; rreadyB_r  = 0;
    case(araddrMux)
      2'b01: begin
        araddrA_r  = araddrA;
        arvalidA_r = arvalid;
        aridA_r    = arid;
        arlenA_r   = arlen;
        arsizeA_r  = arsize;
        arburstA_r = arburst;
        rreadyA_r  = rready;

        araddrB_r  = 0;
        arvalidB_r = 0;
        aridB_r    = 0;
        arlenB_r   = 0;
        arsizeB_r  = 0;
        arburstB_r = 0;
        rreadyB_r  = 0;

        arready_r  = arreadyA;
        rdata_r    = rdataA;
        rvalid_r   = rvalidA;
        rresp_r    = rrespA;
        rid_r      = ridA;
        rlast_r    = rlastA;
      end
      2'b10: begin
        araddrB_r  = araddr;
        arvalidB_r = arvalid;
        aridB_r    = arid;
        arlenB_r   = arlen;
        arsizeB_r  = arsize;
        arburstB_r = arburst;
        rreadyB_r  = rready;

        araddrA_r  = 0;
        arvalidA_r = 0;
        aridA_r    = 0;
        arlenA_r   = 0;
        arsizeA_r  = 0;
        arburstA_r = 0;
        rreadyA_r  = 0;

        arready_r  = arreadyB;
        rdata_r    = rdataB;
        rvalid_r   = rvalidB;
        rresp_r    = rrespB;
        rid_r      = ridB;
        rlast_r    = rlastB;      
      end
    default: begin end
    endcase
  end

  assign arready_o  = arready_r;
  assign rdata_o    = rdata_r;
  assign rvalid_o   = rvalid_r;
  assign rresp_o    = rresp_r;
  assign rid_o      = rid_r;
  assign rlast_o    = rlast_r;
  assign araddrA_o  = araddrA_r;  assign araddrB_o  = araddrB_r; 
  assign arvalidA_o = arvalidA_r; assign arvalidB_o = arvalidB_r;
  assign aridA_o    = aridA_r;    assign aridB_o    = aridB_r;
  assign arlenA_o   = arlenA_r;   assign arlenB_o   = arlenB_r;
  assign arsizeA_o  = arsizeA_r;  assign arsizeB_o  = arsizeB_r;
  assign arburstA_o = arburstA_r; assign arburstA_o = arbursta_r;
  assign rreadyA_o  = rreadyA_r;  assign rreadyB_o  = rreadyB_r;

  parameter W_A = 1;
  reg   [1 :0]  wMux;
  reg   [1 :0]  aw_state;
  reg   [1 :0]  aw_next_state;

  always @(posedge clock) begin
    if(reset) aw_state <= 0;
    else      aw_state <= aw_next_state; 
  end

  always @(*) begin
    case(aw_state)
      IDLE:
        if(awvalid)
          aw_next_state = W_A;
        else 
          aw_next_state = IDLE;
      W_A:
        if(bvalid)
          aw_next_state = IDLE;
        else
          aw_next_state = W_A;
      default: begin end
    endcase
  end

  reg   [1 :0]  wMux_r;  // for save
  reg   [1 :0]  wMux;
  always @(posedge clock) begin
    if(reset) begin
      wMux_r  <= 0;
    end else begin
      if(aw_next_state == IDLE) begin
        wMux_r <= 0; 
      end else begin
        wMux_r <= wMux;
      end
    end
  end

  // awaddr
  always @(*) begin
    if(aw_state == IDLE) begin
      if(awvalidA) 
        wMux      = 2'b01;
      else if(awvalidB) 
        wMux      = 2'b10;
      else begin
        wMux      = wMux_r;
      end
    end else 
      wMux    = wMux_r;
  end

  reg   awready_r;
  reg   wready_r;
  reg   

endmodule