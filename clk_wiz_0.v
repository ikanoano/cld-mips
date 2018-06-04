`default_nettype none
`timescale 1ns/100ps

//clk_wiz_0 clk_wiz (clk, w_rst, locked, w_clk);
module clk_wiz_0(
  output  wire  clk_out1,
  input   wire  reset,
  output  wire  locked,
  input   wire  clk_in1
);
  assign  clk_out1  = clk_in1;
  assign  locked    = ~reset;
endmodule
