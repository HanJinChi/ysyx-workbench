
import "DPI-C" function void sdram_read(input int raddr, output int rdata);
import "DPI-C" function void sdram_write(input int waddr, input int wdata, input byte mask);

module sdram #(
  parameter NUM = 0
)(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [12:0] a,   // 地址
  input [ 1:0] ba,  // 存储体地址
  input [ 1:0] dqm, // 数据掩码
  inout [15:0] dq   
);

  parameter  SDRAM_ADDR_W          = 24;
  parameter  SDRAM_COL_W           = 9;

  localparam SDRAM_BANK_W          = 2;
  localparam SDRAM_DQM_W           = 2;
  localparam SDRAM_BANKS           = 2 ** SDRAM_BANK_W;
  localparam SDRAM_DATA_W          = 16;
  localparam SDRAM_ROW_W           = SDRAM_ADDR_W - SDRAM_COL_W - SDRAM_BANK_W; // 24-9-2 = 13

  localparam Burst_Len             = 4;
  localparam CAS                   = 2;  

  localparam CMD_NOP           = 4'b0111;
  localparam CMD_ACTIVE        = 4'b0011;
  localparam CMD_READ          = 4'b0101;
  localparam CMD_WRITE         = 4'b0100;
  localparam CMD_TERMINATE     = 4'b0110;
  localparam CMD_PRECHARGE     = 4'b0010;
  localparam CMD_REFRESH       = 4'b0001;
  localparam CMD_LOAD_MODE     = 4'b0000;      

  // state
  typedef enum [2:0] { idle, activate_t, read_t, delay_t, send_t, write_t, register_t, terminate_t} state_t;

  reg out;
  wire [15:0] din;
  assign din = dq;
  assign dq = out ? dout : 16'bz;

  wire [3:0] cmd;
  assign cmd = {cs, ras, cas, we};

  reg [2:0] state, next_state;

  wire [24:0] addr;
  wire [SDRAM_BANK_W-1:0] bank;

  assign bank = ba;
  assign addr_col = a;
  assign addr = {active_row[bank],bank,addr_col[SDRAM_COL_W-1:0],1'b0};

  always @(*) begin
    case(state)
      idle:
        case(cmd)
          CMD_LOAD_MODE:
            next_state = register_t;
          CMD_NOP:
            next_state = idle;
          CMD_ACTIVE:
            next_state = activate_t;
          CMD_WRITE:
            next_state = write_t;
          CMD_TERMINATE:
            next_state = terminate_t;
          CMD_READ:
            next_state = read_t;
          default: next_state = idle;
        endcase
      activate_t:
        next_state = idle;
      read_t:
        next_state = send_t;
      send_t:
        if(counter == 1)
          next_state = idle;
        else
          next_state = send_t;
      write_t:
        if(counter == 1)
          next_state = idle;
        else
          next_state = write_t;
      default: next_state = idle;
    endcase
  end

  always @(posedge clk) begin
    if(!cke) state <= idle;
    else     state <= next_state;
  end

  // active_row记录每个存储体激活的行地址
  reg  [SDRAM_ROW_W-1:0] active_row[0:SDRAM_BANKS-1];

  reg  [3:0] counter;
  reg  [31:0] rdata;
  wire [SDRAM_ROW_W-1:0] addr_col;
  reg  [15:0] dout;
  integer idx;
  always @(posedge clk) begin
    if(!cke) begin
      out             <= 0;
      counter         <= 0;
      dout            <= 0;
      for (idx=0;idx<SDRAM_BANKS;idx=idx+1)
          active_row[idx] <= {SDRAM_ROW_W{1'b0}};
    end else begin
      if(next_state == register_t)begin

      end else if(next_state == activate_t)begin
        active_row[ba] <= a; // 行地址
      end else if(next_state == read_t) begin
        sdram_read({7'h0,addr}, rdata);
      end else if(next_state == send_t) begin
        out    <= 1;
        dout   <= (NUM == 0) ? rdata[15:0 ]  :
                  (NUM == 1) ? rdata[31:16]  :
                  0;
        counter <= counter + 1;
      end else if(next_state == write_t) begin
        if(NUM == 0)
          sdram_write({7'h0,addr}, {16'b0, din}, {6'h0, ~dqm});
        else
          sdram_write({7'h0,addr}, {din, 16'b0}, {4'h0, ~dqm, 2'h0});
        counter <= counter + 1;
      end else begin // idle
        counter <= 0;
        out     <= 0; 
      end
    end
  end

endmodule
