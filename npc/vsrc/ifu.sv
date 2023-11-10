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
  reg    [31:0]      reg_pc_next;


  // Reg #(32, 32'h80000000) regdx(clk, rst, pc_next, reg_pc_next, 1); // assign pc value

 
  // sram sr(
  //   // .clk(clk),
  //   // .rst(rst),
  //   .ren(ren),
  //   .wen(wen),
  //   .wmask(wmask),
  //   .addr(reg_pc_next),
  //   .wdata(wdata),
  //   .data(instruction)
  //   // .sram_valid(sram_valid)
  // );

  // assign wen = 1'b0; // 写不使能
  // assign wmask = 8'b0;
  // assign wdata = 32'h0;
  // assign ren = 1'b1;
  // assign idu_valid = sram_valid;

  always@(posedge clk) begin
    if(!rst) reg_pc_next <= pc_next;  
    else     reg_pc_next <= 32'h80000000;
  end

  always@(*) begin
    n_pmem_read(reg_pc_next, instruction);
  end 

endmodule