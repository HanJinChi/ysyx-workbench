module ps2_top_apb(
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

  input         ps2_clk,
  input         ps2_data
);

  typedef enum [0:0] {idle, read} state_t;

  reg state, next_state;

  always @(posedge clock) begin
    if(reset) state <= idle;
    else      state <= next_state;
  end

  always @(*) begin
    case(state)
      idle:
        if(in_psel)
          next_state = read;
        else 
          next_state = idle;
      read:
        next_state = idle;
    endcase
  end

  wire ready;
  wire nextdata_n;
  wire overflow;
  wire [7:0] data;
  ps2_keyboard inst(
    .clk          (clock     ),
    .clrn         (~reset    ),
    .ps2_clk      (ps2_clk   ),
    .ps2_data     (ps2_data  ),
    .data         (data      ),
    .ready        (ready     ),
    .nextdata_n   (nextdata_n),
    .overflow     (overflow  )
  );


  reg [31:0] in_prdata_r;
  reg        in_pready_r;
  reg        nextdata_r;
  always @(posedge clock) begin
    if(reset) begin
      in_prdata_r <= 0;
      in_pready_r <= 0;
      nextdata_r  <= 1;
    end else begin
      if(next_state == read) begin
        if(ready) begin
          nextdata_r <= 0; 
          in_prdata_r <= {24'h0,data}; 
        end else  begin 
          nextdata_r  <= 1; 
          in_prdata_r <= 0; 
        end
        in_pready_r <= 1;
      end else begin// idle
        in_pready_r <= 0;
        nextdata_r  <= 1;
        in_prdata_r <= 0;
      end
    end
  end

  assign in_pready  = in_pready_r;
  assign in_prdata  = in_prdata_r;
  assign nextdata_n = nextdata_r;
endmodule
