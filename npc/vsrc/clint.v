`include "defines.v"

module ysyx_23060059_clint(
    input   wire         clock,
    input   wire         reset,
    // xbar <-> clint
    // ar channel
    input    wire  [31:0]  araddr,
    input    wire          arvalid,
    input    wire  [3 :0]  arid,
    input    wire  [7 :0]  arlen,
    input    wire  [2 :0]  arsize,
    input    wire  [1 :0]  arburst,
    output   wire          arready,
    // r channel
    input    wire          rready,
    output   wire          rvalid,
    output   wire  [1 :0]  rresp,
    output   wire  [63:0]  rdata,
    output   wire          rlast,
    output   wire  [3 :0]  rid,
    // aw channel
    output   wire          awready,
    input    wire  [31:0]  awaddr,
    input    wire          awvalid,
    input    wire  [3 :0]  awid,
    input    wire  [7 :0]  awlen,
    input    wire  [2 :0]  awsize,
    input    wire  [1 :0]  awburst,
    // w channel
    output   wire          wready,
    input    wire          wvalid,
    input    wire  [63:0]  wdata,
    input    wire  [7 :0]  wstrb,
    input    wire          wlast,
    // b channel
    output   wire          bvalid,
    output   wire  [1 :0]  bresp,
    output   wire  [3 :0]  bid,
    input    wire          bready
);

  reg [63:0] time_r;
  always @(posedge clock) begin
    if(reset) begin
      time_r <= 0;    
    end else begin
      time_r <= time_r + 1;
    end
  end
  reg         rvalid_r;
  reg [1 :0]  rresp_r;
  reg [63:0]  rdata_r;
  reg         rlast_r;
  reg [3 :0]  rid_r;
  localparam IDLE = 0, R_A = 1, R_B = 2;

  reg [1 :0] state, next_state;
  always @(posedge clock) begin
    if(reset) state <= IDLE;
    else      state <= R_A;
  end

  assign arready = 1;

  always @(*) begin
    case(state)
      IDLE:
        if(arvalid && arready)
          next_state = R_A;
        else
          next_state = IDLE;
      R_A:
        if(rvalid && rready)
          next_state = R_B;
        else
          next_state = R_A;
      default: begin end
    endcase
  end


  always @(posedge clock) begin
    if(reset) begin
      rvalid_r <= 0;
      rresp_r  <= 2'b01;
      rdata_r  <= 0;
      rlast_r  <= 0;
      rid_r    <= 0;
    end else begin
      if(next_state == R_A) 
        rvalid_r <= 1;
      else if(next_state == R_B) begin
        rresp_r <= 2'b0;
        rdata_r <= (araddr == 
        `YSYX_23060059_CLINT_L) ? {32'h0, time_r[31:0]} : {32'h0, time_r[63:32]};
      end else begin
        rvalid_r <= 0;
        rresp_r  <= 2'b01;
      end
    end
  end

  assign rvalid  = rvalid_r;
  assign rresp   = rresp_r;
  assign rdata   = rdata_r;
  assign rlast   = rlast_r;
  assign rid     = rid_r;

  assign awready = 0;
  assign wready  = 0;
  assign bresp   = 2'b01;
  assign bid     = 0;
endmodule