`default_nettype none
`timescale 1ns/100ps
`include "UTIL.v"

module MEM #(
  parameter WIDTH   = 32,
  parameter WORD    = 1024
) (
  input   wire              clk,
  input   wire              rst,
  input   wire[   32-1:0]   addr,
  input   wire[WIDTH-1:0]   in,
  input   wire              we,
  output  reg [WIDTH-1:0]   out
);

localparam  ADDR_WIDTH = `LOG2(WORD);
(* ram_style = "block" *)
reg [WIDTH-1:0]   mem[0:WORD-1];

always @(posedge clk) begin
  if(we)  mem[addr[0+:ADDR_WIDTH]] <= in;
  out <= mem[addr[0+:ADDR_WIDTH]];
end

integer i;
initial begin
  // Initialize with dummy value or mem will be eliminated by optimization.
  for (i = 0; i < WORD; i = i + 1) mem[i] = WORD-i;
  $readmemh("main.mem", mem, 0, WORD-1);
end

endmodule
