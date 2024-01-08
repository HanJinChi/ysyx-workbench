
module ysyx_23060059_arbiter(
  input    wire          clock,
  input    wire          reset,
  // ifu and lsu <-> arbiter
  // ar channel
  input    wire  [31:0]  araddrA,
  input    wire  [31:0]  araddrB,
  input    wire          arvalidA,
  input    wire          arvalidB,
  input    wire  [3 :0]  aridA,
  input    wire  [3 :0]  aridB,
  input    wire  [7 :0]  arlenA,
  input    wire  [7 :0]  arlenB,
  input    wire  [2 :0]  arsizeA,
  input    wire  [2 :0]  arsizeB,
  input    wire  [1 :0]  arburstA,
  input    wire  [1 :0]  arburstB,
  output   wire          arreadyA_o,
  output   wire          arreadyB_o,
  // r channel
  input    wire          rreadyA,
  input    wire          rreadyB,
  output   wire  [63:0]  rdataA_o,
  output   wire  [63:0]  rdataB_o,
  output   wire          rvalidA_o,
  output   wire          rvalidB_o,
  output   wire  [1 :0]  rrespA_o,
  output   wire  [1 :0]  rrespB_o,
  output   wire  [3 :0]  ridA_o,
  output   wire  [3 :0]  ridB_o,
  output   wire          rlastA_o,
  output   wire          rlastB_o,
  // aw channel 
  input    wire  [31:0]  awaddrA,
  input    wire  [31:0]  awaddrB,
  input    wire          awvalidA,
  input    wire          awvalidB,
  input    wire  [3 :0]  awidA,
  input    wire  [3 :0]  awidB,
  input    wire  [7 :0]  awlenA,
  input    wire  [7 :0]  awlenB,
  input    wire  [2 :0]  awsizeA,
  input    wire  [2 :0]  awsizeB,
  input    wire  [1 :0]  awburstA,
  input    wire  [1 :0]  awburstB,
  output   wire          awreadyA_o,
  output   wire          awreadyB_o,
  // w channel
  input    wire  [63:0]  wdataA,
  input    wire  [63:0]  wdataB,
  input    wire  [7 :0]  wstrbA,
  input    wire  [7 :0]  wstrbB,
  input    wire          wvalidA,
  input    wire          wvalidB,
  input    wire          wlastA,
  input    wire          wlastB,
  output   wire          wreadyA_o,
  output   wire          wreadyB_o,
  // b channel
  input    wire          breadyA,
  input    wire          breadyB,
  output   wire          bvalidA_o,
  output   wire          bvalidB_o,
  output   wire  [1 :0]  brespA_o, 
  output   wire  [1 :0]  brespB_o,
  // arbiter <-> xbar(axi)
  // ar
  input    wire          arready,
  output   wire  [31:0]  araddr,
  output   wire          arvalid,
  output   wire  [3 :0]  arid,
  output   wire  [7 :0]  arlen,
  output   wire  [2 :0]  arsize,
  output   wire  [1 :0]  arburst,
  // r
  input    wire  [63:0]  rdata,
  input    wire          rvalid,
  input    wire  [1 :0]  rresp,
  input    wire  [3 :0]  rid,
  input    wire          rlast,
  output   wire          rready,
  // aw
  input    wire          awready,
  output   wire          awvalid,
  output   wire  [3 :0]  awid,
  output   wire  [7 :0]  awlen,
  output   wire  [2 :0]  awsize,
  output   wire  [1 :0]  awburst,
  output   wire  [31:0]  awaddr,
  // w
  output   wire  [63:0]  wdata,
  output   wire  [7 :0]  wstrb,
  output   wire          wvalid,
  output   wire          wlast,
  input    wire          wready,
  // b 
  input    wire          bvalid,
  input    wire  [1 :0]  bresp,
  output   wire          bready
);
  parameter IDLE = 0, MEM_R_A = 1, MEM_R_B = 2;
  reg   [1 :0]  ar_state;
  reg   [1 :0]  ar_next_state;
  reg   [1 :0]  araddrMux;

  always @(posedge clock) begin
    if(reset) ar_state <= 0;
    else      ar_state <= ar_next_state; 
  end

  always@(*) begin
    case(ar_state)
      IDLE:
        if((arvalidA || arvalidB ) && arready)
          ar_next_state = MEM_R_A;
        else
          ar_next_state = IDLE;
      MEM_R_A:
        if(rvalid && rready)
          ar_next_state = IDLE;
        else
          ar_next_state = MEM_R_A;
    endcase
  end

  reg   [1 :0]  araddrMux_r;  
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

  // araddr
  always @(*) begin
    if(ar_state == IDLE) begin
      if(arvalidA) 
        araddrMux = 2'b01;
      else if(arvalidB) 
        araddrMux = 2'b10;
      else begin
        araddrMux = araddrMux_r;  // waiting response
      end
    end else begin
      araddrMux = araddrMux_r;
    end
  end
 

  // slave
  reg           arvalid_r;
  reg   [31:0]  araddr_r;
  reg           rready_r;

  reg           arreadyA_r, arreadyB_r;
  reg   [63:0]  rdataA_r, rdataB_r;
  reg   [1 :0]  rrespA_r, rrespB_r;
  reg           rvalidA_r, rvalidB_r;

  always @(*) begin
    arvalid_r    = 0;
    araddr_r     = 0;
    rready_r     = 0; 
    arreadyA_r   = 0; arreadyB_r = 0;
    rdataA_r     = 0; rdataB_r   = 0;
    rrespA_r     = 0; rrespB_r   = 0;
    rvalidA_r    = 0; rvalidB_r  = 0;
    case (araddrMux)
      2'b01: begin
        arvalid_r    = arvalidA;
        araddr_r     = araddrA;
        rready_r     = rreadyA;
        arreadyA_r   = arready;
        rdataA_r     = rdata;
        rrespA_r     = rresp;

        arreadyB_r   = 0;
        rdataB_r     = 0;
        rrespB_r     = 0;

        rvalidA_r    = rvalid;
        rvalidB_r    = 0;
      end
      2'b10: begin
        arvalid_r    = arvalidB;
        araddr_r     = araddrB;
        rready_r     = rreadyB;
        arreadyB_r   = arready;
        rdataB_r     = rdata;
        rrespB_r     = rresp;

        arreadyA_r   = 0;
        rdataA_r     = 0;
        rrespA_r     = 0;

        rvalidB_r    = rvalid;
        rvalidA_r    = 0;
      end
      default: begin end
    endcase
  end


  
  assign arreadyA_o = arreadyA_r; 
  assign rdataA_o   = rdataA_r;
  assign rvalidA_o  = rvalidA_r;
  assign rrespA_o   = rrespA_r;

  assign arreadyB_o = arreadyB_r; 
  assign rdataB_o   = rdataB_r;
  assign rvalidB_o  = rvalidB_r;
  assign rrespB_o   = rrespB_r;

  assign rready     = rready_r;
  assign araddr     = araddr_r;
  assign arvalid    = arvalid_r;

  assign rvalidA_o  = rvalidA_r;
  assign rvalidB_o  = rvalidB_r;

  parameter MEM_W_A = 1;
  reg   [1 :0]  wMux;
  reg   [1 :0]  aw_state;
  reg   [1 :0]  aw_next_state;

  always @(posedge clock) begin
    if(reset) aw_state <= 0;
    else      aw_state <= aw_next_state; 
  end

  always@(*) begin
    case(aw_state)
      IDLE:
        if((awvalidA || awvalidB) && awready)
          aw_next_state = MEM_W_A;
        else
          aw_next_state = IDLE;
      MEM_W_A:
        if(bvalid && bready)
          aw_next_state = IDLE;
        else
          aw_next_state = MEM_W_A;
    endcase
  end


  reg   [1 :0]  wMux_r;  // for save
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


  reg          awvalid_r;
  reg  [31:0]  awaddr_r;
  reg  [63:0]  wdata_r;
  reg  [7 :0]  wstrb_r;
  reg          wvalid_r;
  reg          bready_r;
  reg  [3 :0]  awid_r;
  reg  [7 :0]  awlen_r;
  reg  [2 :0]  awsize_r;
  reg  [1 :0]  awburst_r;
  reg          wlast_r;

  reg          awreadyA_r, awreadyB_r;
  reg          wreadyA_r,  wreadyB_r;
  reg          bvalidA_r,  bvalidB_r;
  reg  [1 :0]  brespA_r,   brespB_r;


  always @(*) begin
    awvalid_r = 0;    
    awaddr_r  = 0;   
    wdata_r   = 0;    
    wstrb_r   = 0;    
    wvalid_r  = 0;    
    bready_r  = 0;
    awid_r    = 0;
    awlen_r   = 0;
    awsize_r  = 0;
    awburst_r = 0;
    wlast_r   = 0;  

    awreadyA_r = 0; awreadyB_r = 0;
    wreadyA_r  = 0; wreadyB_r  = 0;
    brespA_r   = 0; brespB_r   = 0;
    bvalidA_r  = 0; bvalidB_r  = 0;
    case(wMux)
      2'b01: begin
        awvalid_r  = awvalidA;
        awaddr_r   = awaddrA;
        wdata_r    = wdataA;
        wstrb_r    = wstrbA;
        wvalid_r   = wvalidA;
        bready_r   = breadyA;
        awid_r     = awidA;
        awlen_r    = awlenA;
        awsize_r   = awsizeA;
        awburst_r  = awburstA;
        wlast_r    = wlastA;

        awreadyA_r = awready;
        wreadyA_r  = wready;
        brespA_r   = bresp;

        awreadyB_r = 0;
        wreadyB_r  = 0;
        brespB_r    = 0; 

        bvalidA_r  = bvalid;
        bvalidB_r  = 0;
      end
      2'b10: begin
        awvalid_r  = awvalidB;
        awaddr_r   = awaddrB;
        wdata_r    = wdataB;
        wstrb_r    = wstrbB;
        wvalid_r   = wvalidB;
        bready_r   = breadyB;
        awid_r     = awidB;
        awlen_r    = awlenB;
        awsize_r   = awsizeB;
        awburst_r  = awburstB;
        wlast_r    = wlastB;

        awreadyB_r = awready;
        wreadyB_r  = wready;
        brespB_r   = bresp;

        awreadyA_r = 0;
        wreadyA_r  = 0;
        brespA_r   = 0;

        bvalidB_r  = bvalid;
        bvalidA_r  = 0; 
      end
    default: begin end
    endcase
  end

  assign awreadyA_o  = awreadyA_r;
  assign wreadyA_o   = wreadyA_r;
  assign bvalidA_o   = bvalidA_r;
  assign brespA_o    = brespA_r;

  assign awreadyB_o  = awreadyB_r;
  assign wreadyB_o   = wreadyB_r;
  assign bvalidB_o   = bvalidB_r;
  assign brespB_o    = brespB_r;

  assign awvalid     = awvalid_r;    
  assign awaddr      = awaddr_r;   
  assign wdata       = wdata_r;    
  assign wstrb       = wstrb_r;    
  assign wvalid      = wvalid_r;
  assign bready      = bready_r;

  assign awid        = awid_r;
  assign awlen       = awlen_r;
  assign awsize      = awsize_r;
  assign awburst     = awburst_r;
  assign wlast       = wlast_r;  

  assign bvalidA_o   = bvalidA_r;
  assign bvalidB_o   = bvalidB_r;  

endmodule