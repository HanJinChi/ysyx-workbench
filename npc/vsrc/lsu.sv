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
  
  reg  [31:0]     data;
  wire            sram_valid;
  wire            sram_ren;
  wire            sram_wen;
  sram srb(
    .clk(clk),
    .rst(rst),
    .ren(sram_ren),
    .sram_receive_valid(1),
    .wen(sram_wen),
    .wmask(wmask),
    .addr(exu_result),
    .wdata(rsb),
    .data(data),
    .sram_valid(sram_valid)
  );

  MuxKeyWithDefault #(3, 32, 32) rwd(memory_read_wd, rmask, 32'h0, {
    32'h000000ff, memory_read_signed ? {{24{data[7]}} , data[7:0]}  : data & rmask,
    32'h0000ffff, memory_read_signed ? {{16{data[15]}}, data[15:0]} : data & rmask,
    32'hffffffff, data
  });

  
  assign lsu_send_valid = ((ren == 1) ? (sram_valid) : wen); // 只有取值命令才需要等待sram返回值
  assign sram_ren = (lsu_receive_valid == 1) ? ren : 0;
  assign sram_wen = (lsu_receive_valid == 1) ? wen : 0;
    
endmodule