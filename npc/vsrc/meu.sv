module meu (
    input                 ren,
    input                 wen,
    input                 memory_read_signed,
    input   [31:0]        rsb,
    input   [7 :0]        wmask,
    input   [31:0]        rmask,
    input   [31:0]        exu_result,
    output  [31:0]        memory_read_wd
);
  
  reg   [31:0]    memory_read;

  always @(*) begin
    if(ren)    n_pmem_read(exu_result, memory_read);
    else       memory_read = 0;
    if(wen)    n_pmem_write(exu_result, rsb, wmask);
    else       n_pmem_write(exu_result, rsb, 0);
  end

  MuxKeyWithDefault #(3, 32, 32) rwd(memory_read_wd, rmask, 32'h0, {
    32'h000000ff, memory_read_signed ? {{24{memory_read[7]}} , memory_read[7:0]}  : memory_read & rmask,
    32'h0000ffff, memory_read_signed ? {{16{memory_read[15]}}, memory_read[15:0]} : memory_read & rmask,
    32'hffffffff, memory_read
  });
    
endmodule