module sdram(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [12:0] a,   // 地址
  input [ 1:0] ba,  // 存储体地址
  input [ 1:0] dqm, // 数据掩码
  inout [15:0] dq   
);

  localparam SDRAM_BANK_W          = 2;
  localparam SDRAM_DQM_W           = 2;
  localparam SDRAM_BANKS           = 2 ** SDRAM_BANK_W;

  reg out;
  assign dq = 16'bz;
  wire [15:0] din;
  assign din = dq;
  assign dq = out ? dout : 16'bz;



endmodule
