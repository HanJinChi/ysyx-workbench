// define this macro to enable fast behavior simulation
// for flash by skipping SPI transfers
// `define FAST_FLASH

module spi_top_apb #(
  parameter flash_addr_start = 32'h30000000,
  parameter flash_addr_end   = 32'h3fffffff,
  parameter spi_ss_num       = 8
) (
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,    // data transfer is required
  input         in_penable, // indicates the second and subsequent cycles of an APB transfer
  input  [2:0]  in_pprot,   // protection type
  input         in_pwrite,  // write: high, read:low
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr, //transfer error

  output                  spi_sck,
  output [spi_ss_num-1:0] spi_ss,
  output                  spi_mosi,
  input                   spi_miso,
  output                  spi_irq_out
);

`ifdef FAST_FLASH

wire [31:0] data;
parameter invalid_cmd = 8'h0;
flash_cmd flash_cmd_i(
  .clock(clock),
  .valid(in_psel && !in_penable),
  .cmd(in_pwrite ? invalid_cmd : 8'h03),
  .addr({8'b0, in_paddr[23:2], 2'b0}),
  .data(data)
);
assign spi_sck    = 1'b0;
assign spi_ss     = 8'b0;
assign spi_mosi   = 1'b1;
assign spi_irq_out= 1'b0;
assign in_pslverr = 1'b0;
assign in_pready  = in_penable && in_psel && !in_pwrite;
assign in_prdata  = data[31:0];

`else

spi_top u0_spi_top (
  .wb_clk_i(clock),
  .wb_rst_i(reset),
  .wb_adr_i(in_paddr[4:0]),
  .wb_dat_i(in_pwdata),
  .wb_dat_o(in_prdata),
  .wb_sel_i(in_pstrb),
  .wb_we_i (in_pwrite),
  .wb_stb_i(in_psel),
  .wb_cyc_i(in_penable),
  .wb_ack_o(in_pready),
  .wb_err_o(in_pslverr),
  .wb_int_o(spi_irq_out),

  .ss_pad_o(spi_ss),
  .sclk_pad_o(spi_sck),
  .mosi_pad_o(spi_mosi),
  .miso_pad_i(spi_miso)
);

  localparam IDLE = 0, WRITE_TX = 1, WRITE_DIVIDER = 2, WRITE_SS = 3, WRITE_CTRL = 4, READ_CTRL = 5;

  reg [2:0] state, next_state;

  always @(posedge clock) begin
    if(reset) state <= IDLE;
    else      state <= next_state;
  end

  always @(*) begin
    case(state)
      IDLE:
        if(in_paddr>= flash_addr_start && in_paddr <= flash_addr_end)
          next_state = WRITE_TX;
        else 
          next_state = IDLE;
      WRITE_TX:
        next_state = WRITE_DIVIDER;
    endcase
  end

  reg [23:0] flash_addr;
  always @(*) begin
    for(int i = 0; i < 24; i++)
      flash_addr[i] = in_paddr[24-i];
  end

  reg [31:0] w_flash_data;
  always @(posedge clock) begin
    if(reset) begin
      w_flash_data <= 0;
    end else begin
      if(next_state == WRITE_TX) begin
        w_flash_data <= {flash_addr, 8'hc0};
        
      end
    end
  end

`endif // FAST_FLASH

endmodule
