module replacer(
  input    wire          clk,
  input    wire          rst,
  input    wire   [2:0]  idx,
  input    wire   [2:0]  way,
  input    wire          access,
  input    wire          invalid,
  output   wire   [2:0]  rway_o
);
  // same to cache
  localparam nset = 8;
  localparam nway = 8;

  reg [nway-1:0] free_map [nset-1:0]; // 0代表未使用, 1代表已使用
  reg [4:0]      used_map [nset-1:0][nway-1:0]; // 记录每个way的使用次数

  always @(posedge clk) begin
    if(rst) begin
      for(int i = 0; i < nset; i++)
        free_map[i] <= 0;
    end else begin
      if(access) begin
        if(free_map[idx][way] == 0)
          free_map[idx][way] <= 1;
      end else if(invalid) begin
        free_map[idx][map] <= 0;
      end
    end
  end

  always @(posedge clk) begin
    if(rst) begin
      for(int i = 0; i < nset; i++)
        for(int j = 0; j < nway; j++)
          used_map[i][j] <= 0;
    end else begin
      if(access) begin
        if(used_map[idx][way] != 5'd31) begin
          used_map[idx][way] <= used_map[idx][map]+1;
        end else if(invalid) begin
          used_map[idx][way] <= 0;
        end
      end
    end
  end

  reg  [2:0]  rway_f;
  reg         rway_f_valid;
  always @(*) begin
    rway_f = 0;
    rway_f_valid = 0;
    for(int w = 0; w < nway; w++) begin
      if(free_map[idx][w]) begin
        rway_f = w;
        rway_f_valid = 1;
      end
    end
  end

  reg  [2:0]  rway_u;
  reg  [4:0]  max_value;
  always @(*) begin
    rway_u    = 0;
    max_value = 0;
    for(int w = 0; w < nway; w++)begin
      if(used_map[w] > max_value) begin
        max_value = used_map[w];
        rway_u = w;
      end
    end
  end

  assign rway_o = rway_f_valid ? rway_f : rway_u;

endmodule