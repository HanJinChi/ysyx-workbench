`include "defines.v"

// define ALU TYPE
import "DPI-C" function void n_pmem_read(input int raddr, output int rdata);
import "DPI-C" function void n_pmem_write(input int waddr, input int wdata, input byte wmask);

module ysyx_23060059(
    input            clock,
    input            reset,
    input            io_interrupt,
    input		         io_master_awready,	
    output		       io_master_awvalid,	
    output	[31:0]	 io_master_awaddr,	
    output	[3 :0] 	 io_master_awid,
    output	[7 :0]	 io_master_awlen,	
    output	[2 :0]	 io_master_awsize,	
    output	[1 :0]	 io_master_awburst,	
    input		         io_master_wready,	
    output		       io_master_wvalid,	
    output	[63:0]	 io_master_wdata,
    output	[7 :0]	 io_master_wstrb,	
    output		       io_master_wlast,	
    output		       io_master_bready,	
    input		         io_master_bvalid,	
    input	  [1 :0]	 io_master_bresp,
    input	  [3 :0]	 io_master_bid,
    input		         io_master_arready,	
    output		       io_master_arvalid,	
    output	[31:0]	 io_master_araddr,	
    output	[3 :0]	 io_master_arid,
    output	[7 :0]	 io_master_arlen,	
    output	[2 :0]	 io_master_arsize,	
    output	[1 :0]	 io_master_arburst,	
    output		       io_master_rready,	
    input		         io_master_rvalid,	
    input	  [1 :0]	 io_master_rresp,
    input	  [63:0]   io_master_rdata,	
    input		         io_master_rlast,	
    input 	[3 :0]	 io_master_rid,

    output		       io_slave_awready,
    input		         io_slave_awvalid,
    input	  [31:0]	 io_slave_awaddr,
    input	  [3 :0]	 io_slave_awid,
    input	  [7 :0]	 io_slave_awlen,
    input	  [2 :0]	 io_slave_awsize,
    input	  [1 :0]	 io_slave_awburst,
    output		       io_slave_wready,
    input		         io_slave_wvalid,
    input	  [63:0]	 io_slave_wdata,
    input	  [7 :0]	 io_slave_wstrb,
    input		         io_slave_wlast,
    input		         io_slave_bready,
    output		       io_slave_bvalid,
    output	[1 :0]	 io_slave_bresp,
    output	[3 :0]	 io_slave_bid,
    output		       io_slave_arready,
    input		         io_slave_arvalid,
    input	  [31:0]	 io_slave_araddr,
    input	  [3 :0]	 io_slave_arid,
    input	  [7 :0]	 io_slave_arlen,
    input	  [2 :0]	 io_slave_arsize,
    input	  [1 :0]	 io_slave_arburst,
    input		         io_slave_rready,
    output		       io_slave_rvalid,
    output	[1 :0]	 io_slave_rresp,
    output	[63:0]	 io_slave_rdata,
    output		       io_slave_rlast,
    output	[3 :0]	 io_slave_rid
    // output reg  [31:0]    pc_next,
    // output reg  [31:0]    pc,
    // output                ebreak_t,
    // output                skip_d
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
  wire   [63:0]         rdataA;
  wire   [63:0]         rdataB;
  wire                  rvalidA;
  wire                  rvalidB;
  wire   [1 :0]         rrespA;
  wire   [1 :0]         rrespB;
  wire   [31:0]         awaddrA;
  wire   [31:0]         awaddrB;
  wire                  awvalidA;
  wire                  awvalidB;
  wire   [63:0]         wdataA;
  wire   [63:0]         wdataB;
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
  wire   [3 :0]         awidA;
  wire   [3 :0]         awidB;
  wire   [7 :0]         awlenA;
  wire   [7 :0]         awlenB;
  wire   [2 :0]         awsizeA;
  wire   [2 :0]         awsizeB;
  wire   [1 :0]         awburstA;
  wire   [1 :0]         awburstB;
  wire                  wlastA;
  wire                  wlastB;
  wire   [3 :0]         bidA;
  wire   [3 :0]         bidB;
  wire   [3 :0]         aridA;
  wire   [3 :0]         aridB;
  wire   [7 :0]         arlenA;
  wire   [7 :0]         arlenB;
  wire   [2 :0]         arsizeA;
  wire   [2 :0]         arsizeB;
  wire   [1 :0]         arburstA;
  wire   [1 :0]         arburstB;
  wire                  rlastA;
  wire                  rlastB;
  wire   [3 :0]         ridA;
  wire   [3 :0]         ridB;

  Reg #(32, 32'h2000_0000) regd(clock, reset, pc_next_idu, pc,  pc_write_enable); // assign pc value

  // instruction fetch Unit
  ysyx_23060059_ifu ifufetch(
    .clock                 (clock            ),
    .reset                 (reset            ),
    .pc_next               (pc_next          ),
    .pc_next_idu           (pc_next_idu      ),
    .receive_valid         (ifu_receive_valid),
    .send_valid            (ifu_send_valid   ),
    .send_ready            (ifu_send_ready   ),
    .receive_ready         (idu_send_ready   ),
    .pc_ifu_to_idu         (pc_ifu_to_idu    ),
    .instruction           (instruction      ),
    .arready               (arreadyA         ),
    .araddr                (araddrA          ),
    .arvalid               (arvalidA         ),
    .arid                  (aridA            ),
    .arlen                 (arlenA           ),
    .arsize                (arsizeA          ),
    .arburst               (arburstA         ),
    .rdata                 (rdataA           ),
    .rvalid                (rvalidA          ),
    .rresp                 (rrespA           ),
    .rready                (rreadyA          ),
    .rlast                 (rlastA           ),
    .rid                   (ridA             )
  );

  // instruction Decode Unit
  ysyx_23060059_idu id(
    .clock                 (clock            ),
    .reset                 (reset            ),
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
  ysyx_23060059_wbu wb(
    .clock                 (clock            ),
    .reset                 (reset            ),
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
  ysyx_23060059_exu ex(
    .clock                 (clock            ),
    .reset                 (reset            ),
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

  ysyx_23060059_lsu ls(
    .clock                 (clock            ),
    .reset                 (reset            ),
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
    .araddr                (araddrB          ),
    .arvalid               (arvalidB         ),
    .arid                  (aridB            ),
    .arlen                 (arlenB           ),
    .arsize                (arsizeB          ),
    .arburst               (arburstB         ),

    .rdata                 (rdataB           ),
    .rresp                 (rrespB           ),
    .rvalid                (rvalidB          ),
    .rlast                 (rlastB           ),
    .rid                   (ridB             ),
    .rready                (rreadyB          ),

    .awready               (awreadyB         ),
    .awaddr                (awaddrB          ),
    .awvalid               (awvalidB         ),
    .awid                  (awidB            ),
    .awlen                 (awlenB           ),
    .awsize                (awsizeB          ),
    .awburst               (awburstB         ),

    .wready                (wreadyB          ),
    .wdata                 (wdataB           ),
    .wstrb                 (wstrbB           ),
    .wvalid                (wvalidB          ),
    .wlast                 (wlastB           ),
    
    .bvalid                (bvalidB          ),
    .bresp                 (brespB           ),
    .bready                (breadyB          ),
    .bid                   (bidB             )
  );

  ysyx_23060059_arbiter arb(
    .clock                  (clock           ),
    .reset                  (reset           ),
    .araddrA                (araddrA         ),
    .araddrB                (araddrB         ),
    .arvalidA               (arvalidA        ),
    .arvalidB               (arvalidB        ),
    .aridA                  (aridA           ),
    .aridB                  (aridB           ),
    .arlenA                 (arlenA          ),
    .arlenB                 (arlenB          ),
    .arsizeA                (arsizeA         ),
    .arsizeB                (arsizeB         ),
    .arburstA               (arburstA        ),
    .arburstB               (arburstB        ),
    .ridA_o                 (ridA            ),
    .ridB_o                 (ridB            ),
    .rlastA_o               (rlastA          ),
    .rlastB_o               (rlastB          ),
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
    .awidA                  (awidA           ),
    .awidB                  (awidB           ),
    .awlenA                 (awlenA          ),
    .awlenB                 (awlenB          ),
    .awsizeA                (awsizeA         ),
    .awsizeB                (awsizeB         ),
    .awburstA               (awburstA        ),
    .awburstB               (awburstB        ),
    .wlastA                 (wlastA          ),
    .wlastB                 (wlastB          ), 
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
    .brespB_o               (brespB          ),

    .arready                (io_master_arready),
    .araddr                 (io_master_araddr ),
    .arvalid                (io_master_arvalid),
    .arid                   (io_master_arid   ),
    .arlen                  (io_master_arlen  ),
    .arsize                 (io_master_arsize ),
    .arburst                (io_master_arburst),
    .rdata                  (io_master_rdata  ),
    .rvalid                 (io_master_rvalid ),
    .rresp                  (io_master_rresp  ),
    .rid                    (io_master_rid    ),
    .rlast                  (io_master_rlast  ),
    .rready                 (io_master_rready ),
    .awready                (io_master_awready),
    .awvalid                (io_master_awvalid),
    .awid                   (io_master_awid   ),
    .awlen                  (io_master_awlen  ),
    .awsize                 (io_master_awsize ),
    .awburst                (io_master_awburst),
    .awaddr                 (io_master_awaddr ),
    .wdata                  (io_master_wdata  ),
    .wstrb                  (io_master_wstrb  ),
    .wvalid                 (io_master_wvalid ),
    .wlast                  (io_master_wlast  ),
    .wready                 (io_master_wready ),
    .bvalid                 (io_master_bvalid ),
    .bresp                  (io_master_bresp  ),
    .bready                 (io_master_bready )
  );

  reg  [31:0]  set_pc;
  reg  [31:0]  pc_next;
  wire [31:0]  pc;
  wire         skip_d;
  wire         ebreak_t;
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
        if(pc == 32'h2000_0000) pc_next = 32'h2000_0000;
        else                   pc_next = pc_next_r;
  end

  reg [31:0] pc_next_r;
  always @(posedge clock) begin
    if(reset) pc_next_r <= 0;
    else
      pc_next_r <= pc_next;
  end
 

endmodule