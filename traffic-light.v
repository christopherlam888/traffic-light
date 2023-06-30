module traffic_light (
  // Inputs
  input clk,
  input off_btn,
  input rst_btn,
  input ped_btn,

  // Outputs
  output reg led_r,
  output reg led_y,
  output reg led_g,
  output reg buzzer
);

  // States
  localparam STATE_OFF = 2'b00;
  localparam STATE_RED = 2'b01;
  localparam STATE_YELLOW = 2'b10;
  localparam STATE_GREEN = 2'b11;

  // Internal signals
  reg off, rst, ped;
  reg rst_clk = 1'b0;
  reg rst_cnt = 1'b0;
  wire div_clk;
  wire [3:0] count_out_r;
  wire [3:0] count_out_y;
  wire [3:0] count_out_g;
  wire count_done_r;
  wire count_done_y;
  wire count_done_g;
  wire buzzer_toggle;

  // Internal storage elements
  reg [1:0] state = STATE_RED;
  reg init_go = 1'b1;
  reg [23:0] beep_count = 0;
  reg ped_present = 1'b0;

  // Assign button values to reg signals
  always @(posedge clk) begin
    off <= ~off_btn;
    rst <= ~rst_btn;
    ped <= ~ped_btn;
  end

  // Instantiate the clock divider module
  clock_divider #(.COUNT_WIDTH(24), .MAX_COUNT(1500000 - 1)) div (
    .clk(clk),
    .rst(rst_clk),
    .out(div_clk)
  );

  // Instantiate the counter module
  counter #(.COUNT_UP(1), .MAX_COUNT(4'h8)) count_r (
    .clk(div_clk),
    .rst(rst_cnt),
    .go(init_go | count_done_y),
    .out(count_out_r),
    .done(count_done_r)
  );

  // Instantiate the counter module
  counter #(.COUNT_UP(1), .MAX_COUNT(4'h2)) count_y (
    .clk(div_clk),
    .rst(rst_cnt),
    .go(count_done_g),
    .out(count_out_y),
    .done(count_done_y)
  );

  // Instantiate the counter module
  counter #(.COUNT_UP(1), .MAX_COUNT(4'h8)) count_g (
    .clk(div_clk),
    .rst(rst_cnt),
    .go(count_done_r),
    .out(count_out_g),
    .done(count_done_g)
  );

  // Instantiate the frequency generator module for the buzzer
  frequency_generator #(.FREQUENCY(440)) div_buzzer (
    .clk(clk),
    .toggle(buzzer_toggle)
  );

  // State transition logic
  always @(posedge div_clk) begin
    if (off == 1'b1) begin
      state <= STATE_OFF;
    end else if (rst == 1'b1) begin
      state <= STATE_RED;
      init_go <= 1'b1;
      rst_cnt <= 1'b1;
      ped_present <= 1'b0;
    end else if (ped == 1'b1) begin
      ped_present <= 1'b1;
    end else begin
      rst_cnt <= 1'b0;
      case (state)
        STATE_RED:
          if (count_done_r) begin
            state <= STATE_GREEN;
            if (init_go)
              init_go <= 1'b0;
          end
        STATE_YELLOW:
          if (count_done_y) begin
            state <= STATE_RED;
          end
        STATE_GREEN: begin
          if (count_done_g) begin
            state <= STATE_YELLOW;
            ped_present <= 1'b0;
          end
        end
        default:
          state <= STATE_OFF;
      endcase
    end
  end

  // State output logic
  always @(posedge div_clk) begin
    case (state)
      STATE_OFF:
        {led_r, led_y, led_g} <= 3'b000;
      STATE_RED: 
        {led_r, led_y, led_g} <= 3'b100;
      STATE_YELLOW:
        {led_r, led_y, led_g} <= 3'b010;
      STATE_GREEN: 
        {led_r, led_y, led_g} <= 3'b001;
      default:
        {led_r, led_y, led_g} <= 3'b000;
    endcase
  end

  // Buzzer control logic
  always @(posedge clk) begin
    if (state == STATE_GREEN && ped_present == 1'b1) begin
      if (beep_count >= 6000000) begin
        buzzer <= buzzer_toggle;
        if (beep_count >= 9000000)
          beep_count <= 0;
        else
          beep_count <= beep_count + 1;
      end else begin
        buzzer <= 1'b0;
        beep_count <= beep_count + 1;
      end
    end else begin
      buzzer <= 1'b0;
      beep_count <= 0;
    end
  end

endmodule
