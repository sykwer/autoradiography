module Ad7673Stub(
  SCLK, CNVST, RD, CS, RESET, OB2C, PD, SDOUT, RDERROR, BUSY,
);
  input SCLK, CNVST, RD, CS, RESET, OB2C, PD;
  output SDOUT, RDERROR, BUSY;
  reg data;

  always @(negedge SCLK) begin
    data <= !data;
  end

  assign SDOUT = data;
endmodule
