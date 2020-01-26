module MasterFPGA(
  clk_in, clk_out, reset_out,
  start_adc1, start_adc2, start_adc3, start_adc4,
  serial_data1, serial_data3, serial_data4,
  lower_adc_error, upper_adc_error,
  INTG, IRST, SHS, SHR, STI, CLK_READOUT,
  SCLK0, CNVST0, RD0, CS0, RESET0, OB2C0, PD0, SDOUT0, RDERROR0, BUSY0,
  SCLK1, CNVST1, RD1, CS1, RESET1, OB2C1, PD1, SDOUT1, RDERROR1, BUSY1,
  CLK_USB, TXE_N, RXF_N, OE_N, RD_N, WR_N, DATA, BE,
);
  // Command enum
  localparam COMMAND_NOOP = 2'b00;
  localparam COMMAND_START = 2'b01;
  localparam COMMAND_STOP = 2'b10;

  // System clock
  input clk_in;

  // Digital port
  output clk_out, reset_out, start_adc1, start_adc2, start_adc3, start_adc4;
  input serial_data1, serial_data3, serial_data4;
  output INTG, IRST, SHS, SHR, STI, CLK_READOUT;

  // Lowwer ADC
  output SCLK0, CNVST0, RD0, CS0, RESET0, OB2C0, PD0;
  input SDOUT0, RDERROR0, BUSY0;

  // Upper ADC
  output SCLK1, CNVST1, RD1, CS1, RESET1, OB2C1, PD1;
  input SDOUT1, RDERROR1, BUSY1;

  // USB buffer
  input CLK_USB, TXE_N, RXF_N;
  output OE_N, RD_N, WR_N;
  inout [15:0] DATA;
  inout [1:0] BE;

  // Error notification (LED)
  output lower_adc_error, upper_adc_error;

  // While running, AFE keep reading the charge signal
  reg running;
  reg reset;
  reg [31:0] integration_clock_count;

  // Intermediate wires
  wire start_adc1_wire, start_adc2_wire, start_adc3_wire, start_adc4_wire;
  wire [15:0] lower_adc_data_wire, upper_adc_data_wire;
  wire lower_adc_data_enable_wire, upper_adc_data_enable_wire;
  wire serializer_out_bit_wire;
  wire serial_data2;
  wire [6:0] read_index_yaxis_wire, read_index_xaxis_wire;
  wire [15:0] data_yaxis_wire, data_xaxis_wire;
  wire data_aggregated_wire;
  wire [15:0] command_wire;
  wire [1:0] command_op_wire;
  wire [13:0] command_val_wire;

  ReadoutController readout_controller(
    clk_in, reset, running, integration_clock_count,
    start_adc1_wire, start_adc2_wire, start_adc3_wire, start_adc4_wire,
    INTG, IRST, SHS, SHR, STI, CLK_READOUT,
  );

  AdcController lower_adc_controller(
    clk_in, reset, start_adc3_wire, lower_adc_data_enable_wire, lower_adc_error, lower_adc_data_wire,
    SCLK0, CNVST0, RD0, CS0, RESET0, OB2C0, PD0, SDOUT0, RDERROR0, BUSY0,
  );

  AdcController upper_adc_controller(
    clk_in, reset, start_adc4_wire, upper_adc_data_enable_wire, upper_adc_error, upper_adc_data_wire,
    SCLK1, CNVST1, RD1, CS1, RESET1, OB2C1, PD1, SDOUT1, RDERROR1, BUSY1,
  );

  DataSerializer data_serializer(
    clk_in, reset, lower_adc_data_wire, upper_adc_data_wire, lower_adc_data_enable_wire,
    upper_adc_data_enable_wire, serializer_out_bit_wire,
  );

  DataAggregator data_aggregator(
    clk_in, reset, serial_data1, serial_data2, serial_data3, serial_data4,
    read_index_yaxis_wire, read_index_xaxis_wire, data_yaxis_wire, data_xaxis_wire,
    data_aggregated_wire,
  );

  UsbController usb_controller(
    clk_in, reset, data_yaxis_wire, data_xaxis_wire, data_aggregated_wire,
    read_index_yaxis_wire, read_index_xaxis_wire, command_wire,
    CLK_USB, TXE_N, RXF_N, OE_N, RD_N, WR_N, DATA, BE,
  );

  always @(posedge clk_in) begin
    if (reset) begin
      running <= 0;
      reset <= 0;
      integration_clock_count <= 5000; // enough large meaningless number
    end else begin
      if (command_op_wire == COMMAND_START) begin
        integration_clock_count <= (command_val_wire << 2);
        running <= 1;
      end else if (command_wire == COMMAND_STOP) begin
        running <= 0;
      end
    end
  end

  assign reset_out = reset;
  assign start_adc1 = start_adc1_wire;
  assign start_adc2 = start_adc2_wire;
  assign start_adc3 = start_adc3_wire;
  assign start_adc4 = start_adc4_wire;
  assign command_op_wire = command_wire[15:14];
  assign command_val_wire = command_wire[13:0];
endmodule
