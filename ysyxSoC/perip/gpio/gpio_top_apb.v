module gpio_top_apb(
  input         clock,
  input         reset,
  input  [31:0] in_paddr, // 写地址
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output [15:0] gpio_out,
  input  [15:0] gpio_in,
  output [7:0]  gpio_seg_0,
  output [7:0]  gpio_seg_1,
  output [7:0]  gpio_seg_2,
  output [7:0]  gpio_seg_3,
  output [7:0]  gpio_seg_4,
  output [7:0]  gpio_seg_5,
  output [7:0]  gpio_seg_6,
  output [7:0]  gpio_seg_7
);

  wire [15:0] switch;
  assign switch = gpio_in;

  reg [3:0]  gpio_seg[7:0];
  reg [15:0] gpio_led;

  typedef enum [2:0] {idle, write, read} state_t;

  reg [2:0] state, next_state;
  always @(posedge clock) begin
    if(reset) state <= idle;
    else      state <= next_state;
  end

  always @(*) begin
    case(state)
      idle:
        if(in_psel)
          if(in_pwrite)
            next_state = write;
          else
            next_state = read;
        else
          next_state = idle;
      write:
        next_state = idle;
      read:
        next_state = idle;
      default: next_state = idle;
    endcase
  end

  integer idx;
  reg         in_pslverr_r;
  reg  [31:0] in_prdata_r;
  reg         in_pready_r;
  always@(posedge clock) begin
    if(reset) begin
      for(idx = 0; idx < 8; idx=idx+1) begin
        gpio_seg[idx] <= 0;
      end
      gpio_led     <= 0;
      in_pslverr_r <= 0;
      in_prdata_r  <= 0;
      in_pready_r  <= 0;
    end else begin
      if(next_state == write) begin
        in_pready_r <= 1;
        if(in_paddr == `YSYX_23060059_GPIO_LED) begin
          case(in_pstrb)
            4'b0001: gpio_led <= {gpio_led[15:8], in_pwdata[7:0]};
            4'b0010: gpio_led <= {in_pwdata[15:8], gpio_led[7:0]};
            4'b0011: gpio_led <= in_pwdata[15:0];
            4'b1111: gpio_led <= in_pwdata[15:0];
            default: begin end
          endcase
        end else if(in_paddr == `YSYX_23060059_GPIO_SEG) begin
          if(in_pstrb[0]) begin gpio_seg[0]<= in_pwdata[3:0]; gpio_seg[1]<= in_pwdata[7:4]; end
          if(in_pstrb[1]) begin gpio_seg[2]<= in_pwdata[11:8]; gpio_seg[3]<= in_pwdata[15:12]; end
          if(in_pstrb[2]) begin gpio_seg[4]<= in_pwdata[19:16]; gpio_seg[5]<= in_pwdata[23:20]; end
          if(in_pstrb[3]) begin gpio_seg[6]<= in_pwdata[27:24]; gpio_seg[7]<= in_pwdata[31:28]; end
        end else
          in_pslverr_r <= 1;
      end else if(next_state == read) begin
        in_pready_r <= 1;
        if(in_paddr == `YSYX_23060059_GPIO_LED)
          in_prdata_r <= {16'h0, gpio_led};
        else if(in_paddr == `YSYX_23060059_GPIO_SWITCH)
          in_prdata_r <= {16'h0, gpio_in};
        else if(in_paddr == `YSYX_23060059_GPIO_SEG)
          in_prdata_r <= {gpio_seg[7],gpio_seg[6],gpio_seg[5],gpio_seg[4],gpio_seg[3],gpio_seg[2],gpio_seg[1],gpio_seg[0]};
        else
          in_pslverr_r <= 1;
      end else begin // idle
        in_pslverr_r <= 0;
        in_pready_r  <= 0;
      end
    end
  end

  assign in_prdata = in_prdata_r;
  assign in_pready = in_pready_r;

  assign gpio_out = gpio_led;

  bcd7seg seg0 (gpio_seg[0], gpio_seg_0);
  bcd7seg seg1 (gpio_seg[1], gpio_seg_1);
  bcd7seg seg2 (gpio_seg[2], gpio_seg_2);
  bcd7seg seg3 (gpio_seg[3], gpio_seg_3);
  bcd7seg seg4 (gpio_seg[4], gpio_seg_4);
  bcd7seg seg5 (gpio_seg[5], gpio_seg_5);
  bcd7seg seg6 (gpio_seg[6], gpio_seg_6);
  bcd7seg seg7 (gpio_seg[7], gpio_seg_7);


endmodule


module bcd7seg(
  input  [3:0] b,
  output [7:0] h
);

    MuxKey #(16, 4, 8) i0 (h, b, {
        4'b0000, 8'b00000011,
        4'b0001, 8'b10011111,
        4'b0010, 8'b00100101,
        4'b0011, 8'b00001101,
        4'b0100, 8'b10011001,
        4'b0101, 8'b01001001,
        4'b0110, 8'b01000001,
        4'b0111, 8'b00011111,
        4'b1000, 8'b00000001,
        4'b1001, 8'b00001001,
        4'b1010, 8'b00010001,
        4'b1011, 8'b11000001,
        4'b1100, 8'b01100010,
        4'b1101, 8'b10000101,
        4'b1110, 8'b01100001,
        4'b1111, 8'b01110001
    });

endmodule