`define YSYX_23060059_IMM   5'b00000
`define YSYX_23060059_ADD   5'b00001
`define YSYX_23060059_SUB   5'b00010
`define YSYX_23060059_AND   5'b00011
`define YSYX_23060059_XOR   5'b00100
`define YSYX_23060059_OR    5'b00101
`define YSYX_23060059_SL    5'b00110 // <<, unsigned
`define YSYX_23060059_SR    5'b00111 // >>, unsigned 
`define YSYX_23060059_DIV   5'b01000 // >=, unsigned
`define YSYX_23060059_SSR   5'b01001 // >>, signed
`define YSYX_23060059_SLES  5'b01010 // <, signed
`define YSYX_23060059_ULES  5'b01011 // <, unsigned
`define YSYX_23060059_REMU  5'b01100 // %, unsigned
`define YSYX_23060059_MUL   5'b01101 // *, unsigned 
`define YSYX_23060059_DIVU  5'b01110 // /, unsigned
`define YSYX_23060059_REM   5'b01111 
`define YSYX_23060059_SRC   5'b10000 
`define YSYS_23060059_MULHU 5'b10001 // *, unsigned, mulhu

`define YSYX_23060059_UART 32'ha00003f8



// define ALU TYPE
import "DPI-C" function void n_pmem_read(input int raddr, output int rdata);
import "DPI-C" function void n_pmem_write(input int waddr, input int wdata, input byte wmask);

module top(
    input                 clk,
    input                 rst,
    output reg  [31:0]    pc_next,
    output reg  [31:0]    pc,
    output                ebreak_t,
    output                skip_d
);

  wire                  endflag; 
  wire   [31:0]         instruction;
  wire   [31:0]         instruction_idu;
  wire   [31:0]         instruction_exu;
  wire   [31:0]         instruction_lsu;
  wire   [4 :0]         rs1;
  wire   [4 :0]         rs2;
  wire   [1 :0]         csr_rs;
  wire   [4 :0]         rd;
  wire   [4 :0]         rd_exu;
  wire   [4 :0]         rd_lsu;
  wire   [4 :0]         rd_lsu_to_idu;
  wire   [1 :0]         csr_rd;
  wire   [1 :0]         csr_rd_exu;
  wire   [1 :0]         csr_rd_lsu;
  wire   [1 :0]         csr_rd_lsu_to_idu;
  wire   [31:0]         imm;
  wire   [31:0]         imm_exu;
  wire   [1 :0]         pcOp;
  wire   [1 :0]         pcOp_exu;
  wire   [1 :0]         pcOpI;
  wire                  zero;
  wire   [1 :0]         wdOp;
  wire   [1 :0]         wdOp_exu;
  wire   [31:0]         src1;
  wire   [31:0]         src1_exu;
  wire   [31:0]         src2;
  wire   [31:0]         src2_exu;
  wire   [4 :0]         aluOp;
  wire   [2 :0]         BOp;
  wire   [2 :0]         BOp_exu;
  wire   [3 :0]         exu_state;
  wire                  lsu_state;
  wire   [2 :0]         wbu_state;
  wire                  Bjump;
  wire                  ren;
  wire                  ren_exu;
  wire                  wen;
  wire                  wen_exu;
  wire   [7 :0]         wmask;
  wire   [7 :0]         wmask_exu;
  wire   [31:0]         rmask;
  wire   [31:0]         rmask_exu;
  wire                  m_signed;
  wire                  m_signed_exu;
  wire                  reg_en;
  wire                  reg_en_exu;
  wire                  reg_en_lsu;
  wire                  csreg_en;
  wire                  csreg_en_exu;
  wire                  csreg_en_lsu;
  wire                  ecall;
  wire                  ecall_exu;
  wire                  ecall_lsu;
  wire                  ebreak;
  wire                  ebreak_exu;
  wire                  ebreak_lsu;
  wire                  csrwdOp;
  wire                  csrwdOp_exu;
  wire   [31:0]         rsa;
  wire   [31:0]         rsb;
  wire   [31:0]         rsb_idu;
  wire   [31:0]         rsb_exu;
  wire   [31:0]         pc_ifu_to_idu;
  wire   [31:0]         pc_idu;
  wire   [31:0]         pc_next_idu;
  wire   [31:0]         pc_exu;
  wire   [31:0]         pc_next_exu;
  wire   [31:0]         pc_lsu;
  wire   [31:0]         pc_next_lsu;
  wire   [31:0]         exu_result;
  wire   [31:0]         wd;
  wire   [31:0]         csr_wd;
  wire   [31:0]         csra;
  wire   [31:0]         memory_read_wd;
  wire                  pc_write_enable;
  wire                  ifu_send_valid;
  wire                  ifu_send_ready;
  wire                  idu_send_valid;
  wire                  idu_send_ready;
  wire                  lsu_send_valid;
  wire                  lsu_send_ready;
  wire                  exu_send_valid;
  wire                  exu_send_ready;
  wire                  ifu_receive_valid;
  wire   [31:0]         araddrA;
  wire   [31:0]         araddrB;
  wire                  arvalidA;
  wire                  arvalidB;
  wire                  rreadyA;
  wire                  rreadyB;
  wire                  arreadyA;
  wire                  arreadyB;
  wire   [31:0]         rdataA;
  wire   [31:0]         rdataB;
  wire                  rvalidA;
  wire                  rvalidB;
  wire   [1 :0]         rrespA;
  wire   [1 :0]         rrespB;
  wire   [31:0]         awaddrA;
  wire   [31:0]         awaddrB;
  wire                  awvalidA;
  wire                  awvalidB;
  wire   [31:0]         wdataA;
  wire   [31:0]         wdataB;
  wire   [7 :0]         wstrbA;
  wire   [7 :0]         wstrbB;
  wire                  wvalidA;
  wire                  wvalidB;
  wire                  breadyA;
  wire                  breadyB;
  wire                  awreadyA;
  wire                  awreadyB;
  wire                  wreadyA;
  wire                  wreadyB;
  wire   [1 :0]         brespA;
  wire   [1 :0]         brespB;
  wire                  bvalidA;
  wire                  bvalidB;


  Reg #(32, 32'h80000000) regd(clk, rst, pc_next_idu, pc,  pc_write_enable); // assign pc value


  // instruction fetch Unit
  ifu ifufetch(
    .clk                   (clk              ),
    .rst                   (rst              ),
    .pc_next               (pc_next          ),
    .pc_next_idu           (pc_next_idu      ),
    .receive_valid         (ifu_receive_valid),
    .send_valid            (ifu_send_valid   ),
    .send_ready            (ifu_send_ready   ),
    .receive_ready         (idu_send_ready   ),
    .pc_ifu_to_idu         (pc_ifu_to_idu    ),
    .instruction           (instruction      ),
    .arready               (arreadyA         ),
    .rdata                 (rdataA           ),
    .rvalid                (rvalidA          ),
    .rresp                 (rrespA           ),
    .araddr                (araddrA          ),
    .arvalid               (arvalidA         ),
    .rready                (rreadyA          )
  );

  // instruction Decode Unit
  idu id(
    .clk                   (clk              ),
    .rst                   (rst              ),
    .instruction_i         (instruction      ),
    .pc_i                  (pc_ifu_to_idu    ),
    .rsa                   (rsa              ),
    .rsb                   (rsb              ),
    .csra                  (csra             ),
    .exu_state             (exu_state        ),
    .wd_exu                (exu_result       ),
    .rd_lsu                (rd_lsu_to_idu    ), // rd_exu是rd_lsu的输入
    .csr_rd_lsu            (csr_rd_lsu_to_idu),
    .lsu_state             (lsu_state        ),
    .rd_wbu                (rd_lsu           ),
    .csr_rd_wbu            (csr_rd_lsu       ),
    .wd_wbu                (wd               ),
    .csr_wd_wbu            (csr_wd           ),
    .wbu_state             (wbu_state        ),
    .reg_en_wbu            (reg_en_lsu       ),
    .csreg_en_wbu          (csreg_en_lsu     ),
    .receive_valid         (ifu_send_valid   ),
    .rs1                   (rs1              ),
    .rs2                   (rs2              ),
    .csr_rs                (csr_rs           ),
    .rd_o                  (rd               ),
    .csr_rd_o              (csr_rd           ),
    .imm_o                 (imm              ),
    .pcOp_o                (pcOp             ),
    .aluOp_o               (aluOp            ),
    .src1_o                (src1             ),
    .src2_o                (src2             ),
    .BOp_o                 (BOp              ),
    .wdOp_o                (wdOp             ),
    .csrwdOp_o             (csrwdOp          ),
    .ren_o                 (ren              ),
    .wen_o                 (wen              ),
    .wmask_o               (wmask            ),
    .rmask_o               (rmask            ),
    .m_signed_o            (m_signed         ),
    .reg_en_o              (reg_en           ),
    .csreg_en_o            (csreg_en         ),
    .ecall_o               (ecall            ),
    .ebreak_o              (ebreak           ),
    .pc_o                  (pc_idu           ),
    .pc_next_o             (pc_next_idu      ),
    .rsb_o                 (rsb_idu          ),
    .instruction_o         (instruction_idu  ),
    .pc_write_enable       (pc_write_enable  ),
    .send_valid            (idu_send_valid   ),
    .send_ready            (idu_send_ready   ),
    .receive_ready         (exu_send_ready   ),
    .send_to_ifu_valid     (ifu_receive_valid)
  );

  // Reg Array Unit
  wbu wb(
    .clk                   (clk              ),
    .rst                   (rst              ),
    .receive_valid         (lsu_send_valid   ),
    .rs1                   (rs1              ),
    .rs2                   (rs2              ),
    .csr_rs                (csr_rs           ),
    .rd                    (rd_lsu           ),
    .csr_rd                (csr_rd_lsu       ),
    .wd                    (wd               ),
    .csr_wd                (csr_wd           ),
    .pc_next_i             (pc_next_lsu      ),
    .pc_i                  (pc_lsu           ),
    .ebreak_i              (ebreak_lsu       ),
    .instruction_i         (instruction_lsu  ),
    .reg_en                (reg_en_lsu       ),
    .csreg_en              (csreg_en_lsu     ),
    .ecall                 (ecall_lsu        ),
    .ebreak_o              (ebreak_t         ),
    .state_o               (wbu_state        ),
    .rsa                   (rsa              ),
    .rsb                   (rsb              ),
    .csra                  (csra             )
  );

  // Exection Unit  
  exu ex(
    .clk                   (clk              ),
    .rst                   (rst              ),
    .receive_valid         (idu_send_valid   ),
    .receive_ready         (lsu_send_ready   ),
    .src1_i                (src1             ),
    .src2_i                (src2             ),
    .rsb_i                 (rsb_idu          ),
    .aluOp_i               (aluOp            ),
    .imm_i                 (imm              ),
    .pcOp_i                (pcOp             ),
    .wdOp_i                (wdOp             ),
    .csrwdOp_i             (csrwdOp          ),
    .BOp_i                 (BOp              ),
    .ren_i                 (ren              ),
    .wen_i                 (wen              ),
    .wmask_i               (wmask            ),
    .rmask_i               (rmask            ),
    .m_signed_i            (m_signed         ),
    .reg_en_i              (reg_en           ),
    .csreg_en_i            (csreg_en         ),
    .ecall_i               (ecall            ),
    .ebreak_i              (ebreak           ),
    .pc_i                  (pc_idu           ),
    .pc_next_i             (pc_next_idu      ),
    .instruction_i         (instruction_idu  ),
    .rd_i                  (rd               ),
    .csr_rd_i              (csr_rd           ),
    .zero_o                (zero             ),
    .result_o              (exu_result       ),
    .src1_o                (src1_exu         ),
    .src2_o                (src2_exu         ),
    .imm_o                 (imm_exu          ),
    .pcOp_o                (pcOp_exu         ),
    .wdOp_o                (wdOp_exu         ),
    .csrwdOp_o             (csrwdOp_exu      ),
    .BOp_o                 (BOp_exu          ),
    .ren_o                 (ren_exu          ),
    .wen_o                 (wen_exu          ),
    .wmask_o               (wmask_exu        ),
    .rmask_o               (rmask_exu        ),
    .m_signed_o            (m_signed_exu     ),
    .reg_en_o              (reg_en_exu       ),
    .csreg_en_o            (csreg_en_exu     ),
    .ecall_o               (ecall_exu        ),
    .ebreak_o              (ebreak_exu       ),
    .pc_o                  (pc_exu           ),
    .rsb_o                 (rsb_exu          ),
    .rd_o                  (rd_exu           ),
    .pc_next_o             (pc_next_exu      ),
    .instruction_o         (instruction_exu  ),
    .csr_rd_o              (csr_rd_exu       ),
    .send_valid            (exu_send_valid   ),
    .send_ready            (exu_send_ready   ),
    .state_o               (exu_state        )  
  );

  lsu ls(
    .clk                   (clk              ),
    .rst                   (rst              ),
    .receive_valid         (exu_send_valid   ),
    .ren_i                 (ren_exu          ),
    .wen_i                 (wen_exu          ),
    .m_signed_i            (m_signed_exu     ),
    .wmask_i               (wmask_exu        ),
    .rmask_i               (rmask_exu        ),
    .result_i              (exu_result       ),
    .pc_i                  (pc_exu           ),
    .pc_next_i             (pc_next_exu      ),
    .instruction_i         (instruction_exu  ),
    .src2_i                (src2_exu         ),
    .rsb_i                 (rsb_exu          ),
    .wdOp_i                (wdOp_exu         ),
    .csrwdOp_i             (csrwdOp_exu      ),
    .rd_i                  (rd_exu           ),
    .csr_rd_i              (csr_rd_exu       ),
    .reg_en_i              (reg_en_exu       ),
    .csreg_en_i            (csreg_en_exu     ),
    .ecall_i               (ecall_exu        ),
    .ebreak_i              (ebreak_exu       ),
    .send_valid            (lsu_send_valid   ),
    .wd_o                  (wd               ),
    .csr_wd_o              (csr_wd           ),
    .rd_o                  (rd_lsu           ),
    .csr_rd_o              (csr_rd_lsu       ),
    .rd_lsu_to_idu         (rd_lsu_to_idu    ),
    .csr_rd_lsu_to_idu     (csr_rd_lsu_to_idu),
    .reg_en_o              (reg_en_lsu       ),
    .csreg_en_o            (csreg_en_lsu     ),
    .ecall_o               (ecall_lsu        ),
    .ebreak_o              (ebreak_lsu       ),
    .pc_next_o             (pc_next_lsu      ),
    .pc_o                  (pc_lsu           ),
    .skip_d_o              (skip_d           ),
    .instruction_o         (instruction_lsu  ),
    .send_ready            (lsu_send_ready   ),
    .lsu_state             (lsu_state        ),
    .arready               (arreadyB         ),
    .rdata                 (rdataB           ),
    .rresp                 (rrespB           ),
    .rvalid                (rvalidB          ),
    .awready               (awreadyB         ),
    .wready                (wreadyB          ),
    .bvalid                (bvalidB          ),
    .bresp                 (brespB           ),
    .araddr                (araddrB          ),
    .arvalid               (arvalidB         ),
    .rready                (rreadyB          ),
    .awaddr                (awaddrB          ),
    .awvalid               (awvalidB         ),
    .wvalid                (wvalidB          ),
    .bready                (breadyB          ),
    .wdata                 (wdataB           ),
    .wstrb                 (wstrbB           )
  );

  arbiter arb(
    .clk                    (clk             ),
    .rst                    (rst             ),
    .araddrA                (araddrA         ),
    .araddrB                (araddrB         ),
    .arvalidA               (arvalidA        ),
    .arvalidB               (arvalidB        ),
    .rreadyA                (rreadyA         ),
    .rreadyB                (rreadyB         ),
    .arreadyA_o             (arreadyA        ),
    .arreadyB_o             (arreadyB        ),
    .rdataA_o               (rdataA          ),
    .rdataB_o               (rdataB          ),
    .rvalidA_o              (rvalidA         ),
    .rvalidB_o              (rvalidB         ),
    .rrespA_o               (rrespA          ),
    .rrespB_o               (rrespB          ),
    .awaddrA                (awaddrA         ),
    .awaddrB                (awaddrB         ),
    .awvalidA               (awvalidA        ),
    .awvalidB               (awvalidB        ),
    .wdataA                 (wdataA          ),
    .wdataB                 (wdataB          ),
    .wstrbA                 (wstrbA          ),
    .wstrbB                 (wstrbB          ),
    .wvalidA                (wvalidA         ),
    .wvalidB                (wvalidB         ),
    .breadyA                (breadyA         ),
    .breadyB                (breadyB         ),
    .awreadyA_o             (awreadyA        ),
    .awreadyB_o             (awreadyB        ),
    .wreadyA_o              (wreadyA         ),
    .wreadyB_o              (wreadyB         ),
    .bvalidA_o              (bvalidA         ),
    .bvalidB_o              (bvalidB         ),
    .brespA_o               (brespA          ),
    .brespB_o               (brespB          )
  );

  reg [31:0] set_pc;

  // assign pc_next = (pc_write_enable == 1) ? pc_next_idu : ((pc == 32'h80000000) ? 32'h80000000 : pc_next_idu);

  always @(*) begin
    // if(pc == 32'h80000000) pc_next = 32'h80000000;
    // else 
    //   if(ifu_send_valid)
    //     pc_next = pc_next_r + 4;
    //   else if(pc_write_enable)
    //     pc_next = pc_next_idu;
    //   else
    //     pc_next = pc_next_r;
    if(ifu_send_valid)
      if(pc_write_enable)
        pc_next = pc_next_idu + 4;
      else
        pc_next = pc_next_r + 4;
    else if(pc_write_enable)
      pc_next = pc_next_idu;
    else
      if(set_pc != 0) begin
        pc_next = set_pc;
      end else 
        if(pc == 32'h80000000) pc_next = 32'h80000000;
        else                   pc_next = pc_next_r;
  end

  reg [31:0] pc_next_r;
  always @(posedge clk) begin
    if(rst) pc_next_r <= 0;
    else
      pc_next_r <= pc_next;
  end
 

endmodule