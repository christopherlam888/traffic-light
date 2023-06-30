// Clock divider
module clock_divider #(
 
  // Parameters (default values)
  parameter COUNT_WIDTH = 24,
  parameter [COUNT_WIDTH:0] MAX_COUNT = 6000000 - 1
) (

  // Inputs
  input clk,
  input rst,

  // Outputs 
  output reg out
);

  // Internal signals  
  reg div_clk;
  reg [COUNT_WIDTH:0] count;

  // Clock divider
  always @ (posedge clk or posedge rst) begin
    if (rst == 1'b1) begin
      count <= 0;
      out <= 0;
    end else if (count == MAX_COUNT) begin
      count <= 0;
      out <= ~out;
    end else begin
      count <= count + 1;
    end
  end

endmodule
