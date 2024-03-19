module ysyx_23060059_replacer(
  input    wire          clock,
  input    wire          reset,
  input    wire   [4:0]  idx,
  input    wire   [2:0]  way,
  input    wire          flush,
  input    wire          access,
  input    wire          invalid,
  output   wire   [2:0]  rway_o
);
  // same to cache
  localparam nset = 32;
  localparam nway = 8;

  reg          free_map [255:0]; // 0代表未使用, 1代表已使用
  reg [4:0]    used_map [255:0]; // 记录每个way的使用次数

  integer i, j, w;

  wire [7:0] widx;
  assign widx = idx*nway+{4'h0, way};

  always @(posedge clock) begin
    if(reset || flush) begin
      for(i = 0; i < 255; i=i+1)
        free_map[i] = 0;
    end else begin
      if(access) begin
        if(free_map[widx] == 0)
          free_map[widx] <= 1;
      end else if(invalid) begin
        free_map[widx] <= 0;
    end
    end
  end


  always @(posedge clock) begin
    if(reset || flush) begin
      for(i = 0; i < 255; i=i+1)
          used_map[i] = 0;
    end else begin
      if(access) begin
        used_map[idx*nway  ] <= (idx*nway   == widx) ? 5'd31 : (used_map[idx*nway] > 0 :used_map[idx*nway]-1 : 0);
        used_map[idx*nway+1] <= (idx*nway+1 == widx) ? 5'd31 : (used_map[idx*nway+1] > 0 :used_map[idx*nway+1]-1 : 0);
        used_map[idx*nway+2] <= (idx*nway+2 == widx) ? 5'd31 : (used_map[idx*nway+2] > 0 :used_map[idx*nway+2]-1 : 0);
        used_map[idx*nway+3] <= (idx*nway+3 == widx) ? 5'd31 : (used_map[idx*nway+3] > 0 :used_map[idx*nway+3]-1 : 0);
        used_map[idx*nway+4] <= (idx*nway+4 == widx) ? 5'd31 : (used_map[idx*nway+4] > 0 :used_map[idx*nway+4]-1 : 0);
        used_map[idx*nway+5] <= (idx*nway+5 == widx) ? 5'd31 : (used_map[idx*nway+5] > 0 :used_map[idx*nway+5]-1 : 0);
        used_map[idx*nway+6] <= (idx*nway+6 == widx) ? 5'd31 : (used_map[idx*nway+6] > 0 :used_map[idx*nway+6]-1 : 0);
        used_map[idx*nway+7] <= (idx*nway+7 == widx) ? 5'd31 : (used_map[idx*nway+7] > 0 :used_map[idx*nway+7]-1 : 0);
      end else if(invalid) begin
        used_map[widx] <= 0;
      end 
    end
  end


  reg  [2:0]  rway_f;
  reg         rway_f_valid;
  always @(*) begin
    rway_f = 0;
    rway_f_valid = 0;
    for(w = 0; w < nway; w=w+1) begin
      if(!free_map[idx*nway+w]) begin
        rway_f = w[2:0];
        rway_f_valid = 1;
      end
    end
  end

  reg  [2:0]  rway_u;
  reg  [5:0]  min_value;
  always @(*) begin
    rway_u    = 0;
    min_value = 6'd33;
    for(w = 0; w < nway; w = w+1)begin
      if({1'h0, used_map[idx*nway + w]} < min_value) begin
        min_value = {1'h0, used_map[idx*nway + w]};
        rway_u = w[2:0];
      end
    end
  end

  assign rway_o = rway_f_valid ? rway_f : rway_u; //  从free_map或used_map中选择一个进行替换

endmodule