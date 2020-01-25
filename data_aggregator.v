module data_aggregator(
  clk, reset, bit1, bit2, bit3, bit4, read_index_yaxis, read_index_xaxis,
  out_data_yaxis, out_data_xaxis, finished,
);
  // Mode enum
  localparam MODE_WAIT_START = 0;
  localparam MODE_WAIT_CHANNEL = 1;
  localparam MODE_WAIT_DATA = 2;
  localparam MODE_ASSIGN_DATA = 3;

  input clk, reset;
  input bit1, bit2, bit3, bit4; // Correspond to AFE number
  input [6:0] read_index_yaxis, read_index_xaxis;

  output [15:0] out_data_yaxis; // Correspond to AFE number 1 and 2
  output [15:0] out_data_xaxis; // Correspond to AFE nubmer 3 and 4
  output finished;

  reg [15:0] data_yaxis [0:127];
  reg [15:0] data_xaxis [0:127];

  reg [15:0] bit1_data_buffer, bit2_data_buffer, bit3_data_buffer, bit4_data_buffer;
  reg [3:0] bit1_data_buffer_index, bit2_data_buffer_index, bit3_data_buffer_index, bit4_data_buffer_index;

  reg [4:0] data_index_yaxis1, data_index_yaxis2, data_index_yaxis3, data_index_yaxis4;
  reg [4:0] data_index_xaxis1, data_index_xaxis2, data_index_xaxis3, data_index_xaxis4;
  reg data_yaxis1_valid, data_yaxis2_valid, data_yaxis3_valid, data_yaxis4_valid;
  reg data_xaxis1_valid, data_xaxis2_valid, data_xaxis3_valid, data_xaxis4_valid;

  // 0: lower ADC output, 1: upper ADC output
  reg channel_bit1, channel_bit2, channel_bit3, channel_bit4;

  reg [1:0] mode_bit1, mode_bit2, mode_bit3, mode_bit4;

  wire data_yaxis_valid, data_xaxis_valid;

  integer i;
  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < 128; i++) begin
        data_yaxis[i] = 0;
        data_xaxis[i] = 0;
      end

      bit1_data_buffer <= 0;
      bit2_data_buffer <= 0;
      bit3_data_buffer <= 0;
      bit4_data_buffer <= 0;
      bit1_data_buffer_index <= 0;
      bit2_data_buffer_index <= 0;
      bit3_data_buffer_index <= 0;
      bit4_data_buffer_index <= 0;

      data_index_yaxis1 <= 31;
      data_index_yaxis2 <= 31;
			data_index_yaxis3 <= 31;
      data_index_yaxis4 <= 31;
			data_index_xaxis1 <= 31;
      data_index_xaxis2 <= 31;
			data_index_xaxis3 <= 31;
      data_index_xaxis4 <= 31;

			data_yaxis1_valid <= 0;
      data_yaxis2_valid <= 0;
			data_yaxis3_valid <= 0;
      data_yaxis4_valid <= 0;
			data_xaxis1_valid <= 0;
      data_xaxis2_valid <= 0;
			data_xaxis3_valid <= 0;
      data_xaxis4_valid <= 0;

			channel_bit1 <= 0;
      channel_bit2 <= 0;
      channel_bit3 <= 0;
      channel_bit4 <= 0;

			mode_bit1 <= MODE_WAIT_START;
      mode_bit2 <= MODE_WAIT_START;
      mode_bit3 <= MODE_WAIT_START;
      mode_bit4 <= MODE_WAIT_START;
    end else begin
      // Process for bit1
      if (mode_bit1 == MODE_WAIT_START) begin
        if (bit1) begin
          mode_bit1 <= MODE_WAIT_CHANNEL;
        end
      end else if (mode_bit1 == MODE_WAIT_CHANNEL) begin
        channel_bit1 <= bit1;
        mode_bit1 <= MODE_WAIT_DATA;
        bit1_data_buffer_index <= 15;
      end else if (mode_bit1 == MODE_WAIT_DATA) begin
        bit1_data_buffer[bit1_data_buffer_index] <= bit1;
        if (bit1_data_buffer_index >= 1) begin
          bit1_data_buffer_index <= bit1_data_buffer_index - 1;
        end else begin
          mode_bit1 <= MODE_ASSIGN_DATA;
        end
      end else if (mode_bit1 == MODE_ASSIGN_DATA) begin
        mode_bit1 <= MODE_WAIT_START;
        if (channel_bit1 == 0) begin // yaxis adc1 (31-0)
          data_yaxis[data_index_yaxis1] <= bit1_data_buffer;
          if (data_index_yaxis1 >= 1) begin
            data_index_yaxis1 <= data_index_yaxis1 - 1;
            data_yaxis1_valid <= 0;
          end else begin
            data_index_yaxis1 <= 31;
            data_yaxis1_valid = 1;
          end
        end else begin // yaxis adc2 (63-32)
          data_yaxis[32 + data_index_yaxis2] <= bit1_data_buffer;
          if (data_index_yaxis2 >= 1) begin
            data_index_yaxis2 <= data_index_yaxis2 - 1;
            data_yaxis2_valid <= 0;
          end else begin
            data_index_yaxis2 <= 31;
            data_yaxis2_valid <= 1;
          end
        end
      end

      // Process for bit2
      if (mode_bit2 == MODE_WAIT_START) begin
        if (bit2) begin
          mode_bit2 <= MODE_WAIT_CHANNEL;
        end
      end else if (mode_bit2 == MODE_WAIT_CHANNEL) begin
        channel_bit2 <= bit2;
        mode_bit2 <= MODE_WAIT_DATA;
        bit2_data_buffer_index <= 15;
      end else if (mode_bit2 == MODE_WAIT_DATA) begin
        bit2_data_buffer[bit2_data_buffer_index] <= bit2;
        if (bit2_data_buffer_index >= 1) begin
          bit2_data_buffer_index <= bit2_data_buffer_index - 1;
        end else begin
          mode_bit2 <= MODE_ASSIGN_DATA;
        end
      end else if (mode_bit2 == MODE_ASSIGN_DATA) begin
        mode_bit2 <= MODE_WAIT_START;
        if (channel_bit2 == 0) begin // yaxis adc3 (95-64)
          data_yaxis[64 + data_index_yaxis3] <= bit2_data_buffer;
          if (data_index_yaxis3 >= 1) begin
            data_index_yaxis3 <= data_index_yaxis3 - 1;
            data_yaxis3_valid <= 0;
          end else begin
            data_index_yaxis3 <= 31;
            data_yaxis3_valid = 1;
          end
        end else begin // yaxis adc4 (127-96)
          data_yaxis[96 + data_index_yaxis4] <= bit2_data_buffer;
          if (data_index_yaxis4 >= 1) begin
            data_index_yaxis4 <= data_index_yaxis4 - 1;
            data_yaxis4_valid <= 0;
          end else begin
            data_index_yaxis4 <= 31;
            data_yaxis4_valid <= 1;
          end
        end
      end

      // Process for bit3
      if (mode_bit3 == MODE_WAIT_START) begin
        if (bit3) begin
          mode_bit3 <= MODE_WAIT_CHANNEL;
        end
      end else if (mode_bit3 == MODE_WAIT_CHANNEL) begin
        channel_bit3 <= bit3;
        mode_bit3 <= MODE_WAIT_DATA;
        bit3_data_buffer_index <= 15;
      end else if (mode_bit3 == MODE_WAIT_DATA) begin
        bit3_data_buffer[bit3_data_buffer_index] <= bit3;
        if (bit3_data_buffer_index >= 1) begin
          bit3_data_buffer_index <= bit3_data_buffer_index - 1;
        end else begin
          mode_bit3 <= MODE_ASSIGN_DATA;
        end
      end else if (mode_bit3 == MODE_ASSIGN_DATA) begin
        mode_bit3 <= MODE_WAIT_START;
        if (channel_bit3 == 0) begin // xaxis adc1 (31-0)
          data_xaxis[data_index_xaxis1] <= bit3_data_buffer;
          if (data_index_xaxis1 >= 1) begin
            data_index_xaxis1 <= data_index_xaxis1 - 1;
            data_xaxis1_valid <= 0;
          end else begin
            data_index_xaxis1 <= 31;
            data_xaxis1_valid = 1;
          end
        end else begin // xaxis adc2 (63-32)
          data_xaxis[32 + data_index_xaxis2] <= bit3_data_buffer;
          if (data_index_xaxis2 >= 1) begin
            data_index_xaxis2 <= data_index_xaxis2 - 1;
            data_xaxis2_valid <= 0;
          end else begin
            data_index_xaxis2 <= 31;
            data_xaxis2_valid <= 1;
          end
        end
      end

      // Process for bit4
      if (mode_bit4 == MODE_WAIT_START) begin
        if (bit4) begin
          mode_bit4 <= MODE_WAIT_CHANNEL;
        end
      end else if (mode_bit4 == MODE_WAIT_CHANNEL) begin
        channel_bit4 <= bit4;
        mode_bit4 <= MODE_WAIT_DATA;
        bit4_data_buffer_index <= 15;
      end else if (mode_bit4 == MODE_WAIT_DATA) begin
        bit4_data_buffer[bit4_data_buffer_index] <= bit4;
        if (bit4_data_buffer_index >= 1) begin
          bit4_data_buffer_index <= bit4_data_buffer_index - 1;
        end else begin
          mode_bit4 <= MODE_ASSIGN_DATA;
        end
      end else if (mode_bit4 == MODE_ASSIGN_DATA) begin
        mode_bit4 <= MODE_WAIT_START;
        if (channel_bit4 == 0) begin // xaxis adc3 (95-64)
          data_xaxis[64 + data_index_xaxis3] <= bit4_data_buffer;
          if (data_index_xaxis3 >= 1) begin
            data_index_xaxis3 <= data_index_xaxis3 - 1;
            data_xaxis3_valid <= 0;
          end else begin
            data_index_xaxis3 <= 31;
            data_xaxis3_valid = 1;
          end
        end else begin // xaxis adc4 (127-96)
          data_xaxis[96 + data_index_xaxis4] <= bit4_data_buffer;
          if (data_index_xaxis4 >= 1) begin
            data_index_xaxis4 <= data_index_xaxis4 - 1;
            data_xaxis4_valid <= 0;
          end else begin
            data_index_xaxis4 <= 31;
            data_xaxis4_valid <= 1;
          end
        end
      end
    end
  end

  assign out_data_yaxis = data_yaxis[read_index_yaxis];
  assign out_data_xaxis = data_xaxis[read_index_xaxis];
  assign data_yaxis_valid = (data_yaxis1_valid && data_yaxis2_valid && data_yaxis3_valid && data_yaxis4_valid);
  assign data_xaxis_valid = (data_xaxis1_valid && data_xaxis2_valid && data_xaxis3_valid && data_xaxis4_valid);
  assign finished = (data_yaxis_valid && data_xaxis_valid);
endmodule
