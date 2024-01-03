module axi_uart(
    input    wire          aclock,
    input    wire          areset,
    input    wire  [31:0]  araddr,
    input    wire          arvalid,
    input    wire          rready,
    input    wire  [31:0]  awaddr,
    input    wire          awvalid,
    input    wire  [31:0]  wdata,
    input    wire  [7 :0]  wstrb,
    input    wire          wvalid,   
    input    wire          bready,
    output   wire          arready,
    output   wire  [31:0]  rdata,
    output   wire  [1 :0]  rresp,
    output   wire          rvalid,
    output   wire          awready,
    output   wire          wready,
    output   wire          bvalid,
    output   wire  [1 :0]  bresp
);

  assign arready = 1;
  assign rdata   = 0;
  assign rvalid  = 0;

  always @(posedge aclock) begin
    if(areset) begin

    end else begin
      if(arvalid) begin
        $display("uart receive read request, error!");
        assert(0);
      end
    end
  end


  parameter IDLE = 0, UART_WRITE = 1;
  reg state, next_state;

  always @(posedge aclock) begin
    if(areset) state <= IDLE;
    else       state <= next_state;
  end

  always @(*) begin
    case(state)
    IDLE: begin
      if(wvalid && wready) 
        next_state = UART_WRITE;
      else
        next_state = IDLE;
    end
    UART_WRITE: begin
      if(bvalid && bready)
        next_state = IDLE;
      else
        next_state = UART_WRITE;
    end
    endcase
  end

  always @(next_state) begin
    if(next_state == UART_WRITE) begin
      $write("%c", wdata[7:0]);
    end
  end

  reg  awready_r;
  always @(posedge aclock) begin
    if(areset) begin  
      awready_r <= 0;  
    end
    else begin
      awready_r <= 1;
    end
  end
  assign awready = awready_r;

  reg  wready_r;
  always @(posedge aclock) begin
    if(areset) begin  
      wready_r <= 0;  
    end
    else begin
      wready_r <= 1;
    end
  end
  assign wready = wready_r;


  reg        wait_bresp;
  reg        bvalid_r;
  reg [1 :0] bresp_r;
  reg [31:0] awaddr_r;

  always @(posedge aclock) begin
    if(areset) begin
      bvalid_r   <= 0;
      bresp_r    <= 1;
      wait_bresp <= 0;
      awaddr_r   <= 0;
    end else begin
      if(next_state == UART_WRITE) begin
        if(bvalid_r == 0) begin
          awaddr_r  <= awaddr;
          bvalid_r  <= 1;
          bresp_r   <= 0;
        end
      end else begin  // next_state == IDLE
        if(bvalid_r == 1) begin
          bvalid_r  <= 0;
          bresp_r   <= 0;
        end
      end
    end
  end
  assign bvalid = bvalid_r;
  assign bresp  = bresp_r;

endmodule