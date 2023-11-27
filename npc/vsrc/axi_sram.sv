module axi_sram  #(SRAM_READ_CYCLE = 1)(
    input    wire          aclk,
    input    wire          areset,
    input    wire  [31:0]  araddr,  // 要读的地址
    input    wire          arvalid, 
    input    wire          rready,
    input    wire  [31:0]  awaddr,  // 要写的地址
    input    wire          awvalid,
    input    wire  [31:0]  wdata,   // 要写的数据
    input    wire  [7 :0]  wstrb,   // 写掩码 
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

  reg  arready_r;
  always @(posedge aclk) begin
    if(areset) begin  //  高电平复位有效
      arready_r <= 0;  
    end
    else begin
      arready_r <= 1;
    end
  end
  assign arready = arready_r;

  parameter IDLE_R = 0, MEM_READ = 1;
  reg sram_read_state, sram_read_next_state;
  always @(posedge aclk) begin
    if(areset) begin
      sram_read_state <= IDLE_R;
    end else begin
      sram_read_state <= sram_read_next_state;
    end
  end

  always@(*) begin
    case(sram_read_state)
    IDLE_R: begin
      if(arvalid && arready) 
        sram_read_next_state = MEM_READ;
      else 
        sram_read_next_state = IDLE_R;
    end
    MEM_READ: begin
      if(rvalid && rready) 
        sram_read_next_state = IDLE_R;
      else
        sram_read_next_state = MEM_READ;
    end
    default: begin end // do nothing
    endcase
  end

  reg [31:0] read_data_r;
  always@(sram_read_next_state) begin
    if(sram_read_next_state == MEM_READ)  n_pmem_read(araddr, read_data_r);
    else                             read_data_r = 0;
  end

  reg         rvalid_r;
  reg  [1 :0] rresp_r;
  reg  [31:0] rdata_r;

  always @(posedge aclk) begin
    if(areset) begin
      rvalid_r        <= 0;
      rdata_r         <= 0;
      rresp_r         <= 1;
    end else begin
      if(sram_read_next_state == MEM_READ) begin
        if(rvalid_r == 0) begin
          rvalid_r  <= 1;
          rdata_r   <= read_data_r;
          rresp_r   <= 0;
        end
      end else begin  // IDLE
        if(rvalid_r == 1) begin
          rvalid_r <= 0;
          rresp_r  <= 1;
        end
      end
    end
  end
  assign  rvalid = rvalid_r;
  assign  rresp  = rresp_r;
  assign  rdata  = rdata_r;


  reg  awready_r;
  always @(posedge aclk) begin
    if(areset) begin  
      awready_r <= 0;  
    end
    else begin
      awready_r <= 1;
    end
  end
  assign awready = awready_r;

  reg  wready_r;
  always @(posedge aclk) begin
    if(areset) begin  
      wready_r <= 0;  
    end
    else begin
      wready_r <= 1;
    end
  end
  assign wready = wready_r;

  parameter IDLE_W = 0, MEM_WRITE = 1;
  reg sram_write_state, sram_write_next_state;
  always @(posedge aclk) begin
    if(areset) begin
      sram_write_state <= IDLE_W;
    end else begin
      sram_write_state <= sram_write_next_state;
    end
  end

  always@(*) begin
    case(sram_write_state)
    IDLE_W: begin
      if(wvalid && wready)
        sram_write_next_state = MEM_WRITE;
      else 
        sram_write_next_state = IDLE_W;
    end
    MEM_WRITE: begin
      if(bvalid && bready)
        sram_write_next_state = IDLE_W;
      else 
        sram_read_next_state  = MEM_WRITE;
    end
    default: begin end // do nothing
    endcase
  end

  wire [31:0]  write_addr; // 真实要写入的地址,这时候分两种情况: 1.地址在数据传输之前已经获得,因此要取awaddr_r 2.数据传输和地址传输同时到达(大部分情况),因此直接取awaddr
  assign write_addr = (awvalid && awready) ? awaddr : awaddr_r;
  always @(sram_write_next_state) begin
    if(sram_write_next_state == MEM_WRITE) begin
      n_pmem_write(write_addr, wdata, wstrb);
    end else begin
      n_pmem_write(write_addr, wdata, 0);
    end
  end

  reg        wait_bresp;
  reg        bvalid_r;
  reg [1 :0] bresp_r;
  reg [31:0] awaddr_r;

  always @(posedge aclk) begin
    if(areset) begin
      bvalid_r   <= 0;
      bresp_r    <= 1;
      wait_bresp <= 0;
      awaddr_r   <= 0;
    end else begin
      if(sram_write_next_state == MEM_WRITE) begin
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