module lsu (
    input                 clk,
    input                 rst,
    input                 lsu_receive_valid,
    input                 ren,
    input                 wen,
    input                 memory_read_signed,
    input   [31:0]        rsb,
    input   [7 :0]        wmask,
    input   [31:0]        rmask,
    input   [31:0]        exu_result,
    output                lsu_send_valid,
    output  [31:0]        memory_read_wd
);

  wire  [31:0]    data;
  reg             arvalid, rready;
  reg   [31:0]    araddr;
  reg             wait_for_read_address;
  wire            arready, rvalid;
  // rready
  always @(posedge clk) begin
    if(rst) rready <= 0;
    else    rready <= 1;
  end 
  // arvalid
  always @(posedge clk) begin
    if(rst) begin
      arvalid <= 0;
      araddr <= 0;
      wait_for_read_address <= 0;
    end else begin
      if(wait_for_read_address) begin
        if(arready) begin
          assert(arvalid == 1);
          wait_for_read_address <= 0;
          arvalid <= 0;
        end 
      end else begin
        if(lsu_receive_valid && ren) begin
          assert(arvalid == 0);
          arvalid <= 1;
          araddr <= exu_result;
          if(!arready) wait_for_read_address <= 1;
        end else begin
          if(arvalid && arready) arvalid <= 0;
        end
      end
    end
  end
  reg [31:0] reg_read_data;
  reg        read_data_valid;
  always @(posedge clk) begin
    if(rst) begin
      reg_read_data <= 0;
      read_data_valid <= 0;
    end else begin
      if(rvalid && rready) begin
        reg_read_data <= data;
        read_data_valid <= 1;
      end else begin
        read_data_valid <= 0;
      end
    end
  end
 
  MuxKeyWithDefault #(3, 32, 32) rwd(memory_read_wd, rmask, 32'h0, {
    32'h000000ff, memory_read_signed ? {{24{reg_read_data[7]}} , reg_read_data[7:0]}  : reg_read_data & rmask,
    32'h0000ffff, memory_read_signed ? {{16{reg_read_data[15]}}, reg_read_data[15:0]} : reg_read_data & rmask,
    32'hffffffff, reg_read_data
  });

  reg [31:0] awaddr;
  reg [31:0] wdata;
  reg [7:0]  wstrb;
  reg        awvalid, wvalid;
  reg        wait_for_write_address;
  reg        wait_for_write_data;
  wire       awready, wready;

  // 传输地址
  always @(posedge clk) begin
    if(rst) begin
      awaddr <= 0;;
      wait_for_write_address <= 0;
    end else begin
      if(wait_for_write_address) begin
        if(awready) begin
          assert(awvalid == 1);
          wait_for_write_address <= 0;
          awvalid <= 0;
        end
      end else begin
        if(lsu_receive_valid && wen) begin
          assert(awvalid == 0);
          awvalid <= 1;
          awaddr <= exu_result;
          if(!awready) wait_for_write_address <= 1;
        end else begin
          if(awvalid && awready) awvalid <= 0;
        end
      end
    end
  end
  // 传输数据
  always @(posedge clk) begin
    if(rst) begin
      wdata <= 0;
      wait_for_write_data <= 0;
    end else begin
      if(wait_for_write_data) begin
        if(wready) begin
          assert(wvalid == 1);
          wait_for_write_data <= 0;
          wvalid <= 0;
        end 
      end else begin
        if(lsu_receive_valid && wen) begin
          assert(wvalid == 0);
          wvalid <= 1;
          wdata <= rsb;
          if(!wready) wait_for_write_data <= 1;
        end else begin
          if(wvalid && wready) wvalid <= 0;
        end
      end
    end
  end

  wire write_data_valid;
  assign write_data_valid = wvalid && wready;

  axi_sram axi_sa(
    .aclk(clk),
    .areset(rst),
    .araddr(araddr),
    .arvalid(arvalid),
    .rready(rready),
    .awaddr(exu_result),
    .awvalid(awvalid),
    .wdata(rsb),
    .wstrb(wmask),
    .wvalid(wvalid),
    .arready(arready),
    .data(data),
    .rvalid(rvalid),
    .awready(awready),
    .wready(wready)
  );
  
  assign lsu_send_valid = (lsu_receive_valid == 1) ? (((ren == 1)||(wen == 1)) ? (read_data_valid || write_data_valid) : 1) : (read_data_valid || write_data_valid); // 只有取值命令才需要等待sram返回值

endmodule