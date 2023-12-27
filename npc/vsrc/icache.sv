`include "defines.sv"

// 4KB data array
// nset       : 8
// nway       : 8
// block size : 512bit , 64Byte
// meta size  : 25bit, 23bit tag + 1 bit valid + 1bit dirty 

module icache(
  input    wire          clk,
  input    wire          rst,
  input    wire          arvalid,
  input    wire  [31:0]  addr_i,
  output   wire  [31:0]  data_o,
  output   wire          rvalid
);

  localparam nset = 8;
  localparam nway = 8;
  // icache data size = 8*8*64B = 4KB
  wire  [63:0] data [511:0];  // data array
  wire  [63:0] meta [511:0];  // meta array

  genvar i;
  generate
      for(i = 0; i < 64; i = i+1) begin
        Reg #(512,512'b0) u_reg_data(clk, rst, , data[i], );
      end
  endgenerate
  
  generate
    for(i = 0; i < 64; i = i+1) begin
      Reg #(25,25'b0) u_reg_meta(clk, rst, , meta[i], );
    end
  endgenerate

  reg [2:0] idx;
  reg       hit;
  reg [2:0] hway;
  always @(*) begin
    idx  = addr_i[8:6];
    hit  = 0;
    hway = 0;
    for(int w = 0; w < nway; w++) begin
      if(meta[idx*nset+w][23] && meta[idx*nset+w][22:0] == addr_i[31:9]) begin
        hit  = 1'b1;
        hway = w;
      end
    end
  end
  assign hit = &hit_array;

  reg  [2:0] state, next_state;
  localparam IDLE = 0, HIT = 1, MISS = 2;


  always @(posedge clk) begin
    if(rst) state <= IDLE;
    else    state <= next_state;
  end

  always @(*) begin
    case(state)
      IDLE:
        if(arvalid)
          if(hit)
            next_state = HIT;
          else
            next_state = MISS;
        else
          next_state = IDLE;
    endcase
  end

//   always @(posedge) begin

//   end

endmodule