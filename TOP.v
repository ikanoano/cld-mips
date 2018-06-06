`default_nettype none
`timescale 1ns/100ps
  
// Top module for simulation
module TOP();
reg clk=0, rst=1;

initial begin
  clk = 0;
  #50
  forever #50 clk = ~clk;
end

integer cycle;
initial begin
  rst = 1;
  #520;
  $display("deassert reset");
  rst = 0;
  cycle = 0;
end
always @(posedge clk) begin
  cycle <= cycle + 1;
end

initial begin
  $dumpfile("/tmp/wave.vcd");
  $dumpvars(0, p);
end

integer nopcnt = 0;
integer i;
always @(posedge clk) begin
  //r[8] == $t0
  #10
  $write("pc=%x ir=%x :\n", {p.pc[1],2'h0}, p.ir_ig);
  for(i=0; i<32; i=i+1) begin
    $write("%x,", p.regfile.r[i]);
    if((i+1)%8==0) $write("\n");
  end

  if(!rst && p.ir_ig==32'h0)  nopcnt = nopcnt + 1;
  else                        nopcnt = 0;

  if(nopcnt >= 6) begin
    $display("");
    $display("halt!");
    $display("cycle = %d", cycle);
    $display("\ndmem:");
    for(i=0; i<16; i=i+1) begin
      $write("%x,", p.dmem.mem[i]);
      if((i+1)%8==0) $write("\n");
    end
    $finish();
  end
  if(cycle>10000000) begin
    $display("");
    $display("Cycle limit exceeded! Abort..");
    $finish();
  end
end

wire[32-1:0] dummy;
PROCESSOR p(
  .clk(clk), .rst(rst), .led(dummy));
endmodule

