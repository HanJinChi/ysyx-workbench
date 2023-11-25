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
  MuxKeyWithDefault #(1, 2, 1) a_m10 (rvalidB, araddrMux, 1'b0, {
    2'b10, rvalid
  });

  always @(posedge clk) begin
    if(rready && rvalid) begin
      assert(araddrMux != 0);
      araddrMux <= 0;
    end
  end

  reg   [1 :0]  awaddrMux;
  reg           wait_for_write_addr;
  reg           awvalid;
  wire  [31:0]  awaddr;
  wire          awready;
  always @(posedge clk) begin
    if(rst) begin
      awaddrMux <= 0;  // 默认选择情况下谁都不选择
      wait_for_write_addr <= 0;
    end
    else begin
      if(wait_for_write_addr) begin
        if(awready) begin
          assert(awvalid == 1);
          wait_for_write_addr <= 0;
          awvalid <= 0; 
          awaddrMux <= 0;  
        end
      end else begin
        if(awvalidA) begin
          awvalid <= 1;
          awaddrMux <= 2'b01;
          if(!awready) wait_for_write_addr <= 1;
        end else if(awvalidB) begin
          awvalid <= 1;
          awaddrMux <= 2'b10;
          if(!awready) wait_for_write_addr <= 1;
        end else begin
          if(awvalid && awready) begin
            awvalid <= 1'b0;
            awaddrMux <= 0;
          end 
        end
      end
    end
  end

  MuxKeyWithDefault #(2, 2, 32) a_m11(awaddr, awaddrMux, 32'b0, {
    2'b01, awaddrA,
    2'b10, awaddrB
  });

  // 使用流水线时要进行修改
  MuxKeyWithDefault #(1, 2, 1) a_m12(awreadyA, awaddrMux, 1'b0, {
    2'b01, awready
  });
  MuxKeyWithDefault #(1, 2, 1) a_m13(awreadyB, awaddrMux, 1'b0, {
    2'b10, awready
  });

  reg   [1 :0]  wdataMux;
  reg           wait_for_write_data;
  reg           wvalid;
  wire  [31:0]  wdata;
  wire  [7 :0]  wstrb;
  wire          wready;
  wire          bvalid;
  wire          bready;
  wire  [1 :0]  bresp;
  always @(posedge clk) begin
    if(rst) begin
      wdataMux <= 0;  // 默认选择情况下谁都不选择
      wait_for_write_data <= 0;
    end
    else begin
      if(wait_for_write_data) begin
        if(wready) begin
          assert(wvalid == 1);
          wait_for_write_data <= 0;
          wvalid <= 0; 
          // wdataMux <= 0;  
        end
      end else begin
        if(wvalidA) begin
          wvalid <= 1;
          wdataMux <= 2'b01;
          if(!wready) wait_for_write_data <= 1;
        end else if(wvalidB) begin
          wvalid <= 1;
          wdataMux <= 2'b10;
          if(!wready) wait_for_write_data <= 1;
        end else begin
          if(wvalid && wready) begin
            wvalid <= 1'b0;
            // wdataMux <= 0;
          end 
        end
      end
    end
  end

  MuxKeyWithDefault #(2, 2, 32) a_m14(wdata, wdataMux, 32'b0, {
    2'b01, wdataA,
    2'b10, wdataB
  });

  MuxKeyWithDefault #(2, 2, 8) a_m15(wstrb, wdataMux, 8'b0, {
    2'b01, wstrbA,
    2'b10, wstrbB
  });

  // 使用流水线时要进行修改
  MuxKeyWithDefault #(1, 2, 1) a_m16(wreadyA, wdataMux, 1'b0, {
    2'b01, wready
  });
  MuxKeyWithDefault #(1, 2, 1) a_m17(wreadyB, wdataMux, 1'b0, {
    2'b10, wready
  });

  MuxKeyWithDefault #(1, 2, 1) a_m18(bvalidA, wdataMux, 1'b0, {
    2'b01, bvalid
  });
  MuxKeyWithDefault #(1, 2, 1) a_m19(bvalidB, wdataMux, 1'b0, {
    2'b10, bvalid
  });

  MuxKeyWithDefault #(2, 2, 1) a_m20(bready, wdataMux, 1'b0, {
    2'b01, breadyA,
    2'b10, breadyB
  });

  MuxKeyWithDefault #(1, 2, 2) a_m21(brespA, wdataMux, 2'b01, {
    2'b01, bresp
  });
  MuxKeyWithDefault #(1, 2, 2) a_m22(brespB, wdataMux, 2'b01, {
    2'b10, bresp
  });

  always@(posedge clk) begin
    if(bready && bvalid) wdataMux <= 0;
  end

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