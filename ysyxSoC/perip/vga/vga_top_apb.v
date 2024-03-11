module vga_top_apb(
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output [7:0]  vga_r,
  output [7:0]  vga_g,
  output [7:0]  vga_b,
  output        vga_hsync,
  output        vga_vsync,
  output        vga_valid
);


  typedef enum [1:0] {idle, read_t, write_t} state_t;
  reg [1:0] state, next_state;
  always @(posedge clock) begin
    if(reset) state <= idle;
    else      state <= next_state;
  end

  reg [31:0] vmem[504287:0]; // 640*480
  integer idx;
  always @(posedge clock) begin
    if(reset) begin
      for(idx=0; idx<504287;idx=idx+1)
        vmem[idx] = 32'h0;
    end
  end


  always @(*) begin
    case(state)
      idle:
        if(in_psel)
          if(in_pwrite)
            next_state = write_t;
          else
            next_state = read_t;
        else
          next_state = idle;
      write_t:
        next_state = idle;
      read_t:
        next_state = idle;
      default: begin next_state = idle; end
    endcase
  end

  reg in_pready_r;
  always @(posedge clock) begin
    if(reset) begin
      in_pready_r <= 0;
    end else begin
      if(next_state == write_t) begin
        vmem[in_paddr] <= in_pwdata;
        in_pready_r    <= 1;
      end else if(next_state == read_t) begin
        in_pready_r <= 1;
      end else begin
        in_pready_r <= 0;
      end
    end
  end 

  assign in_pready    = in_pready_r;

  //640x480分辨率下的VGA参数设置
  parameter    h_frontporch = 96;
  parameter    h_active = 144;
  parameter    h_backporch = 784;
  parameter    h_total = 800;

  parameter    v_frontporch = 2;
  parameter    v_active = 35;
  parameter    v_backporch = 515;
  parameter    v_total = 525;

  //像素计数值
  reg  [9:0]    x_cnt;
  reg  [9:0]    y_cnt;
  wire          h_valid;
  wire          v_valid;
  wire [31:0]   vga_data;
  wire [9 :0]   h_addr;
  wire [9 :0]   v_addr;

  always @(posedge clock) //行像素计数
      if (reset)
        x_cnt <= 1;
      else
      begin
        if (x_cnt == h_total)
            x_cnt <= 1;
        else
            x_cnt <= x_cnt + 10'd1;
      end

  always @(posedge clock)  //列像素计数
      if (reset)
        y_cnt <= 1;
      else
      begin
        if (y_cnt == v_total & x_cnt == h_total)
            y_cnt <= 1;
        else if (x_cnt == h_total)
            y_cnt <= y_cnt + 10'd1;
      end
  //生成同步信号
  assign vga_hsync = (x_cnt > h_frontporch);
  assign vga_vsync = (y_cnt > v_frontporch);
  //生成消隐信号
  assign h_valid = (x_cnt > h_active) & (x_cnt <= h_backporch);
  assign v_valid = (y_cnt > v_active) & (y_cnt <= v_backporch);
  assign vga_valid = h_valid & v_valid;
  //计算当前有效像素坐标
  assign h_addr = h_valid ? (x_cnt - 10'd145) : {10{1'b0}};
  assign v_addr = v_valid ? (y_cnt - 10'd36) : {10{1'b0}};

  assign vga_data = vmem[{v_addr[8:0], h_addr}];

  //设置输出的颜色值
  assign vga_r = vga_data[23:16];
  assign vga_g = vga_data[15:8];
  assign vga_b = vga_data[7:0];


endmodule
