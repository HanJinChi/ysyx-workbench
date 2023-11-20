module arbiter(
  input    wire          clk,
  input    wire          rst,
  input    wire  [31:0]  araddrA,
  input    wire  [31:0]  araddrB,
  input    wire          arvalidA,
  input    wire          arvalidB,
  input    wire          rreadyA,
  input    wire          rreadyB,
  output   wire          arreadyA,
  output   wire          arreadyB,
  output   wire  [31:0]  rdataA,
  output   wire  [31:0]  rdataB,
  output   wire          rvalidA,
  output   wire          rvalidB,
  output   wire  [1 :0]  rrespA,
  output   wire  [1 :0]  rrespB
);
  reg   [1 :0]  araddrMux;
  reg           wait_for_read_addr;
  reg           arvalid;
  wire  [31:0]  araddr;
  wire          arready;
  always @(posedge clk) begin
    if(rst) begin
      araddrMux <= 0;  // 默认选择情况下谁都不选择
      wait_for_read_addr <= 0;
    end
    else begin
      if(wait_for_read_addr) begin
        if(arready) begin
          assert(arvalid == 1);
          wait_for_read_addr <= 0;
          arvalid <= 0; 
          // araddrMux <= 0;  // 后续的读取数据选择还要使用araddrMux,因此在这里不能置0
        end
      end else begin
        if(arvalidA) begin
          arvalid <= 1;
          araddrMux <= 2'b01;
          if(!arready) wait_for_read_addr <= 1;
        end else if(arvalidB) begin
          arvalid <= 1;
          araddrMux <= 2'b10;
          if(!arready) wait_for_read_addr <= 1;
        end else begin
          if(arvalid && arready) arvalid <= 1'b0; 
        end
      end
    end
  end

  MuxKeyWithDefault #(2, 2, 32) a_m1(araddr, araddrMux, 32'b0, {
    2'b01, araddrA,
    2'b10, araddrB
  });

  // 使用流水线时要进行修改
  MuxKeyWithDefault #(1, 2, 1) a_m2(arreadyA, araddrMux, 1'b0, {
    2'b01, arready
  });
  MuxKeyWithDefault #(1, 2, 1) a_m3(arreadyB, araddrMux, 1'b0, {
    2'b10, arready
  });

  wire          rready;
  wire  [31:0]  rdata;
  wire  [1 :0]  rresp;
  wire          rvalid;
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
  MuxKeyWithDefault #(1, 2, 1) a_m10 (rvalidB, araddrMux, 1'b1, {
    2'b10, rvalid
  });

  always @(posedge clk) begin
    if(rready && rvalid) begin
      assert(araddrMux != 0);
      araddrMux <= 0;
    end
  end

  wire          awready;
  wire          wready;
  wire          bvalid;
  wire   [1:0]  bresp;
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
    .awaddr(0),
    .awvalid(0),
    .wdata(0),
    .wstrb(0),
    .wvalid(0),
    .bready(0),
    .awready(awready),
    .wready(wready),
    .bvalid(bvalid),
    .bresp(bresp)
  );


endmodule