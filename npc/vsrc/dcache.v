`include "defines.v"

// 4KB data array
// nset       : 32
// nway       : 8
// block size : 128bit, 16Byte
// meta size  : 25bit, 23bit tag + 1 bit valid + 1bit dirty 

module ysyx_23060059_dcache(
  input    wire           clock,
  input    wire           reset,
  // dcache <-> lsu, ar channel
  input    wire  [31 :0]  req_addr,
  input    wire           arvalid,
  output   wire           arready,
  // dcache <-> lsu, r channel
  input    wire           rready,
  output   wire           rvalid,
  output   wire  [63 :0]  data_o,
  // dcache <-> lsu, aw channel
  input    wire           awvalid,
  output   wire           awready,
  // dcache <-> lsu, w channel
  input    wire           wvalid,
  input    wire  [63 :0]  lwdata,
  input    wire  [7  :0]  wstrb,
  output   wire           wready,
  // dcache <-> lsu, b channel
  input    wire           bready,
  output   wire           bvalid,
  // dcache <-> axi, ar channel
  output   wire  [31 :0]  axi_araddr,
  output   wire  [3  :0]  axi_arid,
  output   wire  [7  :0]  axi_arlen,
  output   wire  [2  :0]  axi_arsize,
  output   wire  [1  :0]  axi_arburst,
  output   wire           axi_arvalid,
  input    wire           axi_arready,
  // dcache <-> axi, r channel
  input    wire  [63 :0]  axi_rdata,
  input    wire           axi_rvalid,
  input    wire  [1  :0]  axi_rresp,
  input    wire           axi_rlast,
  input    wire  [3 :0]   axi_rid,
  output   wire           axi_rready,
  // dcache <-> axi, aw channel
  input    wire           axi_awready,
  output   wire  [31 :0]  axi_awaddr,
  output   wire           axi_awvalid,
  output   wire  [3  :0]  axi_awid,
  output   wire  [7  :0]  axi_awlen,
  output   wire  [2  :0]  axi_awsize,
  output   wire  [1  :0]  axi_awburst,
  // dcache <-> axi, w channel
  input    wire           axi_wready,
  output   wire           axi_wvalid,
  output   wire  [63 :0]  axi_wdata,
  output   wire  [7  :0]  axi_wstrb,
  output   wire           axi_wlast,
  // dcache <-> axi, b channel
  input    wire           axi_bvalid,
  input    wire  [1  :0]  axi_bresp,
  input    wire  [3  :0]  axi_bid,
  output   wire           axi_bready
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

  wire  [24 :0]  meta  [255:0];  // meta array
  wire  [24 :0]  wmeta [255:0];
  wire  [127:0]  data  [255:0];  // data array
  wire  [127:0]  wdata [255:0];

  genvar i;
  generate
    for(i = 0; i < 256; i = i+1) begin
      Reg #(25,25'b0) u_reg_meta(clock, reset, wmeta[i], meta[i], wen);
    end
  endgenerate

  generate
    for(i = 0; i < 256; i = i+1) begin
      assign wmeta[i] = (wen == 1) ? ( ((idx*nway+{29'h0, way}) == i) ? write_meta : meta[i]) : meta[i];
    end
  endgenerate

  generate
    for(i = 0; i < 256; i = i+1) begin
      Reg #(128,128'b0) u_reg_data(clock, reset, wdata[i], data[i], wen);
    end
  endgenerate

  generate
    for(i = 0; i < 256; i = i+1) begin
      assign wdata[i] = (wen == 1) ? ( ((idx*nway+{29'h0, way}) == i) ? concat_write_data : data[i]) : data[i];
    end
  endgenerate


  reg  [4  :0]  idx;
  reg           hit;
  reg  [2  :0]  hway;
  wire [24 :0]  hit_meta;
  wire [127:0]  hit_data;
  reg  [24 :0]  write_meta;
  reg  [7  :0]  write_data[15:0];
  wire [127:0]  mux_write_data;
  reg  [127:0]  concat_write_data;
  reg  [63 :0]  rdata;
  integer w;
  always @(*) begin
    idx  = req_addr[8:4];
    hit  = 0;
    hway = 0;
    for(w = 0; w < nway; w=w+1) begin
      if(meta[idx*nway+w][23] && meta[idx*nway+w][22:0] == req_addr[31:9]) begin
        hit  = 1'b1;
        hway = w[2:0];
      end
    end
  end

  assign hit_meta       = meta[idx*nway+{29'h0, hway}];
  assign hit_data       = data[idx*nway+{29'h0, hway}];
  assign mux_write_data = (state == IDLE) ? hit_data : data_buffer; 

  always @(*) begin
    if(state == IDLE) write_meta = {1'b1, hit_meta[23:0]};
    else              write_meta = {1'b0, 1'b1, align_addr[31:9]};
  end

  integer j;
  always @(*) begin
    if(req_addr[3]) begin
      for(j = 0; j < 8; j = j+1)
        write_data[j] = mux_write_data[8*(j+1)-1 -: 8];
      for(j = 8; j < 16; j = j+1)
        write_data[j] = is_write ? (wstrb[j-8] ? lwdata[(j-7)*8-1 -: 8] : mux_write_data[8*(j-7)-1 -:8]) : mux_write_data[8*(j+1)-1 -:8];
    end else begin
      for(j = 0; j < 8; j = j+1)
        write_data[j] = is_write ? (wstrb[j] ? lwdata[(j+1)*8-1 -: 8] : mux_write_data[8*(j+1)-1 -: 8]) : mux_write_data[8*(j+1)-1 -: 8];
      for(j = 8; j < 16; j = j+1)
        write_data[j] = mux_write_data[8*(j+1)-1 -: 8];
    end
  end

  always @(*) begin
    integer i;
    for(i = 0; i < 16; i = i+1)
      concat_write_data[8*(i+1)-1 -: 8] = write_data[i];
  end

  always @(*) begin
    rdata = 64'b0;
    if(next_state == HIT)
      if(state == MISSC)
        case(req_addr[3:0])
          4'b0000, 4'b0001, 4'b0010, 4'b0011:
            rdata = {32'h0, data_buffer[31:0]};
          4'b0100, 4'b0101, 4'b0110, 4'b0111:
            rdata = {32'h0, data_buffer[63:32]};
          4'b1000, 4'b1001, 4'b1010, 4'b1011:
            rdata = {data_buffer[95:64], 32'h0};
          4'b1100, 4'b1101, 4'b1110, 4'b1111:
            rdata = {data_buffer[127:96], 32'h0};
          default: rdata = 64'b0;
        endcase
      else
        case(req_addr[3:0])
          4'b0000, 4'b0001, 4'b0010, 4'b0011:
            rdata = {32'h0, hit_data[31:0]};
          4'b0100, 4'b0101, 4'b0110, 4'b0111:
            rdata = {32'h0, hit_data[63:32]};
          4'b1000, 4'b1001, 4'b1010, 4'b1011:
            rdata = {32'h0, hit_data[95:64]};
          4'b1100, 4'b1101, 4'b1110, 4'b1111:
            rdata = {32'h0, hit_data[127:96]};
          default: rdata = 64'b0;
        endcase
  end


  reg  [2:0] state, next_state;
  typedef enum [2:0] {IDLE, WRITEA, WRITEB, MISSA, MISSB, MISSC, HIT} state_t;

  always @(posedge clock) begin
    if(reset) state <= IDLE;
    else      state <= next_state;
  end

  always @(*) begin
    case(state)
      IDLE:
        if(io)
          if(arvalid)   next_state = MISSA;
          else
            if(awvalid) next_state = WRITEA;
            else        next_state = IDLE;
        else 
          if(arvalid || awvalid)
            if(hit)
              next_state = HIT;
            else
              if(writeback)
                next_state = WRITEA;
              else
                next_state = MISSA;
          else
            next_state = IDLE;
      WRITEA:
        if(axi_awvalid && axi_awready)
          next_state = WRITEB;
        else
          next_state = WRITEA;
      WRITEB:
        if(axi_bvalid && axi_bready)
          if(axi_bresp == 0)
            if(io)
              next_state = IDLE;
            else
              if(wcounter == 2'b11)
                next_state = WRITEA;
              else
                next_state = MISSA;
          else begin
            next_state = WRITEB;
            $display("bresp != 0, error!\n");
            assert(0);
          end
        else
          next_state = WRITEB;
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
        if(io)
          next_state = HIT;
        else
          if(counter == 2'b0)
            next_state = HIT;
          else
            next_state = MISSA;
      HIT:
        if((rvalid && rready) || (bvalid && bready))
          next_state = IDLE;
        else
          next_state = HIT;
      default: next_state = IDLE;
    endcase
  end

  wire          io;
  wire [2  :0]  rway;
  wire [31 :0]  align_addr;
  wire [31 :0]  writeback_addr;
  reg           axi_arvalid_r;
  reg  [31 :0]  axi_araddr_r;
  reg           rvalid_r;
  reg           bvalid_r;
  reg  [1  :0]  counter;
  reg  [1  :0]  wcounter;
  reg           wen;
  reg  [127:0]  data_buffer;
  reg  [63 :0]  data_r;

  reg           axi_awvalid_r;
  reg  [31 :0]  axi_awaddr_r;
  reg           axi_wvalid_r;
  reg  [63 :0]  axi_wdata_r;
  reg           axi_wstrb_r;

  assign align_addr     = {req_addr[31:4], 4'h0};
  assign writeback_addr = {meta[idx*nway+{29'h0, rway}][22:0], idx, 4'h0};
  assign io             = (req_addr >= `YSYX_23060059_UART_L  && req_addr <= `YSYX_23060059_UART_H  ) ||
                          (req_addr >= `YSYX_23060059_CLINT_L && req_addr <= `YSYX_23060059_CLINT_H ) || 
                          (req_addr >= `YSYX_23060059_GPIO_L  && req_addr <= `YSYX_23060059_GPIO_H  ) || 
                          (req_addr >= `YSYX_23060059_KEY_L   && req_addr <= `YSYX_23060059_KEY_H   ) || 
                          (req_addr >= `YSYX_23060059_VGA_L   && req_addr <= `YSYX_23060059_VGA_H   ) ;

  reg  [31 :0]  awdata;
  always @(*) begin
    case(wcounter)
      2'b00:
        awdata = data[idx*nway+{29'h0, rway}][31:0];
      2'b01:
        awdata = data[idx*nway+{29'h0, rway}][63:32];
      2'b10:
        awdata = data[idx*nway+{29'h0, rway}][95:64];
      2'b11:
        awdata = data[idx*nway+{29'h0, rway}][127:96];
    endcase
  end

  reg is_write;
  always @(posedge clock) begin
    if(reset) is_write <= 0;
    else begin
      if(state == IDLE && next_state != IDLE) 
        is_write <= awvalid ? 1'b1 : 1'b0;
    end
  end


  always @(posedge clock) begin
    if(reset)
      wcounter <= 0;
    else begin
      if(next_state == WRITEB)
        if(axi_awvalid && axi_awready)
          wcounter <= wcounter + 1;
      if(next_state == IDLE)
        wcounter <= 0;
    end
  end


  always @(posedge clock) begin
    if(reset)
      axi_awvalid_r <= 0;
    else begin
      if(next_state == WRITEA)
        axi_awvalid_r <= 1;
      else
        axi_awvalid_r <= 0;
    end
  end

  always @(posedge clock) begin
    if(reset)
      axi_awaddr_r <= 0;
    else begin
      if(next_state == WRITEA)
        axi_awaddr_r <= io ? req_addr : (writeback_addr + {28'h0, wcounter, 2'h0});
    end
  end

  always @(posedge clock) begin
    if(reset)
      axi_wvalid_r <= 0;
    else begin
      if(next_state == WRITEA)
        axi_wvalid_r <= 1;
      else
        axi_wvalid_r <= 0;
    end
  end

  always @(posedge clock) begin
    if(reset)
      axi_wdata_r <= 0;
    else begin
      if(next_state == WRITEA)
        axi_wdata_r <= io ? lwdata : {32'h0, awdata};
      else
        axi_wdata_r <= 0;
    end
  end

  reg [7 :0] axi_align_wstrb_r;
  reg [63:0] axi_align_wdata_r;

  always @(*) begin
    if(io) begin
      axi_align_wdata_r = axi_wdata_r;
      axi_align_wstrb_r = wstrb;
    end 
    else begin
      axi_align_wdata_r  = axi_wdata_r << (axi_awaddr[2]*32);
      axi_align_wstrb_r  = 8'hf << (axi_awaddr[2]*4);
    end
  end

  // 8字节对齐
  assign axi_wstrb     = axi_align_wstrb_r;
  assign axi_wdata     = axi_align_wdata_r;
  assign axi_awvalid   = axi_awvalid_r;
  assign axi_wvalid    = axi_wvalid_r;
  assign axi_awaddr    = axi_awaddr_r;


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
    else begin
      if(io)
        wen <= 1'b0;
      else begin
        if(next_state == HIT) begin
          if(state == IDLE) wen <= awvalid ? 1'b1 : 1'b0;
          else              wen <= 1'b1;
        end
        else
          wen <= 1'b0;
      end
    end
  end

  always @(posedge clock) begin
    if(reset) counter <= 0;
    else begin
      if(next_state == MISSB)
        if(!io && axi_arvalid && axi_arready) 
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
      if(next_state == HIT) begin
        if(state == IDLE) begin
          if(arvalid)
            rvalid_r <= 1;
        end
        else
          if(!is_write)
            rvalid_r <= 1;
      end
      else
        rvalid_r <= 0;
    end
  end

  always @(posedge clock) begin
    if(reset) bvalid_r <= 0;
    else begin
      if(next_state == HIT) begin
        if(state == IDLE) begin 
          if(awvalid)
            bvalid_r <= 1;
        end
        else
          if(is_write)
            bvalid_r <= 1;
      end
      else
        bvalid_r <= 0;
    end
  end

  always @(posedge clock) begin
    if(reset) data_r <= 0;
    else begin
      if(next_state == HIT)
        data_r <= io ? axi_rdata : rdata;
    end
  end

  assign data_o      = data_r;
  assign axi_arvalid = axi_arvalid_r;
  assign rvalid      = rvalid_r;
  assign bvalid      = bvalid_r;
  assign arready     = 1;
  assign awready     = 1;
  assign axi_araddr  = axi_araddr_r;
  assign axi_rready  = 1'b1;
  assign axi_arlen   = 8'b0;
  assign axi_arsize  = 3'b010;
  assign axi_arburst = 2'b01;
  assign axi_arid    = 4'b0;
  assign axi_bready  = 1'b1;

  reg [2:0] way;
  always @(posedge clock) begin
    if(reset) way <= 0;
    else begin
      if(next_state == MISSA && counter == 2'b00)
        way <= rway;
    end
  end

  reg       invalid;
  reg       access;
  always @(*) begin
    invalid = 0;
    access  = 0;
    if(!io) begin
      if(next_state == MISSA && counter == 2'b11) begin
        if(meta[idx*nway+{29'h0, rway}][23]) invalid = 1;
        else                                 invalid = 0;
      end
      if(next_state == HIT) begin
        access = 1;
      end
    end
  end

  reg writeback;
  always @(*) begin
    writeback = 0;
    if(meta[idx*nway+{29'h0, rway}][24]) writeback = 1;
    else                                 writeback = 0;
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