module ifu(
    input                 clk,
    input                 rst,
    input      [31:0]     pc_next,
    output                idu_valid,
    output  reg   [31:0]  instruction
);

  wire   [31:0]      data;
  wire               ren;
  wire               wen;
  wire   [7: 0]      wmask;
  wire   [31:0]      wdata;
  wire               sram_valid;
  wire   [31:0]      sram_addr;   
  reg    [31:0]      reg_pc_next;
  reg                reg_ren;

 
  sram sr(
    .clk(clk),
    .rst(rst),
    .ren(ren),
    .wen(wen),
    .wmask(wmask),
    .addr(sram_addr),
    .wdata(wdata),
    .data(instruction),
    .sram_valid(sram_valid)
  );

  assign wen = 1'b0; // 写不使能
  assign wmask = 8'b0;
  assign wdata = 32'h0;
  assign ren = reg_ren;
  assign idu_valid = sram_valid;
  assign sram_addr = (reg_pc_next == 32'h0) ? 32'h80000000 : reg_pc_next;

  always@(posedge clk) begin
    if(!rst) begin
      reg_pc_next <= pc_next;  
      reg_ren <= 1;
    end
    else begin
      reg_pc_next <= 32'h80000000;
      reg_ren <= 0;
    end
  end



endmodule