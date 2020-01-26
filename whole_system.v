module whole_system(
  clk, CLK_USB, TXT_N, RXF_N, OE_N, RD_N, WR_N, DATA, BE,
  adc_y1_error, adc_y2_error, adc_y3_error, adc_y4_error,
  adc_x1_error, adc_x2_error, adc_x3_error, adc_x4_error,
);
  output clk;

  input CLK_USB, TXT_N, RXF_N;
  output OE_N, RD_N, WR_N;
  inout [15:0] DATA;
  inout [1:0] BE;

  output adc_y1_error, adc_y2_error, adc_y3_error, adc_y4_error;
  output adc_x1_error, adc_x2_error, adc_x3_error, adc_x4_error;

  wire clk_wire, reset_wire;
  wire start_adc1_wire, start_adc2_wire, start_adc3_wire, start_adc4_wire;
  wire serial_data1_wire, serial_data3_wire, serial_data4_wire;

  wire INTG, IRST, SHS, SHR, STI, CLK_READOUT;
  wire SMT_MD, PDZ, NAPZ, ENTRI, INTUPZ;
  wire [2:0] PGA;

  wire SCLK_Y1, CNVST_Y1, RD_Y1, CS_Y1, RESET_Y1, OB2C_Y1, PD_Y1, SDOUT_Y1, RDERROR_Y1, BUSY_Y1;
  wire SCLK_Y2, CNVST_Y2, RD_Y2, CS_Y2, RESET_Y2, OB2C_Y2, PD_Y2, SDOUT_Y2, RDERROR_Y2, BUSY_Y2;
  wire SCLK_Y3, CNVST_Y3, RD_Y3, CS_Y3, RESET_Y3, OB2C_Y3, PD_Y3, SDOUT_Y3, RDERROR_Y3, BUSY_Y3;
  wire SCLK_Y4, CNVST_Y4, RD_Y4, CS_Y4, RESET_Y4, OB2C_Y4, PD_Y4, SDOUT_Y4, RDERROR_Y4, BUSY_Y4;
  wire SCLK_X1, CNVST_X1, RD_X1, CS_X1, RESET_X1, OB2C_X1, PD_X1, SDOUT_X1, RDERROR_X1, BUSY_X1;
  wire SCLK_X2, CNVST_X2, RD_X2, CS_X2, RESET_X2, OB2C_X2, PD_X2, SDOUT_X2, RDERROR_X2, BUSY_X2;
  wire SCLK_X3, CNVST_X3, RD_X3, CS_X3, RESET_X3, OB2C_X3, PD_X3, SDOUT_X3, RDERROR_X3, BUSY_X3;
  wire SCLK_X4, CNVST_X4, RD_X4, CS_X4, RESET_X4, OB2C_X4, PD_X4, SDOUT_X4, RDERROR_X4, BUSY_X4;

  // Node1 from here
  SlaveFPGA fpga1(
    clk_wire, reset_wire, start_adc1_wire, start_adc2_wire, serial_data1_wire,
    adc_y1_error, adc_y2_error,
    SMT_MD, PDZ, NAPZ, ENTRI, INTUPZ, PGA,
    SCLK_Y1, CNVST_Y1, RD_Y1, CS_Y1, RESET_Y1, OB2C_Y1, PD_Y1, SDOUT_Y1, RDERROR_Y1, BUSY_Y1,
    SCLK_Y2, CNVST_Y2, RD_Y2, CS_Y2, RESET_Y2, OB2C_Y2, PD_Y2, SDOUT_Y2, RDERROR_Y2, BUSY_Y2,
  );

  Ad7673Stub adc_y1(
    SCLK_Y1, CNVST_Y1, RD_Y1, CS_Y1, RESET_Y1, OB2C_Y1, PD_Y1, SDOUT_Y1, RDERROR_Y1, BUSY_Y1,
  );

  Ad7673Stub adc_y2(
    SCLK_Y2, CNVST_Y2, RD_Y2, CS_Y2, RESET_Y2, OB2C_Y2, PD_Y2, SDOUT_Y2, RDERROR_Y2, BUSY_Y2,
  );
  // Node1 to here

  // Node2 from here
  MasterFPGA fpga2(
    clk, clk_wire, reset_wire,
    start_adc1_wire, start_adc2_wire, start_adc3_wire, start_adc4_wire,
    serial_data1_wire, serial_data3_wire, serial_data4_wire,
    adc_y4_error, adc_y3_error,
    SCLK_Y3, CNVST_Y3, RD_Y3, CS_Y3, RESET_Y3, OB2C_Y3, PD_Y3, SDOUT_Y3, RDERROR_Y3, BUSY_Y3,
    SCLK_Y4, CNVST_Y4, RD_Y4, CS_Y4, RESET_Y4, OB2C_Y4, PD_Y4, SDOUT_Y4, RDERROR_Y4, BUSY_Y4,
    INTG, IRST, SHS, SHR, STI, CLK_READOUT,
    CLK_USB, TXE_N, RXF_N, OE_N, RD_N, WR_N, DATA, BE,
  );

  Ad7673Stub adc_y3(
    SCLK_Y3, CNVST_Y3, RD_Y3, CS_Y3, RESET_Y3, OB2C_Y3, PD_Y3, SDOUT_Y3, RDERROR_Y3, BUSY_Y3,
  );

  Ad7673Stub adc_y4(
    SCLK_Y4, CNVST_Y4, RD_Y4, CS_Y4, RESET_Y4, OB2C_Y4, PD_Y4, SDOUT_Y4, RDERROR_Y4, BUSY_Y4,
  );
  // Node2 to here

  // Node3 from here
  wire smt_md3, pdz3, napz3, entri3, intupz3;
  wire [2:0] pga3;
  SlaveFPGA fpga3(
    clk_wire, reset_wire, start_adc1_wire, start_adc2_wire, serial_data3_wire,
    adc_y1_error, adc_y2_error,
    smt_md3, pdz3, napz3, entri3, intupz3, pga3,
    SCLK_X1, CNVST_X1, RD_X1, CS_X1, RESET_X1, OB2C_X1, PD_X1, SDOUT_X1, RDERROR_X1, BUSY_X1,
    SCLK_X2, CNVST_X2, RD_X2, CS_X2, RESET_X2, OB2C_X2, PD_X2, SDOUT_X2, RDERROR_X2, BUSY_X2,
  );

  Ad7673Stub adc_x1(
    SCLK_X1, CNVST_X1, RD_X1, CS_X1, RESET_X1, OB2C_X1, PD_X1, SDOUT_X1, RDERROR_X1, BUSY_X1,
  );

  Ad7673Stub adc_x2(
    SCLK_X2, CNVST_X2, RD_X2, CS_X2, RESET_X2, OB2C_X2, PD_X2, SDOUT_X2, RDERROR_X2, BUSY_X2,
  );
  // Node3 to here

  // Node4 from here
  wire smt_md4, pdz4, napz4, entri4, intupz4;
  wire [2:0] pga4;
  SlaveFPGA fpga4(
    clk_wire, reset_wire, start_adc3_wire, start_adc4_wire, serial_data4_wire,
    adc_y3_error, adc_y4_error,
    smt_md4, pdz4, napz4, entri4, intupz4, pga4,
    SCLK_X3, CNVST_X3, RD_X3, CS_X3, RESET_X3, OB2C_X3, PD_X3, SDOUT_X3, RDERROR_X3, BUSY_X3,
    SCLK_X4, CNVST_X4, RD_X4, CS_X4, RESET_X4, OB2C_X4, PD_X4, SDOUT_X4, RDERROR_X4, BUSY_X4,
  );

  Ad7673Stub adc_x3(
    SCLK_X3, CNVST_X3, RD_X3, CS_X3, RESET_X3, OB2C_X3, PD_X3, SDOUT_X3, RDERROR_X3, BUSY_X3,
  );

  Ad7673Stub adc_x4(
    SCLK_X4, CNVST_X4, RD_X4, CS_X4, RESET_X4, OB2C_X4, PD_X4, SDOUT_X4, RDERROR_X4, BUSY_X4,
  );
  // Node4 to here

  ReadoutStub readout(
    INTG, IRST, SHS, SHR, STI, CLK_READOUT,
    SMT_MD, PDZ, NAPZ, ENTRI, INTUPZ, PGA,
  );
endmodule
