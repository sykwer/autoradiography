module slave_fpga(
  clk, reset, start_lower_adc, start_upper_adc, serial_data_out,
  lower_adc_error, upper_adc_error,
  SMT_MD, PDZ, NAPZ, ENTRI, INTUPZ, PGA,
  SCLK0, CNVST0, RD0, CS0, RESET0, OB2C0, PD0, RDERROR0, BUSY0,
  SCLK1, CNVST1, RD1, CS1, RESET1, OB2C1, PD1, RDERROR1, BUSY1,
);
  // Digital port
  input clk, reset;
  input start_lower_adc, start_upper_adc;
  output serial_data_out;

  // Error notification (LED)
  output lower_adc_error, upper_adc_error;

  // Readout configuration
  output SMT_MD, PDZ, NAPZ, ENTRI, INTUPZ;
  output [2:0] PGA;

  // Lowwer ADC
  output SCLK0, CNVST0, RD0, CS0, RESET0, OB2C0, PD0;
  input RDERROR0, BUSY0;

  // Upper ADC
  output SCLK1, CNVST1, RD1, CS1, RESET1, OB2C1, PD1;
  input RDERROR1, BUSY1;

  // Intermediate wires
  wire [15:0] lower_adc_data_wire, upper_adc_data_wire;
  wire lower_adc_data_enable_wire, upper_adc_data_enable_wire;

  ReadoutConfigurator readout_configurator(
    SMT_MD, PDZ, NAPZ, ENTRI, INTUPZ, PGA,
  );

  AdcController lower_adc_controller(
    clk, reset, start_lower_adc, lower_adc_data_enable_wire, lower_adc_error, lower_adc_data_wire,
    SCLK0, CNVST0, RD0, CS0, RESET0, OB2C0, PD0, RDOUT0, RDERROR0, BUSY0,
  );

  AdcController upper_adc_controller(
    clk, reset, start_upper_adc, upper_adc_data_enable_wire, upper_adc_error, upper_adc_data_wire,
    SCLK1, CNVST1, RD1, CS1, RESET1, OB2C1, PD1, RDOUT1, RDERROR1, BUSY1,
  );

  DataSerializer data_serializer(
    clk, reset, lower_adc_data_wire, upper_adc_data_wire, lower_adc_data_enable_wire,
    upper_adc_data_enable_wire, serial_data_out,
  );
endmodule
