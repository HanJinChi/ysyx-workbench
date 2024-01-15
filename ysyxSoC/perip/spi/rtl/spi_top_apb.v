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
  .wb_adr_i(wb_adr_i),
  .wb_dat_i(wb_dat_i),
  .wb_dat_o(wb_dat_o),
  .wb_sel_i(wb_sel_i),
  .wb_we_i (wb_we_i),
  .wb_stb_i(wb_stb_i),
  .wb_cyc_i(wb_cyc_i),
  .wb_ack_o(wb_ack_o),
  .wb_err_o(wb_err_o),
  .wb_int_o(spi_irq_out),

  .ss_pad_o(spi_ss),
  .sclk_pad_o(spi_sck),
  .mosi_pad_o(spi_mosi),
  .miso_pad_i(spi_miso)
);

  wire [4 :0] wb_adr_i;
  wire [31:0] wb_dat_i;
  wire [31:0] wb_dat_o;
  wire [3 :0] wb_sel_i;
  wire        wb_we_i;
  wire        wb_stb_i;
  wire        wb_cyc_i;
  wire        wb_ack_o;
  wire        wb_err_o;

  assign wb_adr_i   = (state == IDLE) ? in_paddr[4:0] : in_paddr_r[4:0];
  assign wb_dat_i   = (state == IDLE) ? in_pwdata     : in_pwdata_r;
  assign wb_sel_i   = (state == IDLE) ? in_pstrb      : in_pstrb_r;
  assign wb_we_i    = (state == IDLE) ? in_pwrite     : in_pwrite_r;
  assign wb_stb_i   = (state == IDLE) ? in_psel       : in_psel_r;
  assign wb_cyc_i   = (state == IDLE) ? in_penable    : in_penable_r;
  
  assign in_pready  = (state == IDLE) ? wb_ack_o      : in_pready_r;
  assign in_prdata  = (state == IDLE) ? wb_dat_o      : reverse_flash_data;
  assign in_pslverr = wb_err_o;

  localparam IDLE = 0, WRITE_TX_A = 1, WRITE_TX_B = 2, WRITE_DIVIDER_A = 3, WRITE_DIVIDER_B = 4;
  localparam WRITE_SS_A = 5, WRITE_SS_B = 6, WRITE_CTRL_A = 7, WRITE_CTRL_B = 8, READ_CTRL_A = 9;
  localparam READ_CTRL_B = 10, READ_CTRL_C = 11, READ_RX_A = 12, READ_RX_B = 13, READ_RX_C = 14;
  localparam RESET_CTRL_A = 15, RESET_CTRL_B = 16, SEND_READY = 17;
  localparam SPI_BASE = 32'h10001000, SPI_TX_0 = 0, SPI_DIVIDER = 32'h14, SPI_SS = 32'h18, SPI_CTRL = 32'h10, SPI_RX_1 = 32'h4;

  reg [4:0] state, next_state;

  always @(posedge clock) begin
    if(reset) state <= IDLE;
    else      state <= next_state;
  end

  always @(*) begin
    case(state)
      IDLE:
        if(in_psel && (in_paddr>= flash_addr_start && in_paddr <= flash_addr_end))
          next_state = WRITE_TX_A;
        else 
          next_state = IDLE;
      WRITE_TX_A:
        next_state = WRITE_TX_B;
      WRITE_TX_B:
        if(wb_ack_o)
          next_state = WRITE_DIVIDER_A;
        else
          next_state = WRITE_TX_B;
      WRITE_DIVIDER_A:
        next_state = WRITE_DIVIDER_B;
      WRITE_DIVIDER_B:
        if(wb_ack_o)
          next_state = WRITE_SS_A;
        else
          next_state = WRITE_DIVIDER_B;
      WRITE_SS_A:
        next_state = WRITE_SS_B;
      WRITE_SS_B:
        if(wb_ack_o)
          next_state = WRITE_CTRL_A;
        else
          next_state = WRITE_SS_B;
      WRITE_CTRL_A:
        next_state = WRITE_CTRL_B;
      WRITE_CTRL_B:
        if(wb_ack_o)
          next_state = READ_CTRL_A;
        else
          next_state = WRITE_CTRL_B;
      READ_CTRL_A:
        next_state = READ_CTRL_B;
      READ_CTRL_B:
        if(wb_ack_o)
          next_state = READ_CTRL_C;
        else
          next_state = READ_CTRL_B;
      READ_CTRL_C:
        if(in_prdata_r[8] == 0)
          next_state = READ_RX_A;
        else
          next_state = READ_CTRL_A;
      READ_RX_A:
        next_state = READ_RX_B;
      READ_RX_B:
        if(wb_ack_o)
          next_state = READ_RX_C;
        else 
          next_state = READ_RX_B;
      READ_RX_C:
        next_state = RESET_CTRL_A;
      RESET_CTRL_A:
        next_state = RESET_CTRL_B;
      RESET_CTRL_B:
        if(wb_ack_o)
          next_state = SEND_READY;
        else
          next_state = RESET_CTRL_B;
      SEND_READY:
        next_state = IDLE;
    endcase
  end

  reg [23:0] flash_addr;
  always @(*) begin
    for(int i = 0; i < 24; i++)
      flash_addr[i] = in_paddr[23-i];
  end

  reg [31:0] in_pwdata_r;
  reg [31:0] in_paddr_r;
  reg        in_psel_r;
  reg        in_pwrite_r;
  reg        in_penable_r;
  reg [3 :0] in_pstrb_r;
  reg [31:0] in_prdata_r;

  reg        in_pready_r;
  always @(posedge clock) begin
    if(reset) begin
      in_pwdata_r  <= 0;
      in_paddr_r   <= 0;
      in_psel_r    <= 0;
      in_pwrite_r  <= 0;
      in_penable_r <= 0;
      in_pstrb_r   <= 0;
      in_pready_r  <= 0;
      in_prdata_r  <= 0;
    end else begin
      if(next_state == WRITE_TX_A) begin
        in_pwdata_r  <= {flash_addr, 8'hc0};
        in_paddr_r   <= SPI_BASE + SPI_TX_0;
        in_psel_r    <= 1;
        in_pwrite_r  <= 1;
        in_pstrb_r   <= 4'hf;  
        in_penable_r <= 0;
      end else if(next_state == WRITE_TX_B) begin
        in_penable_r <= 1;
      end else if(next_state == WRITE_DIVIDER_A) begin
        in_pwdata_r  <= 32'h1;
        in_paddr_r   <= SPI_BASE + SPI_DIVIDER;
        in_psel_r    <= 1;
        in_pwrite_r  <= 1;
        in_pstrb_r   <= 4'hf;
        in_penable_r <= 0;  
      end else if(next_state == WRITE_DIVIDER_B) begin
        in_penable_r <= 1;
      end else if(next_state == WRITE_SS_A) begin
        in_pwdata_r <= 32'h01;
        in_paddr_r  <= SPI_BASE + SPI_SS;
        in_psel_r   <= 1;
        in_pwrite_r <= 1;
        in_pstrb_r  <= 4'hf;
        in_penable_r <= 0;  
      end else if(next_state == WRITE_SS_B) begin
        in_penable_r <= 1;
      end else if(next_state == WRITE_CTRL_A) begin
        in_pwdata_r <= 32'h2940;
        in_paddr_r  <= SPI_BASE + SPI_CTRL;
        in_psel_r   <= 1;
        in_pwrite_r <= 1;
        in_pstrb_r  <= 4'hf;  
        in_penable_r <= 0;
      end else if(next_state == WRITE_CTRL_B) begin
        in_penable_r <= 1;
      end else if(next_state == READ_CTRL_A) begin
        in_paddr_r   <= SPI_BASE+SPI_CTRL;
        in_psel_r    <= 1;
        in_pwrite_r  <= 0;
        in_penable_r <= 0;
        in_pstrb_r   <= 4'h0;  
        in_pwdata_r  <= 0;
      end else if(next_state == READ_CTRL_B) begin
        in_penable_r <= 1;
      end else if(next_state == READ_CTRL_C) begin
        in_penable_r <= 0;
        in_prdata_r  <= wb_dat_o;
        in_psel_r    <= 0;     
      end else if(next_state == READ_RX_A) begin
        in_paddr_r   <= SPI_BASE+SPI_RX_1;
        in_psel_r    <= 1;
        in_pwrite_r  <= 0;
        in_penable_r <= 0;
        in_pstrb_r   <= 4'h0;  
        in_pwdata_r  <= 0;
      end else if(next_state == READ_RX_B) begin
        in_penable_r <= 1;
      end else if(next_state == READ_RX_C) begin
        in_prdata_r  <= wb_dat_o;
        in_penable_r <= 0;
        in_psel_r    <= 0;     
      end else if(next_state == RESET_CTRL_A) begin
        in_paddr_r   <= SPI_BASE + SPI_CTRL;
        in_psel_r    <= 1;
        in_pwrite_r  <= 1;
        in_penable_r <= 0;
        in_pstrb_r   <= 4'hf;
        in_pwdata_r  <= 0;
      end else if(next_state == RESET_CTRL_B) begin
        in_penable_r <= 1;
      end else if(next_state == SEND_READY) begin
        in_pready_r  <= 1;
        in_psel_r    <= 0;
        in_pstrb_r   <= 0;
        in_pwrite_r  <= 0;
      end else if(next_state == IDLE) begin
        in_pready_r <= 0;
      end
    end
  end

  reg [31:0] reverse_flash_data;
  always @(*) begin
    for(int i = 0 ; i < 4; i++)
      for(int j = 0; j < 8; j++)
        reverse_flash_data[i*8 + j] = in_prdata_r[i*8 + (7-j)]; 
  end


`endif // FAST_FLASH

endmodule
