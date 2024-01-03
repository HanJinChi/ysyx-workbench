
module ysyx_23060059_arbiter(
  input    wire          clock,
  input    wire          reset,
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
  input    wire  [1 :0]  awburstB
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
  output   wire  [1 :0]  brespB_o
);
  parameter IDLE = 0, MEM_R_A = 1, MEM_R_B = 2;
  reg   [1 :0]  ar_state;
  reg   [1 :0]  ar_next_state;
  reg   [1 :0]  araddrMux;

  always @(posedge clock) begin
    if(reset) ar_state <= 0;
    else    ar_state <= ar_next_state; 
  end

  always@(*) begin
    case(ar_state)
      IDLE:
        if(arvalidA)
          if(araddrA == `YSYX_23060059_UART && arreadySA)
            ar_next_state = MEM_R_A;
          else if(arreadySB)
            ar_next_state = MEM_R_A;
          else
            ar_next_state = IDLE;
        else if(arvalidB)
          if(araddrB == `YSYX_23060059_UART && arreadySA)
            ar_next_state = MEM_R_A;
          else if(arreadySB)
            ar_next_state = MEM_R_A;
          else
            ar_next_state = IDLE;
        else
          ar_next_state = IDLE;
      MEM_R_A:
        if((rvalidA_o && rreadyA) || (rvalidB_o && rreadyB))
          ar_next_state = IDLE;
        else
          ar_next_state = MEM_R_A;
    endcase
  end

  reg   [1 :0]  araddrMux_s;  // for save
  always @(posedge clock) begin
    if(reset) begin
      araddrMux_s  <= 0;
    end else begin
      if(ar_next_state == MEM_R_A) begin
        araddrMux_s  <= araddrMux; 
      end else begin
        araddrMux_s  <= 0;
      end
    end
  end

  // araddr
  always @(*) begin
    if(ar_next_state == MEM_R_A) begin
      if(arvalidA) begin
        araddrMux = 2'b01;
      end else if(arvalidB) begin
        araddrMux = 2'b10;
      end else begin
        araddrMux = araddrMux_s;  // waiting response
      end
    end else begin
      araddrMux = araddrMux_s;
    end
  end

  // slave
  reg           arvalidSA, arvalidSB;
  reg   [31:0]  araddrSA,  araddrSB;
  reg           rreadySA,  rreadySB;

  reg           arreadyA_o_r, arreadyB_o_r;
  reg   [63:0]  rdataA_o_r, rdataB_o_r;
  reg   [1 :0]  rrespA_o_r, rrespB_o_r;
  reg           rvalidA_o_r, rvalidB_o_r;

  wire          arreadySA, arreadySB;
  wire  [63:0]  rdataSA,   rdataSB;
  wire  [1 :0]  rrespSA,   rrespSB;
  wire          rvalidSA,  rvalidSB;

  always @(*) begin
    arvalidSA    = 0; arvalidSB    = 0;
    araddrSA     = 0; araddrSB     = 0;
    rreadySA     = 0; rreadySB     = 0;
    arreadyA_o_r = 0; arreadyB_o_r = 0;
    rdataA_o_r   = 0; rdataB_o_r   = 0;
    rrespA_o_r   = 0; rrespB_o_r   = 0;
    // rvalidA_o_r  = 0; rvalidB_o_r  = 0;
    case (araddrMux)
      2'b01: begin
        if(araddrA == `YSYX_23060059_UART) begin
          // input 
          arvalidSA    = arvalidA;
          araddrSA     = araddrA;
          rreadySA     = rreadyA;
          // output
          arreadyA_o_r = arreadySA;
          rdataA_o_r   = rdataSA;
          rrespA_o_r   = rrespSA;
          // rvalidA_o_r = rvalidSA;     
        end else begin  // MEMORY READ
          // input 
          arvalidSB    = arvalidA;
          araddrSB     = araddrA;
          rreadySB     = rreadyA;
          // output
          arreadyA_o_r = arreadySB;
          rdataA_o_r   = rdataSB;
          rrespA_o_r   = rrespSB;
          // rvalidA_o_r = rvalidSB; 
        end
      end
      2'b10: begin
        if(araddrB == `YSYX_23060059_UART) begin
          arvalidSA    = arvalidB;
          araddrSA     = araddrB;
          rreadySA     = rreadyB;

          arreadyB_o_r = arreadySA;
          rdataB_o_r   = rdataSA;
          rrespB_o_r   = rrespSA;
          // rvalidB_o_r = rvalidSA;
        end else begin
          arvalidSB   = arvalidB;
          araddrSB    = araddrB;
          rreadySB    = rreadyB;
          // output
          arreadyB_o_r = arreadySB;
          rdataB_o_r  = rdataSB;
          rrespB_o_r  = rrespSB;
          // rvalidB_o_r = rvalidSB; 
        end
      end
      default: begin end
    endcase
  end


  always @(*) begin
    case(araddrMux_s) 
      2'b01: begin
        if(araddrA == `YSYX_23060059_UART) begin
          rvalidA_o_r = rvalidSA;
        end else 
          rvalidA_o_r = rvalidSB;
        rvalidB_o_r = 0;
      end
      2'b10: begin
        if(araddrB == `YSYX_23060059_UART) 
          rvalidB_o_r = rvalidSA;
        else 
          rvalidB_o_r = rvalidSB;
        rvalidA_o_r = 0;
      end
      default: begin
        rvalidA_o_r = 0;
        rvalidB_o_r = 0;
      end
    endcase
  end
  
  assign arreadyA_o = arreadyA_o_r; 
  assign rdataA_o   = rdataA_o_r;
  assign rvalidA_o  = rvalidA_o_r;
  assign rrespA_o   = rrespA_o_r;

  assign arreadyB_o = arreadyB_o_r; 
  assign rdataB_o   = rdataB_o_r;
  assign rvalidB_o  = rvalidB_o_r;
  assign rrespB_o   = rrespB_o_r;



  parameter MEM_W_A = 1;
  reg   [1 :0]  wMux;
  reg   [1 :0]  aw_state;
  reg   [1 :0]  aw_next_state;

  always @(posedge clock) begin
    if(reset) aw_state <= 0;
    else    aw_state <= aw_next_state; 
  end

  always@(*) begin
    case(aw_state)
      IDLE:
        if(awvalidA)
          if(awaddrA == `YSYX_23060059_UART && awreadySA)
            aw_next_state = MEM_W_A;
          else if(awreadySB)
            aw_next_state = MEM_W_A;
          else
            aw_next_state = IDLE;
        else if(awvalidB)
          if(awaddrB == `YSYX_23060059_UART && awreadySA)
            aw_next_state = MEM_W_A;
          else if(arreadySB)
            aw_next_state = MEM_W_A;
          else
            aw_next_state = IDLE;
        else
          aw_next_state = IDLE;
      MEM_W_A:
        if((bvalidA_o && breadyA) || (bvalidB_o && breadyA))
          aw_next_state = IDLE;
        else
          aw_next_state = MEM_W_A;
    endcase
  end


  reg   [1 :0]  wMux_s;  // for save
  always @(posedge clock) begin
    if(reset) begin
      wMux_s  <= 0;
    end else begin
      if(aw_next_state == MEM_W_A) begin
        wMux_s <= wMux; 
      end else begin
        wMux_s <= 0;
      end
    end
  end

  // awaddr
  always @(*) begin
    if(aw_next_state == MEM_W_A) begin
      if(awvalidA) begin
        wMux      = 2'b01;
      end else if(awvalidB) begin
        wMux      = 2'b10;
      end else begin
        wMux      = wMux_s;
      end
    end else begin
      wMux    = wMux_s;
    end
  end


  reg          awvalidSA,    awvalidSB;
  reg  [31:0]  awaddrSA,     awaddrSB;
  reg  [63:0]  wdataSA,      wdataSB;
  reg  [7 :0]  wstrbSA,      wstrbSB;
  reg          wvalidSA,     wvalidSB;
  reg          breadySA,     breadySB;

  reg          awreadyA_o_r, awreadyB_o_r;
  reg          wreadyA_o_r,  wreadyB_o_r;
  reg          bvalidA_o_r,  bvalidB_o_r;
  reg  [1 :0]  brespA_o_r,   brespB_o_r;

  wire         awreadySA,    awreadySB;
  wire         wreadySA,     wreadySB;
  wire         bvalidSA,     bvalidSB;
  wire [1 :0]  brespSA,      brespSB;

  always @(*) begin
    awvalidSA = 0;    awvalidSB = 0;
    awaddrSA  = 0;    awaddrSB  = 0;
    wdataSA   = 0;    wdataSB   = 0;
    wstrbSA   = 0;    wstrbSB   = 0;
    wvalidSA  = 0;    wvalidSB  = 0;
    breadySA  = 0;    breadySB  = 0;

    awreadyA_o_r = 0; awreadyB_o_r = 0;
    wreadyA_o_r  = 0; wreadyB_o_r  = 0;
    brespA_o_r   = 0; brespB_o_r   = 0;
    case(wMux)
      2'b01: begin
        if(awaddrA == `YSYX_23060059_UART) begin
          // input 
          awvalidSA    = awvalidA;
          awaddrSA     = awaddrA;
          wdataSA      = wdataA;
          wstrbSA      = wstrbA;
          wvalidSA     = wvalidA;
          breadySA     = breadyA;
          // output
          awreadyA_o_r = awreadySA;
          wreadyA_o_r  = wreadySA;
          // bvalidA_o_r  = bvalidSA;
          brespA_o_r   = brespSA;
        end else begin  // MEMORY WRITE
          awvalidSB    = awvalidA;
          awaddrSB     = awaddrA;
          wdataSB      = wdataA;
          wstrbSB      = wstrbA;
          wvalidSB     = wvalidA;
          breadySB     = breadyA;
          // output
          awreadyA_o_r = awreadySB;
          wreadyA_o_r  = wreadySB;
          // bvalidA_o_r  = bvalidSB;
          brespA_o_r   = brespSB;
        end
      end
      2'b10: begin
        if(awaddrB == `YSYX_23060059_UART) begin
          // input 
          awvalidSA    = awvalidB;
          awaddrSA     = awaddrB;
          wdataSA      = wdataB;
          wstrbSA      = wstrbB;
          wvalidSA     = wvalidB;
          breadySA     = breadyB;
          // output
          awreadyB_o_r = awreadySA;
          wreadyB_o_r  = wreadySA;
          // bvalidB_o_r  = bvalidSA;
          brespB_o_r   = brespSA;
        end else begin  // MEMORY WRITE
          awvalidSB    = awvalidB;
          awaddrSB     = awaddrB;
          wdataSB      = wdataB;
          wstrbSB      = wstrbB;
          wvalidSB     = wvalidB;
          breadySB     = breadyB;
          // output
          awreadyB_o_r = awreadySB;
          wreadyB_o_r  = wreadySB;
          // bvalidB_o_r  = bvalidSB;
          brespB_o_r   = brespSB;
        end
      end
    default: begin end
    endcase
  end

  assign awreadyA_o  = awreadyA_o_r;
  assign wreadyA_o   = wreadyA_o_r;
  assign bvalidA_o   = bvalidA_o_r;
  assign brespA_o    = brespA_o_r;

  assign awreadyB_o  = awreadyB_o_r;
  assign wreadyB_o   = wreadyB_o_r;
  assign bvalidB_o   = bvalidB_o_r;
  assign brespB_o    = brespB_o_r;

  always @(*) begin
    case(wMux_s)
    2'b01: begin
      if(awaddrA == `YSYX_23060059_UART)
        bvalidA_o_r  = bvalidSA;
      else 
        bvalidA_o_r  = bvalidSB;
      bvalidB_o_r = 0;
    end
    2'b10: begin
      if(awaddrB == `YSYX_23060059_UART)
        bvalidB_o_r = bvalidSA;
      else 
        bvalidB_o_r  = bvalidSB;
      bvalidA_o_r = 0;
    end
    default: begin
      bvalidA_o_r = 0;
      bvalidB_o_r = 0;
    end
    endcase
  end 

endmodule