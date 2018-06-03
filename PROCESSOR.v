`default_nettype none
`timescale 1ns/100ps
`include "INST.v"

module PROCESSOR (
  input   wire          clk,
  input   wire          rst,
  output  reg [32-1:0]  led
);

localparam IF = 0, ID = 1, EX = 2, MM = 3, WB = 4;

reg [32-1:0]  pc[IF:WB],  pc4[ID:WB], btpc[EX:WB]; // pc, pc+4, branch target pc
reg [ 6-1:0]  opcode[ID:WB], funct[ID:WB];
reg [ 5-1:0]  rs[ID:WB],  rt[ID:WB],  rd[ID:WB];
reg [ 5-1:0]  shamt[ID:WB];
reg [16-1:0]  immi[ID:WB];  // immediate for I format
reg [26-1:0]  immj[ID:WB];  // immediate for J format
reg [32-1:0]  rrs[EX:WB], rrt[EX:WB], rslt[WB:WB], ldd[WB:WB];
reg           rwe[EX:WB];   // register write enable
reg           mld[EX:WB], mwe[EX:WB];   // dmem load / dmem write enable
reg           valid[ID:WB];
wire          btaken;

integer i;
always @(posedge clk) begin
  for (i = EX; i <= WB; i = i + 1)  pc[i]     <= rst ? 0 : pc[i-1];
  for (i = EX; i <= WB; i = i + 1)  pc4[i]    <= rst ? 0 : pc4[i-1];
  for (i = MM; i <= WB; i = i + 1)  btpc[i]   <= rst ? 0 : btpc[i-1];
  for (i = EX; i <= WB; i = i + 1)  opcode[i] <= rst ? 0 : opcode[i-1];
  for (i = EX; i <= WB; i = i + 1)  funct[i]  <= rst ? 0 : funct[i-1];
  for (i = EX; i <= WB; i = i + 1)  rs[i]     <= rst ? 0 : rs[i-1];
  for (i = EX; i <= WB; i = i + 1)  rt[i]     <= rst ? 0 : rt[i-1];
  for (i = MM; i <= WB; i = i + 1)  rd[i]     <= rst ? 0 : rd[i-1];
  for (i = EX; i <= WB; i = i + 1)  shamt[i]  <= rst ? 0 : shamt[i-1];
  for (i = EX; i <= WB; i = i + 1)  immi[i]   <= rst ? 0 : immi[i-1];
  for (i = EX; i <= WB; i = i + 1)  immj[i]   <= rst ? 0 : immj[i-1];
  for (i = WB; i <= WB; i = i + 1)  rrs[i]    <= rst ? 0 : rrs[i-1];
  for (i = WB; i <= WB; i = i + 1)  rrt[i]    <= rst ? 0 : rrt[i-1];
//for (i = WB; i <= WB; i = i + 1)  ldd[i]    <= rst ? 0 : ldd[i-1];
  for (i = MM; i <= WB; i = i + 1)  rwe[i]    <= rst ? 0 : valid[i-1]&rwe[i-1];
  for (i = MM; i <= WB; i = i + 1)  mld[i]    <= rst ? 0 : valid[i-1]&mld[i-1];
  for (i = MM; i <= WB; i = i + 1)  mwe[i]    <= rst ? 0 : valid[i-1]&mwe[i-1];
  for (i = EX; i <= WB; i = i + 1)  valid[i]  <= rst ? 0 : valid[i-1];
end

// IF ------------------------------------------------------------
always @(posedge clk) begin
  pc[IF] <=
    rst         ? 0         :
    btaken      ? btpc[EX]  :
                  pc[IF]+4;
end

wire[32-1:0]  ir;
MEM #(
  .WIDTH(32),
  .WORD(4096)
) imem (
  .clk(clk),            .rst(rst),
  .addr({2'b0, pc[IF][2+:30]}),
  .out(ir),   .in(0),   .we(1'b0)
);

always @(posedge clk) begin
  pc[ID]    <= pc[IF];
  pc4[ID]   <= pc[IF]+4;
  // R format
  {opcode[ID], rs[ID], rt[ID], rd[ID], shamt[ID], funct[ID]} <= ir;
  // I format
  immi[ID]  <= ir[16-1:0];
  // J format
  immj[ID]  <= ir[26-1:0];

  // Invalidate instruction on failing branch prediction.
  valid[ID] <= !btaken;
end


// ID ------------------------------------------------------------
wire[32-1:0]  w_rrs, w_rrt, w_rrd;
// w_rrd is forwarded to w_rr[st] in GPR
GPR regfile (
  .clk(clk),    .rst(rst),
  .rs(rs[ID]),  .rt(rt[ID]),  .rrs(w_rrs),  .rrt(w_rrt),
  .rd(rd[WB]),  .rrd(w_rrd),  .we(rwe[WB])
);

wire[32-1:0]  rslt_mm;
always @(posedge clk) begin
  // 1st forwarding
  // rwe includes valid && rd!=0
  rrs[EX] <=
    rst                                   ? 0         : // $0
    rs[ID]==rd[MM] && rwe[MM]             ? rslt_mm   : // alu result in MM
                                            w_rrs;
  rrt[EX] <=
    rst                                   ? 0         : // $0
    rt[ID]==rd[MM] && rwe[MM]             ? rslt_mm   : // alu result in MM
                                            w_rrt;
  // Fix register dstination if opcode was not R format.
  rd[EX] <= opcode[ID]==`INST_R ? rd[ID] : rt[ID];
  mld[EX]<= valid[ID] && opcode[ID]==`INST_I_LW;
  mwe[EX]<= valid[ID] && opcode[ID]==`INST_I_SW;
  rwe[EX]<= valid[ID] && (opcode[ID]==`INST_R ? rd[ID]!=0 : rt[ID]!=0) &&
    opcode[ID]!=`INST_I_BEQ  &&
    opcode[ID]!=`INST_I_BNE  &&
    opcode[ID]!=`INST_I_SW   &&
    opcode[ID]!=`INST_J_J;
    //&& !(opcode_ex==`INST_R && funct_ex==`FUNCT_JR);

  if(((rs[ID]==rd[EX] || rt[ID]==rd[EX]) && mld[EX]) ||
     ((rs[ID]==rd[MM] || rt[ID]==rd[MM]) && mld[EX])) begin
    // needs data forwarding from memory && not ready
    $display("Not supported: kuso zako compiler");
    $finish();
  end
end

wire[32-1:0]  branch_addr = {{14{immi[ID][15]}}, immi[ID], 2'b0} + pc4[ID];
wire[32-1:0]  jump_addr   = {pc[ID][31:28],      immj[ID], 2'b0};
//assign      jal =   //jump and link
//  opcode[ID] == `INST_J_JAL ||
// (opcode[ID] == `INST_R && funct[ID] == `FUNCT_JALR);
//assign      jr  =   //jump register
//  opcode[ID] == `INST_R && (funct[ID] == `FUNCT_JR || funct[ID] == `FUNCT_JALR);
always @(posedge clk) begin
  btpc[EX] <=  // branch target
  //opcode[ID]==`INST_J_JAL ||
  opcode[ID]==`INST_J_J   ? jump_addr   :
  //jr                      ? rrs_fwd_ex  :
                            branch_addr;
end


// EX ------------------------------------------------------------
// 2nd forwarding
wire[32-1:0]  rrs_fwd =
    rs[EX]==rd[MM] && rwe[MM] /*~mld[MM]*/? rslt_mm   : // alu result in MM
                                            rrs[EX];
wire[32-1:0]  rrt_fwd =
    rt[EX]==rd[MM] && rwe[MM] /*~mld[MM]*/? rslt_mm   : // alu result
                                            rrt[EX];
ALU alu (
  .clk(clk),  .rst(rst),
  .opcode(opcode[EX]),
  .rrs(rrs_fwd),  .rrt_in(rrt_fwd),   .imm(immi[EX]),
  .funct(funct[EX]),  .shamt_in(shamt[EX]),
  .rslt(rslt_mm)
);

always @(posedge clk) rrs[MM] <= rst ? 0 :rrs_fwd; // update
always @(posedge clk) rrt[MM] <= rst ? 0 :rrt_fwd;

assign  btaken = // branch condition
  //jal || jr ||
  opcode[EX]==`INST_J_J                               ||
  opcode[EX]==`INST_I_BEQ && rrs_fwd[EX]==rrt_fwd[EX] ||
  opcode[EX]==`INST_I_BNE && rrs_fwd[EX]!=rrt_fwd[EX];


// MM ------------------------------------------------------------
wire[32-1:0]  w_ldd;
MEM #(
  .WIDTH(32),
  .WORD(4096)
) dmem (
  .clk(clk),    .rst(rst),
  .addr({2'b0, rslt_mm[2+:30]}),
  .out(w_ldd),  .in(rrt[MM]), .we(mwe[MM])
);
always @(posedge clk) ldd[WB]   <= rst ? 0 : w_ldd;
always @(posedge clk) rslt[WB]  <= rst ? 0 : rslt_mm;


// WB ------------------------------------------------------------
assign  w_rrd  = mld[WB] ? ldd[WB] : rslt[WB];


// misc ----------------------------------------------------------
always @(posedge clk) led <= rslt[WB];
integer j;
always @(posedge clk) begin
  for (j = EX; j <= WB; j = j + 1) begin
    if(!rst && rwe[j] && !valid[j]) $display("assertion failed: rwe");
    if(!rst && mld[j] && !valid[j]) $display("assertion failed: mld");
    if(!rst && mwe[j] && !valid[j]) $display("assertion failed: mwe");
  end
end

endmodule

