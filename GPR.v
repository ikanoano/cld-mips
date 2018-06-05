`default_nettype none
`timescale 1ns/100ps

// 32bitx32 2R/1W General Purpose Registers (Register File)
module GPR(
  input   wire              clk,
  input   wire              rst,
  input   wire[    5-1:0]   rs,
  input   wire[    5-1:0]   rt,
  output  wire[   32-1:0]   rrs,
  output  wire[   32-1:0]   rrt,

  input   wire[    5-1:0]   rd,
  input   wire[   32-1:0]   rrd,
  input   wire              we
);


reg [31:0]  r[0:31];

assign rrs = r[rs];
assign rrt = r[rt];

always @(posedge clk) begin
  if(we) r[rd] <= rrd;
end

integer i;
initial for (i = 0; i < 32; i = i + 1) r[i] = 0;
always @(posedge clk) if(rd==0 && we) begin
  $display("assertion failed: $0 must be 0");
  $finish();
end

endmodule
