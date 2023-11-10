module sram(
    // input               clk,
    // input               rst,
    input               ren,
    input               wen,
    input    [7 :0]     wmask,
    input    [31:0]     addr,
    input    [31:0]     wdata,
    output   [31:0]     data
    // output              sram_valid
);
//   parameter S0 = 0, S1 = 1;
//   reg reg_valid;
//   reg sram_state, sram_next_state;
  reg [31:0] reg_data;
//   always@(posedge clk) begin
//     if(!rst) begin
//       sram_state <= sram_next_state;
//     end else begin
//       sram_state <= S0;
//       reg_valid <= 0;
//     end
//   end

//   always@(sram_state or ren or wen) begin
//     case(sram_state)
//       S0: begin
//         if(ren == 1) 
//           sram_next_state = S1;
//         else
//           sram_next_state = S0;
//       end
//       S1: begin
//         sram_next_state = S0;
//       end
//     endcase
//   end

//   always@(posedge clk) begin
//     if(!rst) begin
//       if(sram_next_state == S1) 
//         reg_valid <= 1;
//       else begin
//         if(wen == 1) reg_valid <= 1;
//         else         reg_valid <= 0;
//       end
//     end
//   end

  always @(*) begin
    if(ren) n_pmem_read(addr, reg_data);    
    else    reg_data = 32'h0;
    if(wen) n_pmem_write(addr, wdata, wmask);
    else    n_pmem_write(addr, wdata, 0);
  end

//   assign sram_valid = reg_valid;
  assign data = reg_data;

endmodule