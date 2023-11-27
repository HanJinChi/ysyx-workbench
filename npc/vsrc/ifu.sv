module ifu(
    input    wire          clk,
    input    wire          rst,
    input    wire  [31:0]  pc_next,
    input    wire          ifu_receive_valid,
    input    wire          ifu_receive_ready,
    input    wire          arready,
    input    wire  [31:0]  rdata,
    input    wire          rvalid,
    input    wire  [1 :0]  rresp,
    output   reg           ifu_send_valid,
    output   reg           ifu_send_ready,
    output   reg   [31:0]  instruction,
    output   reg   [31:0]  araddr,
    output   reg           arvalid,
    output   reg           rready
);
  parameter IDLE = 0, READ = 1;
  reg state, next_state;

  always @(posedge clk) begin
    if(rst) 
      state <= IDLE;
  end


  always @(posedge clk) begin
    if(rst) begin
      state <= 0;
      ifu_send_ready <= 0;
    end
    else begin
      if(state == 0) begin
        if(ifu_receive_valid) begin
          state          <= 1; // working state 
          ifu_send_ready <= 1;
        end else 
          ifu_send_ready <= 0;
      end else begin
        if(ifu_send_valid && ifu_receive_ready) 
          state <= 0;
        else
          ifu_send_ready <= 0;
      end
    end
  end

  wire  enable_read_inst;
  assign enable_read_inst = (state == 0) && ifu_receive_valid;

  reg wait_for_read_address;
  always@(posedge clk) begin
    if(rst) begin
      arvalid <= 0;
      araddr <= 0;
      wait_for_read_address <=0 ;
    end else begin
      if(wait_for_read_address) begin
        if(arready) begin
          assert(arvalid == 1);
          wait_for_read_address <= 0;
          arvalid <= 0;
        end
      end else begin
        if(enable_read_inst) begin
          assert(arvalid == 0);
          arvalid <= 1;
          araddr  <= pc_next;  // 这里直接使用了pc_next是因为直接就能接收到pc_next而不用等待
          if(!arready) wait_for_read_address <= 1;
        end else begin
          if(arvalid && arready) arvalid <= 0;
        end
      end
    end
  end
  always@(posedge clk) begin
    if(rst) rready <= 0;
    else    rready <= 1;
  end
  reg [31:0] reg_data;
  reg [1 :0] reg_rresp;
  always @(posedge clk) begin
    if(rst) begin
      reg_data <= 0;
      reg_rresp <= 1;
    end else begin
      if(rvalid && rready) begin
        reg_data <= rdata;
        reg_rresp <= rresp;
      end else begin
        reg_rresp <= 1;
      end
    end
  end

  reg wait_for_read_instruction;
  always @(posedge clk) begin
    if(rst) begin
      instruction    <= 0;
      ifu_send_valid <= 0;
      wait_for_read_instruction <= 0;
    end else begin
      if(wait_for_read_instruction) begin
        if(ifu_receive_ready) begin
          assert(ifu_send_valid == 1);
          ifu_send_valid <= 0;
          wait_for_read_instruction <= 0;
        end 
      end else begin
          if(rvalid && rready && (rresp == 0)) begin
            ifu_send_valid <= 1;
            instruction    <= rdata;
            if(!ifu_receive_ready) wait_for_read_instruction <= 1;
          end else 
            if(ifu_send_valid && ifu_receive_ready) 
              ifu_send_valid <= 0;
      end
    end
  end 

endmodule