
import "DPI-C" function void psram_read(input int raddr, output int rdata);
import "DPI-C" function void psram_write(input int waddr, input int wdata, input byte mask);

module psram(
  input sck,
  input ce_n, // 低电平有效
  inout [3:0] dio
);

  typedef enum [2:0] { idle, cmd_t, addr_t, delay, read, write} state_t;

  reg [2:0] state, next_state;

  always@(posedge sck or posedge ce_n) begin
    if(ce_n) state <= idle;
    else     state <= next_state;
  end

  always @(*) begin
    case(state)
      idle:
        if(ce_n)
          next_state = idle;
        else
          next_state = cmd_t;
      cmd_t:
        if(counter == 5'h8) 
          next_state = addr_t;
        else
          next_state = cmd_t;
      addr_t:
        if(counter == 5'd14) // 8 + 6
          if(cmd == 8'heb)
            next_state = delay;
          else
            next_state = write;
        else 
          next_state = addr_t;
      write:
        if(counter == 5'd22) // 8 + 6 + 8
          next_state = idle;
        else
          next_state = write;
      delay: 
        if(counter == 5'd20) // 8 + 6 + 6
          next_state = read;
        else
          next_state = delay;
      read:
        if(counter == 5'd28)
          next_state = idle;
        else 
          next_state = read;
      default:
        next_state = idle;
    endcase
  end

  wire [3:0] din;
  assign din = dio;
  assign dio = out ? dout : 4'bz;

  wire [4: 0] addr_index;
  assign addr_index = 5 - (counter-8);

  reg  [4 :0] counter;
  reg         out;
  reg  [7 :0] cmd;
  reg  [3 :0] dout;

  reg  [3 :0] adata[5:0];
  wire [23:0] addr = {adata[5], adata[4], adata[3], adata[2], adata[1], adata[0]};

  reg  [3 :0] wdata[7:0];
  wire [31:0] wdata_all = {wdata[1], wdata[0], wdata[3], wdata[2], wdata[5], wdata[4], wdata[7], wdata[6]};
  wire [4: 0] wdata_index = 7 - (counter-14); 

  always @(posedge sck or posedge ce_n) begin
    if(ce_n) begin
      counter  <= 0;
      cmd      <= 0;
      out      <= 0;
      dout     <= 0;
      for (int i = 0; i < 8; i++) begin
        adata[i] <= 0;
      end
    end else begin
      if(next_state == cmd_t) begin
        cmd[7-counter] <= dio[0];
        counter        <= counter + 1;
      end else if(next_state == addr_t) begin
        adata[addr_index[2:0]] <= din;
        counter                <= counter + 1;
      end else if(next_state == delay) begin
        counter <= counter + 1;
      end else if(next_state == read) begin
        out     <= 1;
        dout    <= (counter == 5'd20) ? rdata[7 : 4] :  
                   (counter == 5'd21) ? rdata[3 : 0] :
                   (counter == 5'd22) ? rdata[15:12] :
                   (counter == 5'd23) ? rdata[11: 8] :
                   (counter == 5'd24) ? rdata[23:20] :
                   (counter == 5'd25) ? rdata[19:16] :
                   (counter == 5'd26) ? rdata[31:28] :
                   (counter == 5'd27) ? rdata[27:24] :
                   0;     
        counter <= counter + 1;
      end else if(next_state == write) begin
        wdata[wdata_index[2:0]] <= din;
        counter                 <= counter + 1;
      end else if(next_state == idle) begin
        counter <= 0;
        out     <= 0;
      end
    end
  end

  reg  [31:0]  rdata;
  always @(next_state) begin
    if(next_state == read)  psram_read({8'h0, addr}, rdata);
    else                    rdata = 0;
  end

  reg [7:0] mask;
  always@(*) begin
    if(counter == 5'd16)
      mask = 8'b1;
    else if(counter == 5'd18)
      mask = 8'b11;
    else if(counter == 5'd22)
      mask = 8'b1111;
    else
      mask = 0;
  end

  always @(posedge ce_n) begin
    if(cmd == 8'h38) begin
      psram_write({8'h0, addr}, wdata_all, mask);
    end
  end

endmodule
