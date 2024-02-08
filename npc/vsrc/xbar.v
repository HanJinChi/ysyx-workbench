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
          if(rvalid_o && rready)
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
        araddrA_r  = araddr;
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
  assign arburstA_o = arburstA_r; assign arburstA_o = arburstA_r;
  assign rreadyA_o  = rreadyA_r;  assign rreadyB_o  = rreadyB_r;

  parameter W_A = 1;
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
        if(bvalid_o)
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
      if(awvalid)
        if(awaddr == `YSYX_23060059_CLINT_L || awaddr == `YSYX_23060059_CLINT_H) 
          wMux = 2'b01;
        else 
          wMux = 2'b10;
      else
        wMux = wMux_r;  // waiting response
    end else 
      wMux    = wMux_r;
  end

  reg           awready_r;
  reg           wready_r;
  reg           bvalid_r;
  reg   [1 :0]  bresp_r;
  reg   [31:0]  awaddrA_r;  reg   [31:0]  awaddrB_r;
  reg           awvalidA_r; reg           awvalidB_r;
  reg   [3 :0]  awidA_r;    reg   [3 :0]  awidB_r;
  reg   [7 :0]  awlenA_r;   reg   [7 :0]  awlenB_r;
  reg   [2 :0]  awsizeA_r;  reg   [2 :0]  awsizeB_r;
  reg   [1 :0]  awburstA_r; reg   [1 :0]  awburstB_r;

  reg   [63:0]  wdataA_r;   reg   [63:0]  wdataB_r;
  reg   [7 :0]  wstrbA_r;   reg   [7 :0]  wstrbB_r;
  reg           wvalidA_r;  reg           wvalidB_r;
  reg           wlastA_r;   reg           wlastB_r;
  reg           breadyA_r;  reg           breadyB_r;
  always @(*) begin
    awready_r  = 0;
    wready_r   = 0;
    bvalid_r   = 0;
    bresp_r    = 0;
    awaddrA_r  = 0;  awaddrB_r  = 0;
    awvalidA_r = 0;  awvalidA_r = 0;
    awidA_r    = 0;  awidB_r    = 0;
    awlenA_r   = 0;  awlenB_r   = 0;
    awsizeA_r  = 0;  awsizeB_r  = 0;
    awburstA_r = 0;  awburstB_r = 0;
    wdataA_r   = 0;  wdataB_r   = 0;
    wstrbA_r   = 0;  wstrbB_r   = 0;
    wvalidA_r  = 0;  wvalidB_r  = 0;
    wlastA_r   = 0;  wlastB_r   = 0;
    breadyA_r  = 0;  breadyB_r  = 0;
    case(wMux)
      2'b01:begin
        awready_r  = awreadyA;
        wready_r   = wreadyA;
        bvalid_r   = bvalidA;
        bresp_r    = brespA;
        
        awaddrA_r  = awaddr;
        awvalidA_r = awvalid;
        awidA_r    = awid;
        awlenA_r   = awlen;
        awsizeA_r  = awsize;
        awburstA_r = awburst;
        wdataA_r   = wdata;
        wstrbA_r   = wstrb;
        wvalidA_r  = wvalid;
        wlastA_r   = wlast;
        breadyA_r  = bready;

        awaddrB_r  = 0;
        awvalidB_r = 0;
        awidB_r    = 0;
        awlenB_r   = 0;
        awsizeB_r  = 0;
        awburstB_r = 0;
        wdataB_r   = 0;
        wstrbB_r   = 0;
        wvalidB_r  = 0;
        wlastB_r   = 0;
        breadyB_r  = 0;
      end
      2'b10: begin
        awready_r  = awreadyB;
        wready_r   = wreadyB;
        bvalid_r   = bvalidB;
        bresp_r    = brespB;
        
        awaddrB_r  = awaddr;
        awvalidB_r = awvalid;
        awidB_r    = awid;
        awlenB_r   = awlen;
        awsizeB_r  = awsize;
        awburstB_r = awburst;
        wdataB_r   = wdata;
        wstrbB_r   = wstrb;
        wvalidB_r  = wvalid;
        wlastB_r   = wlast;
        breadyB_r  = bready;

        awaddrA_r  = 0;
        awvalidA_r = 0;
        awidA_r    = 0;
        awlenA_r   = 0;
        awsizeA_r  = 0;
        awburstA_r = 0;
        wdataA_r   = 0;
        wstrbA_r   = 0;
        wvalidA_r  = 0;
        wlastA_r   = 0;
        breadyA_r  = 0;
      end
      default: begin end 
    endcase
  end

  assign awready_o  = awready_r;
  assign wready_o   = wready_r;
  assign bvalid_o   = bvalid_r;
  assign bresp_o    = bresp_r;
  assign awaddrA_o  = awaddrA_r;  assign awaddrB_o  = awaddrB_r;
  assign awvalidA_o = awvalidA_r; assign awvalidB_o = awvalidB_r;
  assign awidA_o    = awidA_r;    assign awidA_o    = awidA_r;
  assign awlenA_o   = awlenA_r;   assign awlenB_o   = awlenB_r;
  assign awsizeA_o  = awsizeA_r;  assign awsizeB_o  = awsizeB_r;
  assign awburstA_o = awburstA_r; assign awburstB_o = awburstB_r;
  assign wdataA_o   = wdataA_r;   assign wdataB_o   = wdataB_r;
  assign wstrbA_o   = wstrbA_r;   assign wstrbB_o   = wstrbB_r;
  assign wvalidA_o  = wvalidA_r;  assign wvalidB_o  = wvalidB_r;
  assign wlastA_o   = wlastA_r;   assign wlastB_o   = wlastB_r;
  assign breadyA_o  = breadyA_r;  assign breadyB_o  = breadyB_r;  

endmodule