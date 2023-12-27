module ifu(
    input    wire          clk,
    input    wire          rst,
    input    wire  [31:0]  pc_next,
    input    wire  [31:0]  pc_next_idu,       // 来自idu的正确的pc_next
    input    wire          receive_valid, // 来自idu的valid
    input    wire          receive_ready,
    input    wire          arready,
    input    wire  [31:0]  rdata,
    input    wire          rvalid,
    input    wire  [1 :0]  rresp,
    output   wire          send_valid,
    output   wire          send_ready,
    output   wire  [31:0]  instruction,
    output   wire  [31:0]  pc_ifu_to_idu,
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
        next_state = READ_A;
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
        if(send_valid && receive_ready) begin
          next_state = READ_A;
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
  reg        send_valid_r;
  reg        send_ready_r;
  reg [31:0] instruction_r;
  reg [31:0] araddr_r;
  reg        set_value;
  reg        arvalid_r;
  reg        rready_r;
  reg        ifu_re_fetch;
  reg [31:0] pc_ifu_to_idu_r;
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
      send_ready_r         <= 0;
      rresp_r              <= 1;
      instruction_r        <= 0;
      send_valid_r         <= 0;
      ifu_re_fetch         <= 0;
      pc_ifu_to_idu_r      <= 0;
      set_value            <= 0;
    end else begin
      if(next_state == READ_A) begin
        if(send_valid_r) 
          send_valid_r     <= 0; // READ_C -> READ_A
        if(ifu_re_fetch)
          ifu_re_fetch     <= 0;
        if(arvalid_r == 0) begin
          arvalid_r <= 1;
          araddr_r  <= pc_next;
        end
        if(set_value) set_value <= 0;
        rresp_r     <= 1;
      end else if(next_state == READ_B) begin
        arvalid_r <= 0;
      end else if(next_state == READ_C) begin
        if(send_valid_r == 0) begin
          if(pc_next_valid) begin
            if(araddr_r == pc_next_idu_c || (araddr_r == addr_beginner)) begin // 相等代表没有跳转，预测正确
              send_valid_r     <= 1;
              pc_ifu_to_idu_r  <= araddr_r;
            end
            else                         // 不相等代表预测错误，重新取值
              ifu_re_fetch     <= 1;
          end
        end
        if(set_value == 0) begin
          set_value      <= 1;
          instruction_r  <= rdata;
          rresp_r        <= rresp;
        end
      end else begin // next_state == IDLE
        if(send_valid_r) send_valid_r <= 0;
      end
    end
  end

  assign send_ready     = send_ready_r;
  assign send_valid     = send_valid_r;
  assign instruction    = instruction_r;
  assign araddr         = araddr_r;
  assign arvalid        = arvalid_r;
  assign rready         = rready_r;
  assign pc_ifu_to_idu  = pc_ifu_to_idu_r;


  reg  wstate, wnext_state;
  parameter WIDLE = 0, WAINTING = 1;
  reg  [31:0]   pc_next_idu_c;
  reg           pc_next_valid;
  always @(posedge clk) begin
    if(rst) wstate <= WIDLE;
    else    wstate <= wnext_state;
  end

  always @(*) begin
    case(wstate)
      WIDLE:
        if(send_valid) 
          wnext_state = WAINTING;
        else
          wnext_state = WIDLE;
      WAINTING:
        if(receive_valid)
          wnext_state = WIDLE;
        else
          wnext_state = WAINTING;
    endcase
  end

  always @(posedge clk) begin
    if(rst) begin
      pc_next_idu_c <= 0;
      pc_next_valid <= 1;
    end else begin
      if(wnext_state == WAINTING) begin
        if(send_valid) pc_next_valid <= 0;
      end else  begin  // WIDLE
        if(receive_valid) begin
          pc_next_idu_c  <= pc_next_idu;
          pc_next_valid  <= 1;
        end
      end
    end
  end

endmodule