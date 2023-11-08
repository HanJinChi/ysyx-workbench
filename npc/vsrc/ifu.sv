module ifu(
    input                 clk,
    input                 rst,
    input   [31:0]        pc_next,
    output  [31:0]        instruction
);

  always@(posedge clk) begin
    if(!rst) begin
      n_pmem_read(pc_next, instruction);
    end
  end


endmodule