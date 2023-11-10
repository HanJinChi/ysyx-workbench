module ifu(
    input                 clk,
    input                 rst,
    input      [31:0]     pc_next,
    // output                idu_valid,
    output     [31:0]     instruction
);

  // wire   [31:0]      data;
  // wire               ren;
  // wire               wen;
  // wire   [7: 0]      wmask;
  // wire   [31:0]      wdata;
  // wire               sram_valid;   
 
  // sram sr(
  //   // .clk(clk),
  //   // .rst(rst),
  //   .ren(ren),
  //   .wen(wen),
  //   .wmask(wmask),
  //   .addr(pc_next),
  //   .wdata(wdata),
  //   .data(instruction)
  //   // .sram_valid(sram_valid)
  // );

  // assign wen = 1'b0; // 写不使能
  // assign wmask = 8'b0;
  // assign wdata = 32'h0;
  // assign idu_valid = sram_valid;

  always@(posedge clk) begin
    if(!rst) begin
      n_pmem_read(pc_next, instruction);
    end
  end 

endmodule