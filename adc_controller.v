module adc_controller(
  clk, reset, start_acquisition, data_enable, is_error, data_out,
  SCLK, CNVST, RD, CS, RESET, OB2C, PD, SDOUT, RDERROR, BUSY,
);
  // Suppose system clock is 150MHz, which is 6.777..ns/cycle.
  // TODO: Change this value according to the frequency of the occilator used.
  //
  // t2 (Sampling rate) >= 800ns
  localparam T2 = 119;
  // t9 (Reset duration) >= 15ns
  localparam T9 = 3;

  // mode enum
  localparam MODE_ERROR_RDERROR = 0;
  localparam MODE_ERROR_NOT_READY = 1;
  localparam MODE_RESETTING = 2;
  localparam MODE_RESET_WAIT_BUSY_UP = 3;
  localparam MODE_RESET_WAIT_BUSY_DOWN = 4;
  localparam MODE_READY = 5;
  localparam MODE_CONV_WAIT_BUSY_UP = 6;
  localparam MODE_CONV_WAIT_BUSY_DOWN = 7;
  localparam MODE_ACQUISITION = 8;
  localparam MODE_AFTER_ACQUISITION = 9;

  input clk, reset, start_acquisition;
  input RDERROR, BUSY, SDOUT;

  output data_enable, is_error;
  output [15:0] data_out;
  reg [17:0] data;

  output reg SCLK, CNVST, CS, RESET;
  output RD, OB2C, PD;

  reg [31:0] counter;
  reg counter_on;
  reg [31:0] reset_counter;
  reg [4:0] data_index;
  reg [3:0] mode;

  always @(posedge clk) begin
    if (reset) begin
      data <= 0;
      SCLK <= 1; // should be high when neutral
      CNVST <= 1;
      CS <= 1;
      counter <= 0;
      counter_on <= 0;
      data_index <= 17;

      RESET <= 1;
      mode <= MODE_RESETTING;
      reset_counter <= 1;
    end else if (RDERROR) begin
      mode <= MODE_ERROR_RDERROR;
    end else if (mode == !MODE_READY && start_acquisition) begin
      mode <= MODE_ERROR_NOT_READY;
    end else begin
      // Reset process
      if (mode == MODE_RESETTING) begin
        reset_counter <= reset_counter + 1;

        if (reset_counter == T9) begin
          RESET <= 0;
          mode <= MODE_RESET_WAIT_BUSY_UP;
        end
      end

      if (mode == MODE_RESET_WAIT_BUSY_UP) begin
        if (BUSY) begin
          mode <= MODE_RESET_WAIT_BUSY_DOWN;
        end
      end

      if (mode == MODE_RESET_WAIT_BUSY_DOWN) begin
        if (!BUSY) begin
          mode <= MODE_READY;
        end
      end

      // Conoversion process
      if (mode == MODE_READY) begin
        if (start_acquisition) begin
          CNVST <= 0;
          counter <= 0;
          counter_on <= 1;
          mode <= MODE_CONV_WAIT_BUSY_UP;
        end
      end

      if (mode == MODE_CONV_WAIT_BUSY_UP) begin
        if (BUSY) begin
          mode <= MODE_CONV_WAIT_BUSY_DOWN;
        end
      end

      if (mode == MODE_CONV_WAIT_BUSY_DOWN) begin
        if (!BUSY) begin
          mode <= MODE_ACQUISITION;
          CS <= 0; // Duration between CS negedge and SCLK negedge (data update) >= 5ns
          data_index <= 17; // MSB index
        end
      end

      // Acquisition process
      if (mode == MODE_ACQUISITION) begin
        // TODO: Change this procesure when clk frequency changes
        SCLK <= !SCLK; // 150/2 = 75MHz

        // Output is valid on posedge
        if (SCLK == 0) begin
          data[data_index] <= SDOUT;

          if (data_index >= 1) begin
            data_index <= data_index - 1;
          end else begin
            mode <= MODE_AFTER_ACQUISITION;
            CS <= 1;
          end
        end
      end

      if (mode == MODE_AFTER_ACQUISITION) begin
        if (counter >= T2) begin
          mode <= MODE_READY;
          counter_on <= 0;
        end
      end

      if (counter_on) begin
        counter <= counter + 1;
      end
    end
  end

  assign data_out = data[17:2];
  assign data_enable = (mode == MODE_AFTER_ACQUISITION);
  assign is_error = (mode == MODE_ERROR_NOT_READY || mode == MODE_ERROR_RDERROR);

  // ADC configuration
  assign RD = 0;
  assign OB2C = 0; // 2's complement
  assign PD = 0;
endmodule
