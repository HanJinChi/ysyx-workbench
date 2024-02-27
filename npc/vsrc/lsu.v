// 支持非对齐读不支持非对齐写

module ysyx_23060059_lsu (
  input    wire          clock,
  input    wire          reset,
  input    wire          receive_valid,
  input    wire          ren_i,
  input    wire          wen_i,
  input    wire          m_signed_i,
  input    wire  [7 :0]  wmask_i,
  input    wire  [31:0]  rmask_i,
  input    wire  [31:0]  result_i,
  input    wire  [31:0]  pc_i,
  input    wire  [31:0]  pc_next_i,
  input    wire  [31:0]  instruction_i,
  input    wire  [31:0]  src2_i,
  input    wire  [31:0]  rsb_i,
  input    wire  [1 :0]  wdOp_i,
  input    wire          csrwdOp_i,
  input    wire  [4 :0]  rd_i,
  input    wire  [1 :0]  csr_rd_i,
  input    wire          reg_en_i,
  input    wire          csreg_en_i,
  input    wire          ecall_i,
  input    wire          ebreak_i,
  output   wire          send_valid,
  output   wire          send_ready,
  output   wire  [31:0]  wd_o,
  output   wire  [31:0]  csr_wd_o,
  output   wire  [4 :0]  rd_o,
  output   wire  [4 :0]  rd_lsu_to_idu,
  output   wire  [31:0]  pc_o,
  output   wire  [31:0]  instruction_o,
  output   wire  [31:0]  pc_next_o,
  output   wire  [1 :0]  csr_rd_o,
  output   wire  [1 :0]  csr_rd_lsu_to_idu,
  output   wire          reg_en_o,
  output   wire          csreg_en_o,
  output   wire          ecall_o,
  output   wire          ebreak_o,
  output   wire          skip_d_o,
  // lsu <-> axi, ar channel
  input    wire          arready,
  output   wire  [31:0]  araddr,
  output   wire          arvalid,
  output   wire  [3 :0]  arid,
  output   wire  [7 :0]  arlen,
  output   wire  [2 :0]  arsize,
  output   wire  [1 :0]  arburst,
  // lsu <-> axi, r channel
  input    wire          rvalid,
  input    wire  [1 :0]  rresp,
  input    wire  [63:0]  rdata,
  input    wire          rlast,
  input    wire  [3 :0]  rid,
  output   wire          rready,
  // lsu <-> axi, aw channel
  input    wire          awready,
  output   wire  [31:0]  awaddr,
  output   wire          awvalid,
  output   wire  [3 :0]  awid,
  output   wire  [7 :0]  awlen,
  output   wire  [2 :0]  awsize,
  output   wire  [1 :0]  awburst,
  // lsu <-> axi, w channel
  input    wire          wready,
  output   wire          wvalid,
  output   wire  [63:0]  wdata,
  output   wire  [7 :0]  wstrb,
  output   wire          wlast,
  // lsu <-> axi, b channel
  input    wire          bvalid,
  input    wire  [1 :0]  bresp,
  input    wire  [3 :0]  bid,
  output   wire          bready,

  output   wire          lsu_state
);
  // r
  assign arid    = 4'b0;
  assign arlen   = 8'b0;
  assign arsize  = 3'b010; // 4 bytes(32bit) per transfer
  assign arburst = 2'b01;  // INCR
  // w
  assign awid    = awid_r;
  assign awlen   = 8'b0;
  assign awsize  = 3'b010;
  assign awburst = 2'b01;


  reg [2:0]  state, next_state;
  localparam  IDLE = 0, MEM_READ_A = 1, MEM_READ_B = 2, MEM_READ_C = 3, MEM_WRITE_A = 4, MEM_WRITE_B = 5, MEM_WRITE_C = 6, MEM_NULL = 7;

  always @(posedge clock) begin
    if(reset) state <= IDLE;
    else      state <= next_state;
  end

  always @(*) begin
    case(state)
      IDLE:
        if(receive_valid || buffer) begin
          if(ren_v) 
            next_state = MEM_READ_A;
          else if(wen_v)
            next_state = MEM_WRITE_A;
          else
            next_state = MEM_NULL;
        end else
          next_state = IDLE;
      MEM_READ_A:
        if(arvalid && arready) 
          next_state = MEM_READ_B;
        else 
          next_state = MEM_READ_A;
      MEM_READ_B:
        if(rvalid && rready)
          if(rresp == 0)
            next_state = MEM_READ_C;
          else begin
            $display("rresp !=0, error !");
            assert(0);
          end
        else
          next_state = MEM_READ_B;
      MEM_READ_C:
        if(second_read)
          next_state = MEM_READ_A;
        else
          if(send_valid)
            next_state = IDLE;
          else
            next_state = MEM_READ_C;
      MEM_WRITE_A:
        if(awvalid && awready)
          next_state = MEM_WRITE_B;
        else
          next_state = MEM_WRITE_A;
      MEM_WRITE_B:
        if(bvalid && bready)
          if(bresp == 0)
            next_state = MEM_WRITE_C;
          else begin
            $display("bresp !=0, error!\n");
            assert(0);
          end
        else
          next_state = MEM_WRITE_B;
      MEM_WRITE_C:
        if(send_valid)
          next_state = IDLE;
        else
          next_state = MEM_WRITE_C;
      MEM_NULL:
        if(send_valid)
          next_state = IDLE;
        else
          next_state = MEM_NULL;
    endcase
  end


  reg buffer_en;
  reg buffer;

  always @(posedge clock) begin
    if(reset) begin
      buffer <= 0;
    end else begin
      if(buffer == 0) begin
        if(receive_valid && (state != IDLE)) begin
          buffer  <= 1;
        end
      end
    end
  end

  always @(*) begin
    if(buffer == 0 && receive_valid && (state != IDLE)) 
      buffer_en = 1;
    else 
      buffer_en = 0; 
  end


  wire  [31:0] exu_result_b;
  wire  [31:0] pc_b;
  wire  [31:0] pc_next_b;
  wire  [31:0] instruction_b;
  wire         m_signed_b;
  wire  [31:0] rmask_b;
  wire         ecall_b;
  wire         ebreak_b;
  wire  [31:0] src2_b;
  wire  [31:0] rsb_b;
  wire  [1 :0] wdOp_b;
  wire         csrwdOp_b;
  wire  [4 :0] rd_b;
  wire  [1 :0] csr_rd_b;
  wire         reg_en_b;
  wire         csreg_en_b;
  wire  [7 :0] wmask_b;   
  wire         ren_b;
  wire         wen_b;

  Reg #(32, 32'h0) regd0 (clock, reset, result_i,      exu_result_b,  buffer_en);
  Reg #(32, 32'h0) regd1 (clock, reset, pc_i,          pc_b,          buffer_en);
  Reg #(32, 32'h0) regd2 (clock, reset, pc_next_i,     pc_next_b,     buffer_en);
  Reg #(32, 32'h0) regd3 (clock, reset, instruction_i, instruction_b, buffer_en);
  Reg #(1,  1 'h0) regd4 (clock, reset, m_signed_i,    m_signed_b,    buffer_en);
  Reg #(32, 32'h0) regd5 (clock, reset, rmask_i,       rmask_b,       buffer_en);
  Reg #(1,  1 'h0) regd6 (clock, reset, ecall_i,       ecall_b,       buffer_en);
  Reg #(1,  1 'h0) regd7 (clock, reset, ebreak_i,      ebreak_b,      buffer_en);
  Reg #(32, 32'h0) regd8 (clock, reset, src2_i,        src2_b,        buffer_en);
  Reg #(32, 32'h0) regd9 (clock, reset, rsb_i,         rsb_b,         buffer_en);
  Reg #(2,  2 'h0) regd10(clock, reset, wdOp_i,        wdOp_b,        buffer_en);
  Reg #(1,  1 'h0) regd11(clock, reset, csrwdOp_i,     csrwdOp_b,     buffer_en);
  Reg #(5,  5 'h0) regd12(clock, reset, rd_i,          rd_b,          buffer_en);
  Reg #(2,  2 'h0) regd13(clock, reset, csr_rd_i,      csr_rd_b,      buffer_en);
  Reg #(1,  1 'h0) regd14(clock, reset, reg_en_i,      reg_en_b,      buffer_en);
  Reg #(1,  1 'h0) regd15(clock, reset, csreg_en_i,    csreg_en_b,    buffer_en);
  Reg #(8,  8 'h0) regd16(clock, reset, wmask_i,       wmask_b,       buffer_en);
  Reg #(1,  1 'h0) regd30(clock, reset, ren_i,         ren_b,         buffer_en);
  Reg #(1,  1 'h0) regd31(clock, reset, wen_i,         wen_b,         buffer_en);


  wire  [31:0]  exu_result;
  wire  [31:0]  src2;
  wire  [1 :0]  wdOp;
  wire          csrwdOp;
  wire          ren;
  wire          wen;

  reg           m_signed;
  reg  [31:0]   rmask;
  reg  [63:0]   rdata_r;

  reg          send_valid_r;
  reg  [31:0]  araddr_r;
  reg          arvalid_r;
  reg          rready_r;
  reg  [31:0]  awaddr_r;
  reg          awvalid_r;
  reg          wvalid_r;
  reg          bready_r;
  reg  [63:0]  wdata_r;
  reg  [7 :0]  wstrb_r;
  reg  [3 :0]  awid_r;  
  reg  [31:0]  pc_r;
  reg          second_read;  

  always @(posedge clock) begin
    if(reset) begin
      send_valid_r   <= 0;
      m_signed           <= 0;
      rmask              <= 0;
      araddr_r           <= 0;
      arvalid_r          <= 0;
      wdata_r            <= 0;
      wstrb_r            <= 0;
      awaddr_r           <= 0;
      awvalid_r          <= 0;
      wvalid_r           <= 0;
      awid_r             <= 0;
      pc_r               <= 0;
      second_read        <= 0;
    end else begin
      if(next_state == IDLE) begin
        if(send_valid_r) begin
          send_valid_r <= 0;
        end
      end else begin
        if(next_state == MEM_READ_A) begin
          if(second_read) begin
            arvalid_r    <= 1;
            araddr_r     <= exu_result_v + 4;
          end else begin
            if(arvalid_r == 0) begin
              arvalid_r            <= 1;
              araddr_r             <= exu_result_v;
              m_signed             <= m_signed_v;
              rmask                <= rmask_v;
              pc_r                 <= pc_v;
            end
          end
        end else if(next_state == MEM_READ_B) begin
          arvalid_r            <= 0;
        end else if(next_state == MEM_READ_C) begin
          if(send_valid_r == 0) begin
            if(unalign) begin
              if(second_read) begin
                send_valid_r <= 1;
                rdata_r      <= rdata;
                second_read  <= 0;
                if(buffer)
                  buffer             <= 0; 
              end else 
                second_read  <= 1;
                rdata_r      <= rdata;
            end else begin
              send_valid_r <= 1;
              rdata_r      <= rdata;
              if(buffer)
                buffer             <= 0;
            end
          end
        end else if(next_state == MEM_WRITE_A) begin
          if(awvalid_r == 0) begin
            awvalid_r           <= 1;
            wvalid_r            <= 1;
            awid_r              <= awid_r + 1;
            awaddr_r            <= exu_result_v;
            wdata_r             <= align_wdata_v;
            wstrb_r             <= align_wstrb_v;
            if(buffer)
              buffer            <= 0;
            end
        end else if(next_state == MEM_WRITE_B) begin
          awvalid_r <= 0;
          wvalid_r  <= 0; 
        end else if(next_state == MEM_WRITE_C) begin  
          if(send_valid_r == 0) begin
            send_valid_r   <= 1;
          end
        end else begin // MEM_NULL 
          if(send_valid_r == 0) begin
            send_valid_r <= 1;
            if(buffer)
              buffer     <= 0;
          end
        end
      end
    end
  end

  assign send_valid   = send_valid_r;
  assign send_ready   = !buffer;

  reg lsu_to_wbu_en;
  always @(*) begin
    if((next_state == MEM_NULL || next_state == MEM_READ_A || next_state == MEM_WRITE_A) && send_valid_r == 0) begin
      lsu_to_wbu_en = 1;
    end else
      lsu_to_wbu_en = 0;
  end

  reg unalign;

  always @(*) begin
    unalign = 0;
    if(rmask_v == 32'h0000ffff) begin
      if(exu_result_v[1:0] == 2'b11)
        unalign = 1;
    end else if(rmask_v == 32'hffffffff) begin
      if(exu_result_v[1:0] != 2'h0)
        unalign = 1;
    end
  end

  Reg #(32, 32'h0) regd17 (clock, reset, pc_v,          pc_o,          lsu_to_wbu_en);
  Reg #(32, 32'h0) regd18 (clock, reset, pc_next_v,     pc_next_o,     lsu_to_wbu_en);
  Reg #(32, 32'h0) regd19 (clock, reset, instruction_v, instruction_o, lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd20 (clock, reset, ecall_v,       ecall_o,       lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd21 (clock, reset, ebreak_v,      ebreak_o,      lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd22 (clock, reset, reg_en_v,      reg_en_o,      lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd23 (clock, reset, csreg_en_v,    csreg_en_o,    lsu_to_wbu_en);
  Reg #(5,  5 'h0) regd27 (clock, reset, rd_v,          rd_o,          lsu_to_wbu_en);
  Reg #(2,  2 'h0) regd28 (clock, reset, csr_rd_v,      csr_rd_o,      lsu_to_wbu_en);

  Reg #(32, 32'h0) regd24 (clock, reset, src2_v,        src2,          lsu_to_wbu_en);
  Reg #(2,  2 'h0) regd25 (clock, reset, wdOp_v,        wdOp,          lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd26 (clock, reset, csrwdOp_v,     csrwdOp,       lsu_to_wbu_en);
  Reg #(32, 32'h0) regd29 (clock, reset, exu_result_v,  exu_result,    lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd32 (clock, reset, ren_v,         ren,           lsu_to_wbu_en);
  Reg #(1,  1 'h0) regd33 (clock, reset, wen_v,         wen,           lsu_to_wbu_en);


  // 从flash读取的数据是4字节对齐，从sram读取的数据是8字节对齐，
  // 因此在处理从sram读取的数据时，要区分是前4字节还是后4字节
  reg [63:0] rdata_buffer;
  always @(posedge clock) begin
    if(reset) rdata_buffer <= 0;
    else      rdata_buffer <= rdata_r;
  end

  reg  [63:0] rdata_8;
  reg  [63:0] rdata_16;
  reg  [63:0] rdata_32;

  always @(*) begin
    rdata_8 = 0;
    rdata_16 = 0;
    if((araddr_r >= 32'hf000000 && araddr_r <= 32'hfffffff)) begin 
      rdata_8  = rdata_r >> (araddr_r[2]*32) >> (araddr_r[1:0]*8);
      rdata_16 = rdata_r >> (araddr_r[2]*32) >> (araddr_r[1]*16);
      rdata_32 = rdata_r >> (araddr_r[2]*32);
    end else begin
      rdata_8  = rdata_r >> (araddr_r[1:0]*8);
      rdata_16 = rdata_r >> (araddr_r[1]*16) >> (araddr_r[0]*8);
      rdata_32 = {32'h0, rdata_r[31:0]};
    end
  end

  wire  [31:0]  align_mread;
  MuxKeyWithDefault #(3, 32, 32) rwd(align_mread, rmask, 32'h0, {
    32'h000000ff, m_signed ? {{24{rdata_8[7]}} , rdata_8[7:0]}  : rdata_8[31:0] & rmask,
    32'h0000ffff, m_signed ? {{16{rdata_16[15]}}, rdata_16[15:0]} : rdata_16[31:0] & rmask,
    32'hffffffff, rdata_32[31:0]
  });

  // 只考虑在psram和sdram非对齐读取
  wire [63:0] unalign_rdata;
  assign unalign_rdata = {rdata_r[31:0], rdata_buffer[31:0]};

  reg  [63:0] unalign_rdata_16;
  reg  [63:0] unalign_rdata_32;
  always @(*) begin
    unalign_rdata_16 = 0;
    unalign_rdata_32 = 0;
    if(rmask == 32'h0000ffff) begin // araddr_r[1:0] == 2'b11
      unalign_rdata_16 = {48'h0, unalign_rdata[39:24]};
    end else begin
      case(araddr_r[1:0])
        2'b01:
          unalign_rdata_32 = {32'h0, unalign_rdata[39:8]};
        2'b10:
          unalign_rdata_32 = {32'h0, unalign_rdata[47:16]};
        2'b11:
          unalign_rdata_32 = {32'h0, unalign_rdata[55:24]};
        default: unalign_rdata_32 = 0;
      endcase
    end
  end

  wire [31:0] unalign_mread;
  MuxKeyWithDefault #(2, 32, 32) rwd1(unalign_mread, rmask, 32'h0, {
    32'h0000ffff, m_signed ? {{16{unalign_rdata_16[15]}}, unalign_rdata_16[15:0]} : unalign_rdata_16[31:0] & rmask,
    32'hffffffff, unalign_rdata_32[31:0]
  });

  wire [31:0] mread = unalign ? unalign_mread : align_mread;

  wire [31:0] awaddr_v;
  reg  [7 :0] align_wstrb_v;
  reg  [63:0] align_wdata_v;
  assign awaddr_v = exu_result_v;

  // AXITOAPB module 会把wmask再次恢复成四字节对齐
  always @(*) begin
    align_wstrb_v = 0;
    align_wdata_v = 0;
    if(wmask_v == 8'b00000001) begin
      align_wstrb_v = wmask_v << awaddr_v[2:0];
      align_wdata_v = {32'b0,rsb_v} << (awaddr_v[2:0]*8);
    end
    else if(wmask_v == 8'b00000011) begin  // 如果想让psram也支持非对齐写，这里需要修改
        align_wstrb_v = wmask_v << (awaddr_v[2:1]*2) << (awaddr_v[0]);
        align_wdata_v = {32'b0,rsb_v}   << (awaddr_v[2:1]*16) << (awaddr_v[0]*8);
    end
    else if(wmask_v == 8'b00001111) begin
      align_wstrb_v = wmask_v << (awaddr_v[2]*4);
      align_wdata_v = {32'b0,rsb_v}   << (awaddr_v[2]*32);
    end
  end

  // reg  [7 :0] unalign_wstrb_vA;
  // reg  [7 :0] unalign_wstrb_vB;
  // reg  [63:0] unalign_wdata_vA;
  // reg  [63:0] unalign_wdata_vB;

  // always @(*) begin
  //   unalign_wdata_vA = 0;
  //   unalign_wdata_vB = 0;
  //   unalign_wstrb_vA = 0;
  //   unalign_wstrb_vB = 0;
  //   if(wmask_v == 8'b00000011) begin
  //     case(awaddr_v[2:0])
  //       3'b000: begin end // 对齐
  //       3'b001: begin end // 对齐
  //       3'b010: begin end // 对齐
  //       3'b011:           // 不对齐
  //         begin
  //           unalign_wstrb_vA = 8'b00001000;
  //           unalign_wdata_vA = {32'h0, rsb_v[7:0], 24'h0};
  //           unalign_wstrb_vB = 8'b00010000;
  //           unalign_wdata_vB = {24'h0, rsb_v[15:8], 32'h0};
  //         end
  //       3'b100: begin end // 对齐
  //       3'b101: begin end // 对齐
  //       3'b110: begin end // 对齐
  //       3'b111: 
  //         begin
  //           unalign_wstrb_vA = 8'b10000000;
  //           unalign_wdata_vA = {rsb_v[7:0], 56'h0};
  //           unalign_wstrb_vB = 8'b00000001;
  //           unalign_wdata_vB = {56'h0, rsb_v[15:8]};
  //         end
  //     endcase
  //   end else if(wmask_v == 8'b00001111) begin
  //     case(awaddr_v[2:0])
  //       3'b000: begin end //对齐
  //       3'b001: 
  //         begin
  //           unalign_wstrb_vA = 8'b00001110;
  //           unalign_wdata_vA = {32'h0, rsb_v[23:0], 8'h0};
  //           unalign_wstrb_vB = 8'b00010000;
  //           unalign_wdata_vB = {24'h0, rsb_v[31:24], 32'h0};
  //         end
  //       3'b010:
  //         begin
  //           unalign_wstrb_vA = 8'b00001100;
  //           unalign_wdata_vA = {32'h0, rsb_v[15:0], 16'h0};
  //           unalign_wstrb_vB = 8'b00110000;
  //           unalign_wdata_vB = {16'h0, rsb_v[31:16], 32'h0};
  //         end
  //       3'b011:
  //         begin
  //           unalign_wstrb_vA = 8'b00001000;
  //           unalign_wdata_vA = {32'h0, rsb_v[7:0], 24'h0};
  //           unalign_wstrb_vB = 8'b01110000;
  //           unalign_wdata_vB = {8'h0, rsb_v[31:8], 32'h0};
  //         end
  //       3'b100: begin end //对齐
  //       3'b101: 
  //         begin
  //           unalign_wstrb_vA = 8'b11100000;
  //           unalign_wdata_vA = {rsb_v[23:0], 40'h0};
  //           unalign_wstrb_vB = 8'b00000001;
  //           unalign_wdata_vB = {56'h0, rsb_v[31:24]};
  //         end
  //       3'b110:
  //         begin
  //           unalign_wstrb_vA = 8'b11000000;
  //           unalign_wdata_vA = {rsb_v[15:0], 48'h0};
  //           unalign_wstrb_vB = 8'b00000011;
  //           unalign_wdata_vB = {48'h0, rsb_v[31:16]};
  //         end
  //       3'b111:
  //         begin
  //           unalign_wstrb_vA = 8'b10000000;
  //           unalign_wdata_vA = {rsb_v[7:0], 56'h0};
  //           unalign_wstrb_vB = 8'b00000111;
  //           unalign_wdata_vB = {40'h0, rsb_v[31:8]};
  //         end
  //     endcase
  //   end
  // end

  // wd choose
  MuxKeyWithDefault #(4, 2, 32) wdc (wd_o, wdOp, exu_result, {
    2'b00, exu_result,
    2'b01, mread,
    2'b10, pc_o+4,
    2'b11, src2
  });

  MuxKeyWithDefault #(2, 1, 32) csrwdc (csr_wd_o, csrwdOp, exu_result, {
    1'b0, exu_result,
    1'b1, pc_o
  });

  assign skip_d_o = ((exu_result >= `YSYX_23060059_UART_L && exu_result <= `YSYX_23060059_UART_H) 
                    || (exu_result >= `YSYX_23060059_CLINT_L && exu_result <= `YSYX_23060059_CLINT_H)) && (ren || wen);

  wire  [31:0] exu_result_v;
  wire  [31:0] pc_v;
  wire  [31:0] pc_next_v;
  wire  [31:0] instruction_v;
  wire         m_signed_v;
  wire  [31:0] rmask_v;
  wire         ecall_v;
  wire         ebreak_v;
  wire  [31:0] src2_v;
  wire  [31:0] rsb_v;
  wire  [1 :0] wdOp_v;
  wire         csrwdOp_v;
  wire  [4 :0] rd_v;
  wire  [1 :0] csr_rd_v;
  wire         reg_en_v;
  wire         csreg_en_v;
  wire  [7 :0] wmask_v;
  wire         ren_v;
  wire         wen_v;

  assign exu_result_v  = buffer ? exu_result_b  : result_i;
  assign pc_v          = buffer ? pc_b          : pc_i;
  assign pc_next_v     = buffer ? pc_next_b     : pc_next_i;
  assign instruction_v = buffer ? instruction_b : instruction_i;
  assign m_signed_v    = buffer ? m_signed_b    : m_signed_i;
  assign rmask_v       = buffer ? rmask_b       : rmask_i;
  assign ecall_v       = buffer ? ecall_b       : ecall_i;
  assign ebreak_v      = buffer ? ebreak_b      : ebreak_i;
  assign src2_v        = buffer ? src2_b        : src2_i;
  assign rsb_v         = buffer ? rsb_b         : rsb_i;
  assign wdOp_v        = buffer ? wdOp_b        : wdOp_i;
  assign csrwdOp_v     = buffer ? csrwdOp_b     : csrwdOp_i;
  assign rd_v          = buffer ? rd_b          : rd_i;
  assign csr_rd_v      = buffer ? csr_rd_b      : csr_rd_i;
  assign reg_en_v      = buffer ? reg_en_b      : reg_en_i;
  assign csreg_en_v    = buffer ? csreg_en_b    : csreg_en_i;
  assign wmask_v       = buffer ? wmask_b       : wmask_i;
  assign ren_v         = buffer ? ren_b         : ren_i;
  assign wen_v         = buffer ? wen_b         : wen_i; 


  assign send_valid   = send_valid_r;
  assign send_ready   = !buffer; // buffer

  assign araddr         = araddr_r;
  assign arvalid        = arvalid_r;
  assign rready         = rready_r;
  assign awaddr         = awaddr_r;
  assign awvalid        = awvalid_r;
  assign wvalid         = wvalid_r;
  assign bready         = bready_r;
  assign wstrb          = wstrb_r;
  assign wdata          = wdata_r;
  assign wlast          = 1;


  always @(posedge clock) begin
    if(reset) rready_r <= 0;
    else    rready_r <= 1;
  end

  always @(posedge clock) begin
    if(reset) bready_r <= 0;
    else    bready_r <= 1;
  end 

  assign  lsu_state = (next_state != IDLE);
  assign  rd_lsu_to_idu = (state == IDLE) ? rd_v : rd_o;
  assign  csr_rd_lsu_to_idu = (state == IDLE) ? csr_rd_v : csr_rd_o;


endmodule