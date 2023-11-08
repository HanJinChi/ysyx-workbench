module ifu(
    input                 clk,
    input                 rst,
    // input                 ifu_ready,
    input      [31:0]     pc_next,
    // output     reg        ifu_valid,
    output     [31:0]     instruction
);
//   reg reg_ifu_state, reg_ifu_next_state; // 0: idle, 1: wait_ready
//   reg ifu_valid;

//   always@(posedge clk) begin
//     if(!rst) begin
//       ifu_state 
//     end
//   end

//   always@(ifu_state or ifu_ready or ifu_valid) begin
//     case(ifu_state)
//       0: begin // idle
//         if(ifu_valid == 1)
//           ifu_state = 1;
//       end
//       1: begin  // wait_ready
//         if(ifu_ready == 1)
//           ifu_state = 0;
//       end
//     endcase
//   end

//   always@(posedge clk) begin
//     if(!rst)
//       if(ifu_state == 0) begin // ifu idle
//         n_pmem_read(pc_next, instruction);
//         ifu_valid <= 1;
//       end 
//   end
    always@(posedge clk) begin
      if(!rst) begin
        n_pmem_read(pc_next, instruction);
      end
    end
    

endmodule