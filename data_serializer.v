module DataSerializer(
  clk, reset, lower_adc_data, upper_adc_data,
  lower_adc_data_enable, upper_adc_data_enable, out_bit,
);
  // Mode enum
  localparam MODE_WAIT_ADC_DATA_ENABLE_UP = 0;
  localparam MODE_NOTIFY_START_SERIALIZING = 1;
  localparam MODE_NOTIFY_CHANNEL = 2;
  localparam MODE_SERIALIZING = 3;
  localparam MODE_AFTER_SERIALIZING = 4;

  input clk, reset, lower_adc_data_enable, upper_adc_data_enable;
  input [15:0] lower_adc_data, upper_adc_data;

  output reg out_bit;

  reg [15:0] data;
  reg [3:0] data_index;
  reg [2:0] mode;
  reg channel; // lower:0, upper: 1

  reg lower_adc_data_next_ready;
  reg upper_adc_data_next_ready;

  always @(posedge clk) begin
    if (reset) begin
      out_bit <= 0; // Keep out_bit 0 when neutral
      data <= 0;
      data_index <= 0;
      mode <= MODE_WAIT_ADC_DATA_ENABLE_UP;
      channel <= 0;
      lower_adc_data_next_ready <= 1;
      upper_adc_data_next_ready <= 1;
    end else begin
      if (mode == MODE_WAIT_ADC_DATA_ENABLE_UP) begin
         if ((lower_adc_data_enable && lower_adc_data_next_ready) || (upper_adc_data_enable && upper_adc_data_next_ready)) begin
           mode <= MODE_NOTIFY_START_SERIALIZING;
           out_bit <= 1;
         end

         if (lower_adc_data_enable && lower_adc_data_next_ready) begin
           data <= lower_adc_data;
           channel <= 0;
           lower_adc_data_next_ready <= 0;
         end else if (upper_adc_data_enable && upper_adc_data_next_ready) begin
           data <= upper_adc_data;
           channel <= 1;
           upper_adc_data_next_ready <= 0;
         end
      end

      if (mode == MODE_NOTIFY_START_SERIALIZING) begin
        out_bit <= channel;
        mode <= MODE_NOTIFY_CHANNEL;
        data_index <= 15;
      end

      if (mode == MODE_NOTIFY_CHANNEL) begin
        out_bit <= data[data_index];
        data_index <= data_index - 1;
        mode <= MODE_SERIALIZING;
      end

      if (mode == MODE_SERIALIZING) begin
        out_bit <= data[data_index];
        if (data_index >= 1) begin
          data_index <= data_index - 1;
        end else begin
          mode <= MODE_AFTER_SERIALIZING;
        end
      end

      if (mode == MODE_AFTER_SERIALIZING) begin
        out_bit <= 0;
        mode <= MODE_WAIT_ADC_DATA_ENABLE_UP;
      end

      if (!lower_adc_data_next_ready && !lower_adc_data_enable) begin
        lower_adc_data_next_ready <= 1;
      end

      if (!upper_adc_data_next_ready && !upper_adc_data_enable) begin
        upper_adc_data_next_ready <= 1;
      end
    end
  end
endmodule
