module RegArray(
    input clk,
    input rst,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd, // write reg 
    input [31:0] wd,
    input rwEnable,
    output [31:0] rsa,
    output [31:0] rsb,
    output [31:0] rdd
);
  reg  [31:0] regarray [31:0];
  wire [31:0] w_regarray_subsequent[31:0]; // directly modify
  wire [31:0] w_regarray_previous[31:0];

  genvar i;
  generate
      for( i = 0; i < 32; i = i+1) begin
        Reg #(32, 32'b0) regx(clk, rst, w_regarray_subsequent[i], regarray[i], 1);
      end
  endgenerate

  generate
    for(i = 0; i < 32; i = i+1) begin
      assign w_regarray_previous[i] = regarray[i];
    end
  endgenerate

  generate
    for(i = 1; i < 32; i = i+1) begin
      assign w_regarray_subsequent[i] = (rwEnable == 1) ? ((rd == i) ? wd : w_regarray_previous[i]) : w_regarray_previous[i];
    end
  endgenerate

  assign w_regarray_subsequent[0] = 32'b0;

  assign rsa = regarray[rs1];
  assign rsb = regarray[rs2];
  assign rdd = regarray[rd];


endmodule