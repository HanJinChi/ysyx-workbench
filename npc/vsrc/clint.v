module ysyx_23060059_clint(
    input   wire         clock,
    input   wire         reset,
    output  wire  [63:0] mtime  
);

  reg [63:0] time_r;
  always @(posedge clock) begin
    if(reset) begin
      time_r <= 0;    
    end else begin
      time_r <= time_r + 1;
    end
  end

    


endmodule