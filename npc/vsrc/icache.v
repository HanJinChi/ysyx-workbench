`include "defines.v"

// 4KB data array
// nset       : 32
// nway       : 8
// block size : 128bit, 16Byte
// meta size  : 25bit, 23bit tag + 1 bit valid + 1bit dirty 

module ysyx_23060059_icache(
  input    wire           clock,
  input    wire           reset,
  input    wire           arvalid,
  input    wire  [31 :0]  addr_i,
  output   wire  [31 :0]  data_o,
  output   wire           rvalid,
  // axi part
  input    wire           axi_arready,
  input    wire  [31 :0]  axi_rdata,
  input    wire           axi_rvalid,
  input    wire  [1  :0]  axi_rresp,
  output   wire           axi_arvalid,
  output   wire           axi_rready,
  output   wire  [31 :0]  axi_araddr,

  //
  output   wire  [5  :0]  io_sram0_addr,
  output   wire           io_sram0_cen,
  output   wire           io_sram0_wen,
  output   wire  [127:0]  io_sram0_wmask,
  output   wire  [127:0]  io_sram0_wdata,
  input    wire  [127:0]  io_sram0_rdata,

  output   wire  [5  :0]  io_sram1_addr,
  output   wire           io_sram1_cen,
  output   wire           io_sram1_wen,
  output   wire  [127:0]  io_sram1_wmask,
  output   wire  [127:0]  io_sram1_wdata,
  input    wire  [127:0]  io_sram1_rdata,

  output   wire  [5  :0]  io_sram2_addr,
  output   wire           io_sram2_cen,
  output   wire           io_sram2_wen,
  output   wire  [127:0]  io_sram2_wmask,
  output   wire  [127:0]  io_sram2_wdata,
  input    wire  [127:0]  io_sram2_rdata,

  output   wire  [5  :0]  io_sram3_addr,
  output   wire           io_sram3_cen,
  output   wire           io_sram3_wen,
  output   wire  [127:0]  io_sram3_wmask,
  output   wire  [127:0]  io_sram3_wdata,
  input    wire  [127:0]  io_sram3_rdata 
);

  localparam nset = 32;
  localparam nway = 8;
  // icache data size = 32*8*16B = 4KB

  wire  [24:0] meta [255:0];  // meta array

  genvar i;
  generate
    for(i = 0; i < 256; i = i+1) begin
      Reg #(25,25'b0) u_reg_meta(clock, reset, , meta[i], );
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

  reg  [2:0] state, next_state;
  localparam IDLE = 0, HIT = 1, MISS = 2;

  always @(posedge clock) begin
    if(reset) state <= IDLE;
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

  wire [2:0]  rway;
  reg  axi_arvalid_r;
  reg  axi_rready_r;
  always @(posedge clock) begin
    if(reset) begin
      axi_arvalid_r <= 0;
      axi_rready_r  <= 0;
    end else begin
      if(next_state == MISS) begin
        axi_arvalid_r <= 1;
        axi_araddr    <= araddr_r;
      end
    end
  end

  reg [2:0] way;
  reg       invalid;
  reg       access; 
  always @(*) begin
    way     = 0;
    access  = 0;
    invalid = 0;
    if(next_state == MISS) begin
      way = rway;
      access = 0;
      if(meta[idx*nset+rway][23]) invalid = 1;
      else                        invalid = 0;
    end
  end


  ysyx_23060059_replacer u_replacer(
    .clock          (clock     ),
    .reset          (reset     ),
    .idx          (idx     ),
    .way          (way     ),
    .access       (access  ),
    .invalid      (invalid ),
    .rway_o       (rway    )
  );

endmodule