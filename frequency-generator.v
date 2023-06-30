module frequency_generator #(

  parameter FREQUENCY = 440
) (
  input clk,
  output reg toggle
);

  reg [23:0] count = 0;
  reg [23:0] target = 12_000_000 / FREQUENCY; // Calculate the target count for the desired frequency

  always @(posedge clk) begin
    if (count >= target) begin
      toggle <= ~toggle; // Toggle the output signal
      count <= 0; // Reset the counter
    end else begin
      count <= count + 1; // Increment the counter
    end
  end

endmodule

