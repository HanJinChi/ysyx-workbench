module lsu (
    input                 clk,
    input                 rst,
    input                 ren,
    input                 wen,
    input                 memory_read_signed,
    input   [31:0]        rsb,
    input   [7 :0]        wmask,
    input   [31:0]        rmask,
    input   [31:0]        exu_result,
    // output                wbu_valid,
    output  [31:0]        memory_read_wd
);
  
  reg  [31:0]     data;
  wire            sram_valid;
  // sram srb(
  //   // .clk(clk),
  //   // .rst(rst),
  //   .ren(ren),
  //   .wen(wen),
  //   .wmask(wmask),
  //   .addr(exu_result),
  //   .wdata(rsb),
  //   .data(data)
  //   // .sram_valid(sram_valid)
  // );

  MuxKeyWithDefault #(3, 32, 32) rwd(memory_read_wd, rmask, 32'h0, {
    32'h000000ff, memory_read_signed ? {{24{data[7]}} , data[7:0]}  : data & rmask,
    32'h0000ffff, memory_read_signed ? {{16{data[15]}}, data[15:0]} : data & rmask,
    32'hffffffff, data
  });

  always @(*) begin
    if(ren)    n_pmem_read(exu_result, data);
    else       data = 0;
    if(wen)    n_pmem_write(exu_result, rsb, wmask);
    else       n_pmem_write(exu_result, rsb, 0);
  end
  
  // assign wbu_valid = (ren == 1) ? (sram_valid) : 1; // 只有取值命令才需要等待sram返回值
    
endmodule