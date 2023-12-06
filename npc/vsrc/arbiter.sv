module arbiter(
  input    wire          clk,
  input    wire          rst,
  input    wire  [31:0]  araddrA,
  input    wire  [31:0]  araddrB,
  input    wire          arvalidA,
  input    wire          arvalidB,
  input    wire          rreadyA,
  input    wire          rreadyB,
  input    wire  [31:0]  awaddrA,
  input    wire  [31:0]  awaddrB,
  input    wire          awvalidA,
  input    wire          awvalidB,
  input    wire  [31:0]  wdataA,
  input    wire  [31:0]  wdataB,
  input    wire  [7 :0]  wstrbA,
  input    wire  [7 :0]  wstrbB,
  input    wire          wvalidA,
  input    wire          wvalidB,
  input    wire          breadyA,
  input    wire          breadyB,
  output   wire          arreadyA,
  output   wire          arreadyB,
  output   wire  [31:0]  rdataA,
  output   wire  [31:0]  rdataB,
  output   wire          rvalidA,
  output   wire          rvalidB,
  output   wire  [1 :0]  rrespA,
  output   wire  [1 :0]  rrespB,
  output   wire          awreadyA,
  output   wire          awreadyB,
  output   wire          wreadyA,
  output   wire          wreadyB,
  output   wire          bvalidA,
  output   wire          bvalidB,
  output   wire  [1 :0]  brespA, 
  output   wire  [1 :0]  brespB
);
  parameter IDLE = 0, MEM_R_A = 1, MEM_R_B = 2;
  reg   [1 :0]  ar_state;
  reg   [1 :0]  ar_next_state;
  reg   [1 :0]  araddrMux;
  reg           arvalid;
  wire  [31:0]  araddr;
  wire          arready;
  wire          rready;
  wire  [31:0]  rdata;
  wire  [1 :0]  rresp;
  wire          rvalid;

  always @(posedge clk) begin
    if(rst) ar_state <= 0;
    else    ar_state <= ar_next_state; 
  end

  always@(*) begin
    case(ar_state)
      IDLE:
        if((arvalidA || arvalidB) && arready)
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

  reg   [1 :0]  araddrMux_s;  // for save
  always @(posedge clk) begin
    if(rst) begin
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
        arvalid   = 1;
      end else if(arvalidB) begin
        araddrMux = 2'b10;
        arvalid   = 1;
      end else begin
        araddrMux = araddrMux_s;  // waiting response
        arvalid   = 0;
      end
    end else begin
      araddrMux = araddrMux_s;
      arvalid   = 0;
    end
  end

  MuxKeyWithDefault #(2, 2, 32) a_m1(araddr, araddrMux, 32'b0, {
    2'b01, araddrA,
    2'b10, araddrB
  });

  MuxKeyWithDefault #(1, 2, 1) a_m2(arreadyA, araddrMux, 0, {
    2'b01, arready
  });
  MuxKeyWithDefault #(1, 2, 1) a_m3(arreadyB, araddrMux, 0, {
    2'b10, arready
  });

  MuxKeyWithDefault #(2, 2, 1) a_m4(rready, araddrMux, 1'b0, {
    2'b01, rreadyA,
    2'b10, rreadyB
  });
  MuxKeyWithDefault #(1, 2, 32) a_m5(rdataA, araddrMux, 32'b0, {
    2'b01, rdata
  });
  MuxKeyWithDefault #(1, 2, 32) a_m6(rdataB, araddrMux, 32'b0, {
    2'b10, rdata
  });
  MuxKeyWithDefault #(1, 2, 2) a_m7 (rrespA, araddrMux, 2'b10, {
    2'b01, rresp
  });
  MuxKeyWithDefault #(1, 2, 2) a_m8 (rrespB, araddrMux, 2'b10, {
    2'b10, rresp
  });
  MuxKeyWithDefault #(1, 2, 1) a_m9 (rvalidA, araddrMux, 1'b0, {
    2'b01, rvalid
  });
  MuxKeyWithDefault #(1, 2, 1) a_m10 (rvalidB, araddrMux, 1'b0, {
    2'b10, rvalid
  });

  parameter MEM_W_A = 1, MEM_W_B = 2;
  reg   [1 :0]  wMux;
  reg           wait_for_write_addr;
  reg           awvalid;
  wire  [31:0]  awaddr;
  wire          awready;
  reg   [1 :0]  aw_state;
  reg   [1 :0]  aw_next_state;

  reg           wvalid;
  wire  [31:0]  wdata;
  wire  [7 :0]  wstrb;
  wire          wready;
  wire          bvalid;
  wire          bready;
  wire  [1 :0]  bresp;
  always @(posedge clk) begin
    if(rst) aw_state <= 0;
    else    aw_state <= aw_next_state; 
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

  reg   [1 :0]  wMux_s;  // for save
  always @(posedge clk) begin
    if(rst) begin
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
        awvalid   = 1;
        wvalid    = 1;
        wMux      = 2'b01;
      end else if(awvalidB) begin
        awvalid   = 1;
        wvalid    = 1;
        wMux      = 2'b10;
      end else begin
        wMux      = wMux_s;
        awvalid   = 0;
        wvalid    = 0;
      end
    end else begin
      wMux    = wMux_s;
      awvalid = 0;
      wvalid  = 0;
    end
  end

  MuxKeyWithDefault #(2, 2, 32) a_m11(awaddr, wMux, 32'b0, {
    2'b01, awaddrA,
    2'b10, awaddrB
  });

  MuxKeyWithDefault #(1, 2, 1) a_m12(awreadyA, wMux, 1'b0, {
    2'b01, awready
  });
  MuxKeyWithDefault #(1, 2, 1) a_m13(awreadyB, wMux, 1'b0, {
    2'b10, awready
  });


  MuxKeyWithDefault #(2, 2, 32) a_m14(wdata, wMux, 32'b0, {
    2'b01, wdataA,
    2'b10, wdataB
  });

  MuxKeyWithDefault #(2, 2, 8) a_m15(wstrb, wMux, 8'b0, {
    2'b01, wstrbA,
    2'b10, wstrbB
  });

  MuxKeyWithDefault #(1, 2, 1) a_m16(wreadyA, wMux, 1'b0, {
    2'b01, wready
  });
  MuxKeyWithDefault #(1, 2, 1) a_m17(wreadyB, wMux, 1'b0, {
    2'b10, wready
  });

  MuxKeyWithDefault #(1, 2, 1) a_m18(bvalidA, wMux, 1'b0, {
    2'b01, bvalid
  });
  MuxKeyWithDefault #(1, 2, 1) a_m19(bvalidB, wMux, 1'b0, {
    2'b10, bvalid
  });

  MuxKeyWithDefault #(2, 2, 1) a_m20(bready, wMux, 1'b0, {
    2'b01, breadyA,
    2'b10, breadyB
  });

  MuxKeyWithDefault #(1, 2, 2) a_m21(brespA, wMux, 2'b01, {
    2'b01, bresp
  });
  MuxKeyWithDefault #(1, 2, 2) a_m22(brespB, wMux, 2'b01, {
    2'b10, bresp
  });

  axi_sram ar(
    .aclk(clk),
    .areset(rst),
    .araddr(araddr),
    .arvalid(arvalid),
    .arready(arready),
    .rready(rready),
    .rdata(rdata),
    .rvalid(rvalid),
    .rresp(rresp),
    .awaddr(awaddr),
    .awvalid(awvalid),
    .wdata(wdata),
    .wstrb(wstrb),
    .wvalid(wvalid),
    .bready(bready),
    .awready(awready),
    .wready(wready),
    .bvalid(bvalid),
    .bresp(bresp)
  );


endmodule