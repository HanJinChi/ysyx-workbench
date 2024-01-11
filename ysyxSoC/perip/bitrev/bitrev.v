module bitrev (
  input  sck,
  input  ss, // 低电平有效
  input  mosi,
  output miso
);
  localparam IDLE = 0, WORK = 1;

  reg  [7:0] data_r;
  reg  [2:0] read_p;
  reg  [2:0] write_p;
  reg        full;
  reg        miso_r;
  always @(posedge sck or posedge ss) begin
    if(ss) begin
      data_r  <= 0;
      read_p  <= 0;
      write_p <= 3'b111;
      miso_r  <= 0;
      full    <= 0;
    end else begin
      if(full == 1) begin
        miso_r  <= data_r[write_p];
        write_p <= write_p -1;
      end else begin
        data_r[read_p] <= mosi;
        if(read_p == 3'b111) full <= 1;
        read_p         <= read_p +1;
      end
    end    
  end

  assign miso = ss ? 1 : miso_r;
endmodule
