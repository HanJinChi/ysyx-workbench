module axi_sram  #(SRAM_READ_CYCLE = 1)(
    input    wire          aclk,
    input    wire          areset,
    input    wire  [31:0]  araddr,  // 要读的地址
    input    wire          arvalid, 
    input    wire          rready,
    output   wire          arready,
    output   reg   [31:0]  data,
    output   reg           rvalid
);

  reg  reg_arready;
  assign arready = reg_arready;

  always @(posedge aclk) begin
    if(areset) begin  //  高电平复位有效
      reg_arready <= 0;  // 默认将arready设为1
    end
    else begin
      reg_arready <= 1;
    end
  end

  reg [31:0] reg_araddr;
  always @(posedge aclk) begin
    if(areset) begin
      reg_araddr <= 0;
    end else begin
      if(arvalid && arready) begin
        reg_araddr <= araddr;
      end
    end 
  end

  parameter S0 = 0, S1 = 1;
  reg sram_read_state, sram_read_next_state;
  always @(posedge aclk) begin
    if(areset) begin
      sram_read_state <= S0;
    end else begin
      sram_read_state <= sram_read_next_state;
    end
  end

  always@(sram_read_state or arvalid or arready) begin
    case(sram_read_state)
    S0: begin
      if(arvalid && arready) begin
        sram_read_next_state = S1;
      end else begin
        sram_read_next_state = S0;
      end
    end
    S1: begin
      sram_read_next_state = S0;
    end
    default: begin end // do nothing
    endcase
  end

  reg [31:0] reg_read_data;
  always@(*) begin
    if(sram_read_state == S1) n_pmem_read(reg_araddr, reg_read_data);
    else                      reg_read_data = 0;
  end

  reg wait_for_read;
  always @(posedge aclk) begin
    if(areset) begin
      rvalid <= 0;
      data  <= 0;
      wait_for_read <= 0;
    end else begin
      if(wait_for_read) begin
        if(rready) begin
          assert(rvalid == 1);
          wait_for_read <= 0;
          rvalid <= 0;
        end
      end else begin
        if(sram_read_state == S1) begin
          assert(rvalid == 0);
          rvalid <= 1;
          data <= reg_read_data;
          if(!rready) begin
            wait_for_read <= 1;
          end
        end else begin
          if(rvalid && rready) begin
            rvalid <= 0;
          end
        end
      end
    end
  end

endmodule