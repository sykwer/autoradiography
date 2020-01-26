module ReadoutConfigurator(
           SMT_MD, PDZ, NAPZ, ENTRI, INTUPZ, PGA,
       );
output SMT_MD, PDZ, NAPZ, ENTRI, INTUPZ;
output [2:0] PGA;

assign SMT_MD = 0; // Sequential mode
assign PDZ = 1; // active low
assign NAPZ = 1; // active low
// TODO: Add explanation
assign ENTRI = 0; // ???
assign INTUPZ = 0; // ???
assign PGA = 3; // ???
endmodule
