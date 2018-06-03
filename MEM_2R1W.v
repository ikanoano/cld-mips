`default_nettype none
`timescale 1ns/100ps
`include "UTIL.v"

module MEM_2R1W #(
  parameter WIDTH   = 32,
  parameter WORD    = 1024
) (
  input   wire              clk,
  input   wire              rst,
  input   wire[   32-1:0]   addr0,
  input   wire[WIDTH-1:0]   in0,
  input   wire              we0,
  output  wire[WIDTH-1:0]   out0,
  input   wire[   32-1:0]   addr1,
  output  wire[WIDTH-1:0]   out1
);

localparam  ADDR_WIDTH = `LOG2(WORD);
(* ram_style = "block" *)
reg [WIDTH-1:0]   mem[0:WORD-1];

always @(posedge clk) begin
  if(we0) mem[addr0[0+:ADDR_WIDTH]] <= in0;
end
assign  out0  = mem[addr0[0+:ADDR_WIDTH]];
assign  out1  = mem[addr1[0+:ADDR_WIDTH]];

integer i;
initial begin
  // Initialize with dummy value or mem will be eliminated by optimization.
  for (i = 0; i < WORD; i = i + 1) mem[i] = i | i<<16;
end

endmodule
