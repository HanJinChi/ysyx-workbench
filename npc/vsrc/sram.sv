module sram(
    input               clk,
    input               rst,
    input               sram_receive_valid,
    input               ren,
    input               wen,
    input    [7 :0]     wmask,
    input    [31:0]     addr,
    input    [31:0]     wdata,
    output   [31:0]     data,
    output              sram_valid
);
  parameter S0 = 0, S1 = 1;
  reg reg_read_valid, reg_next_read_valid; // reg_read_valid代表读是否可用，与写没有关系
  reg sram_state, sram_next_state;
  reg [31:0] reg_data;
  wire read_memory;
  always@(posedge clk) begin
    if(!rst) begin
      sram_state <= sram_next_state;
      reg_read_valid <= reg_next_read_valid;
    end else begin
      sram_state <= S0;
      reg_read_valid <= 0;
    end
  end

  always@(sram_state or ren) begin
    case(sram_state)
      S0: begin
        if(ren == 1) begin
          sram_next_state = S1;
          reg_next_read_valid = 1;
        end
        else begin
          sram_next_state = S0;
        end
      end
      S1: begin
        sram_next_state = S0;
        if(sram_receive_valid)
          reg_next_read_valid = 0;
        else
          reg_next_read_valid = 1;
      end
    endcase
  end

  // always@(posedge clk) begin
  //   if(!rst) begin
  //     if(sram_next_state == S1) 
  //       reg_read_valid <= 1;
  //     else begin
  //       if(ren == 1) reg_read_valid <= 0;
  //     end
  //   end
  // end

  always @(*) begin
    if(reg_read_valid) n_pmem_read(addr, reg_data);    
    else    reg_data = 32'h0;
    if(wen) n_pmem_write(addr, wdata, wmask);
    else    n_pmem_write(addr, wdata, 0);
  end
  assign sram_valid = wen | reg_read_valid;
  assign data = reg_data;

endmodule