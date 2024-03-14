`include "defines.v"

// 4KB data array
// nset       : 32
// nway       : 8
// block size : 128bit, 16Byte
// meta size  : 25bit, 23bit tag + 1 bit valid + 1bit dirty 

module ysyx_23060059_icache(
  input    wire           clock,
  input    wire           reset,
  // icache <-> ifu
  input    wire           arvalid,
  input    wire  [31 :0]  addr_i,
  input    wire           rready,
  output   wire  [63 :0]  data_o,
  output   wire           rvalid,
  output   wire           arready,
  // axi part
  // icache <-> axi, ar channel
  output   wire  [31 :0]  axi_araddr,
  output   wire  [3  :0]  axi_arid,
  output   wire  [7  :0]  axi_arlen,
  output   wire  [2  :0]  axi_arsize,
  output   wire  [1  :0]  axi_arburst,
  output   wire           axi_arvalid,
  input    wire           axi_arready,
  // icache <-> axi, r channel
  input    wire  [63 :0]  axi_rdata,
  input    wire           axi_rvalid,
  input    wire  [1  :0]  axi_rresp,
  input    wire           axi_rlast,
  input    wire  [3 :0]   axi_rid,
  output   wire           axi_rready
  // //
  // output   wire  [5  :0]  io_sram0_addr,
  // output   wire           io_sram0_cen,
  // output   wire           io_sram0_wen,
  // output   wire  [127:0]  io_sram0_wmask,
  // output   wire  [127:0]  io_sram0_wdata,
  // input    wire  [127:0]  io_sram0_rdata,

  // output   wire  [5  :0]  io_sram1_addr,
  // output   wire           io_sram1_cen,
  // output   wire           io_sram1_wen,
  // output   wire  [127:0]  io_sram1_wmask,
  // output   wire  [127:0]  io_sram1_wdata,
  // input    wire  [127:0]  io_sram1_rdata,

  // output   wire  [5  :0]  io_sram2_addr,
  // output   wire           io_sram2_cen,
  // output   wire           io_sram2_wen,
  // output   wire  [127:0]  io_sram2_wmask,
  // output   wire  [127:0]  io_sram2_wdata,
  // input    wire  [127:0]  io_sram2_rdata,

  // output   wire  [5  :0]  io_sram3_addr,
  // output   wire           io_sram3_cen,
  // output   wire           io_sram3_wen,
  // output   wire  [127:0]  io_sram3_wmask,
  // output   wire  [127:0]  io_sram3_wdata,
  // input    wire  [127:0]  io_sram3_rdata 
);

  localparam nset = 32;
  localparam nway = 8;
  // icache data size = 32*8*16B = 4KB

  wire  [24:0]  meta  [255:0];  // meta array
  wire  [24:0]  wmeta [255:0];
  wire  [127:0] data  [255:0];  // data array
  wire  [127:0] wdata [255:0];

  genvar i;
  generate
    for(i = 0; i < 256; i = i+1) begin
      Reg #(25,25'b0) u_reg_meta(clock, reset, wmeta[i], meta[i], wen);
    end
  endgenerate

  generate
    for(i = 0; i < 256; i = i+1) begin
      assign wmeta[i] = (wen == 1) ? ( ((idx*nway+{29'h0, way}) == i) ? {1'b0, 1'b1, align_addr[31:9]} : meta[i]) : meta[i];
    end
  endgenerate

  generate
    for(i = 0; i < 256; i = i+1) begin
      Reg #(128,128'b0) u_reg_data(clock, reset, wdata[i], data[i], wen);
    end
  endgenerate

  generate
    for(i = 0; i < 256; i = i+1) begin
      assign wdata[i] = (wen == 1) ? ( ((idx*nway+{29'h0, way}) == i) ?  data_buffer : data[i]) : data[i];
    end
  endgenerate


  reg [4 :0] idx;
  reg        hit;
  reg [2 :0] hway;
  reg [31:0] rdata;
  integer w;
  always @(*) begin
    idx  = addr_i[8:4];
    hit  = 0;
    hway = 0;
    for(w = 0; w < nway; w=w+1) begin
      if(meta[idx*nway+w][23] && meta[idx*nway+w][22:0] == addr_i[31:9]) begin
        hit  = 1'b1;
        hway = w[2:0];
      end
    end
  end

  always @(*) begin
    rdata = 32'b0;
    if(next_state == HIT)
      if(state == MISSC)
        case(addr_i[3:0])
          4'b0000, 4'b0001, 4'b0010, 4'b0011:
            rdata = data_buffer[31:0];
          4'b0100, 4'b0101, 4'b0110, 4'b0111:
            rdata = data_buffer[63:32];
          4'b1000, 4'b1001, 4'b1010, 4'b1011:
            rdata = data_buffer[95:64];
          4'b1100, 4'b1101, 4'b1110, 4'b1111:
            rdata = data_buffer[127:96];
          default: rdata = 32'b0;
        endcase
      else
        case(addr_i[3:0])
          4'b0000, 4'b0001, 4'b0010, 4'b0011:
            rdata = data[idx*nway+{29'h0, hway}][31:0];
          4'b0100, 4'b0101, 4'b0110, 4'b0111:
            rdata = data[idx*nway+{29'h0, hway}][63:32];
          4'b1000, 4'b1001, 4'b1010, 4'b1011:
            rdata = data[idx*nway+{29'h0, hway}][95:64];
          4'b1100, 4'b1101, 4'b1110, 4'b1111:
            rdata = data[idx*nway+{29'h0, hway}][127:96];
          default: rdata = 32'b0;
        endcase
  end



  reg  [2:0] state, next_state;
  typedef enum [2:0] {IDLE, MISSA, MISSB, MISSC, HIT} state_t;


  always @(posedge clock) begin
    if(reset) state <= IDLE;
    else      state <= next_state;
  end

  always @(*) begin
    case(state)
      IDLE:
        if(arvalid)
          if(hit)
            next_state = HIT;
          else
            next_state = MISSA;
        else
          next_state = IDLE;
      MISSA:
        if(axi_arvalid && axi_arready)
          next_state = MISSB;
        else
          next_state = MISSA;
      MISSB:
        if(axi_rvalid && axi_rready)
          if(axi_rresp == 0)
            next_state = MISSC;
          else begin
            next_state = MISSB;
            $display("rresp !=0, error!");
            assert(0);
          end
        else
          next_state = MISSB;
      MISSC:
        if(counter == 2'b0)
          next_state = HIT;
        else
          next_state = MISSA;
      HIT:
        if(rvalid && rready)
          next_state = IDLE;
        else
          next_state = HIT;
      default:
        next_state = IDLE;
    endcase
  end

  wire [2  :0]  rway;
  wire [31 :0]  align_addr;
  reg           axi_arvalid_r;
  reg  [31 :0]  axi_araddr_r;
  reg           rvalid_r;
  reg  [1  :0]  counter;
  reg           wen;
  reg  [127:0]  data_buffer;
  reg  [31 :0]  data_r;

  assign align_addr = {addr_i[31:4], 4'h0};

  always @(posedge clock) begin
    if(reset) 
      axi_arvalid_r <= 0;
    else begin
      if(next_state == MISSA) 
        axi_arvalid_r <= 1;
      else if(next_state == MISSB)
        axi_arvalid_r <= 0;
    end
  end

  always @(posedge clock) begin
    if(reset) 
      axi_araddr_r <= 0;
    else begin
      if(next_state == MISSA) 
        axi_araddr_r <= align_addr + {28'h0,counter,2'h0} ;
    end
  end

  always @(posedge clock) begin
    if(reset) wen <= 0;
    else 
      if(next_state == MISSC)
        if(counter == 2'b0) 
          wen <= 1'b1;
        else
          wen <= 1'b0;
      else
        wen <= 1'b0;
  end

  always @(posedge clock) begin
    if(reset) counter <= 0;
    else begin
      if(next_state == MISSB)
        if(axi_arvalid && axi_arready) 
          counter <= counter + 1;
    end
  end

  always @(posedge clock) begin
    if(reset) data_buffer <= 0;
    else begin
      if(next_state == MISSC) 
        data_buffer <= {axi_rdata[31:0], data_buffer[127:32]};
    end
  end

  always @(posedge clock) begin
    if(reset) rvalid_r <= 0;
    else begin
      if(next_state == HIT)
        rvalid_r <= 1;
      else
        rvalid_r <= 0;
    end
  end

  always @(posedge clock) begin
    if(reset) data_r <= 0;
    else begin
      if(next_state == HIT)
        data_r <= rdata;
    end
  end

  assign data_o      = {32'h0, data_r};
  assign axi_arvalid = axi_arvalid_r;
  assign rvalid      = rvalid_r;
  assign arready     = 1;
  assign axi_araddr  = axi_araddr_r;
  assign axi_rready  = 1'b1;
  assign axi_arlen   = 8'b0;
  assign axi_arsize  = 3'b010;
  assign axi_arburst = 2'b01;
  assign axi_arid    = 4'b0;

  reg [2:0] way;
  always @(posedge clock) begin
    if(reset) way <= 0;
    else begin
      if(next_state == MISSA)
        way <= rway;
      else if(next_state == HIT)
        way <= hway;
    end
  end

  reg       invalid;
  reg       access;
  always @(*) begin
    invalid = 0;
    access  = 0;
    if(next_state == MISSA) begin
      if(meta[idx*nway+{29'h0, rway}][23]) invalid = 1;
      else                                 invalid = 0;
    end
    if(next_state == MISSC) begin
      if(counter == 2'b0) access = 1;
      else                access = 0;
    end
    if(next_state == HIT) begin
      access = 1;
    end
  end


  ysyx_23060059_replacer u_replacer(
    .clock        (clock   ),
    .reset        (reset   ),
    .idx          (idx     ),
    .way          (way     ),
    .access       (access  ),
    .invalid      (invalid ),
    .rway_o       (rway    )
  );

endmodule