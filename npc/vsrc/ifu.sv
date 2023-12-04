module ifu(
    input    wire          clk,
    input    wire          rst,
    input    wire  [31:0]  pc_next,
    input    wire  [31:0]  pc_next_idu,   // 来自idu的正确的pc_next
    input    wire          ifu_receive_valid,
    input    wire          ifu_receive_ready,
    input    wire          arready,
    input    wire  [31:0]  rdata,
    input    wire          rvalid,
    input    wire  [1 :0]  rresp,
    output   wire          ifu_send_valid,
    output   wire          ifu_send_ready,
    output   wire  [31:0]  instruction,
    output   wire  [31:0]  araddr,
    output   wire          arvalid,
    output   wire          rready
);
  // A阶段:  发送需要读的地址到内存
  // B阶段:  接受读的数据
  // C阶段:  将读的数据发送给IDU
  parameter IDLE = 0, READ_A = 1, READ_B = 2, READ_C = 3;
  reg [1:0] state, next_state;

  always @(posedge clk) begin
    if(rst) 
      state <= IDLE;
    else 
      state <= next_state;
  end

  always @(*) begin
    case(state)
      IDLE: begin
        if(ifu_receive_valid)
          next_state = READ_A;
        else 
          next_state = IDLE;
      end
      READ_A: begin
        if(arvalid && arready) 
          next_state = READ_B;
        else
          next_state = READ_A;
      end
      READ_B: begin
        if(rvalid && rready && (rresp == 0)) 
          next_state = READ_C;
        else 
          next_state = READ_B;
      end
      READ_C: begin
        if(ifu_send_valid && ifu_receive_ready) begin
          if(ifu_receive_valid)
            next_state = READ_A;
          else
            next_state = IDLE;
        end
        else begin
          if(ifu_re_fetch)
            next_state = READ_A;
          else
            next_state = READ_C;
        end
      end
      default: begin end
    endcase
  end


  reg [1 :0] rresp_r;
  reg        ifu_send_valid_r;
  reg        ifu_send_ready_r;
  reg [31:0] instruction_r;
  reg [31:0] araddr_r;
  reg        arvalid_r;
  reg        rready_r;
  reg        ifu_re_fetch;
  reg [31:0] addr_beginner; // 最开始取值的addr

  always@(posedge clk) begin
    if(rst) rready_r <= 0;
    else    rready_r <= 1;
  end

  always@(posedge clk) begin
    if(rst) addr_beginner <= 0;
    else if(next_state == READ_A) begin
      if(addr_beginner == 0)
        addr_beginner <= pc_next;
    end
  end
 

  always @(posedge clk) begin
    if(rst) begin
      arvalid_r            <= 0;
      araddr_r             <= 0;
      ifu_send_ready_r     <= 0;
      rresp_r              <= 1;
      instruction_r        <= 0;
      ifu_send_valid_r     <= 0;
      ifu_re_fetch         <= 0;
    end else begin
      if(next_state == READ_A) begin
        if(ifu_send_valid_r) 
          ifu_send_valid_r <= 0; // READ_C -> READ_A
        if(ifu_re_fetch)
          ifu_re_fetch     <= 0;
        if(arvalid_r == 0) begin
          arvalid_r <= 1;
          araddr_r  <= pc_next;
        end
        rresp_r <= 1;
      end else if(next_state == READ_B) begin
        arvalid_r <= 0;
      end else if(next_state == READ_C) begin
        if(ifu_send_valid_r == 0) begin
          if(araddr_r == pc_next_idu || (araddr_r == addr_beginner)) begin // 相等代表没有跳转，预测正确
            instruction_r    <= rdata;
            ifu_send_valid_r <= 1;
            rresp_r          <= rresp;
          end
          else                         // 不相等代表预测错误，重新取值
            ifu_re_fetch     <= 1;
        end
      end else begin // next_state == IDLE
        if(ifu_send_valid_r) ifu_send_valid_r <= 0;
      end
    end
  end

  assign ifu_send_ready = ifu_send_ready_r;
  assign ifu_send_valid = ifu_send_valid_r;
  assign instruction    = instruction_r;
  assign araddr         = araddr_r;
  assign arvalid        = arvalid_r;
  assign rready         = rready_r;


endmodule