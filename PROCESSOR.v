`default_nettype none
`timescale 1ns/100ps
`include "INST.v"

module PROCESSOR (
  input   wire          clk,
  input   wire          rst,
  output  reg [32-1:0]  led
);

localparam IF = 0, IG = 1, ID = 2, EX = 3, MM = 4, WA = 5, WB = 6;

reg [32-1:0]  pc[IF:WB],  pc4[IG:WB], btpc[MM:WB]; // pc, pc+4, branch target pc
reg [32-1:0]  ir[ID:WB];
wire[32-1:0]  ir_ig;
reg [16-1:0]  immi[EX:WB];  // immediate for I format
reg [26-1:0]  immj[EX:WB];  // immediate for J format
reg [32-1:0]  rrs[EX:WB], rrt[EX:WB], rslt[WA:WB];
reg           rwe[EX:WB];   // register write enable
reg           mld[EX:WB], mwe[EX:WB];   // dmem load / dmem write enable
reg           valid[IG:WB];
reg [33-1:0]  bpred[ID:WB]; // {valid (1bit), target_pc (32bit)}
wire[33-1:0]  bact_wa;      // actual branch condition
reg           bmiss_wa;

integer i;
always @(posedge clk) begin
  for (i = ID; i <= WB; i = i + 1)  pc[i]     <= rst ? 0 : pc[i-1];
  for (i = ID; i <= WB; i = i + 1)  pc4[i]    <= rst ? 0 : pc4[i-1];
  for (i = WA; i <= WB; i = i + 1)  btpc[i]   <= rst ? 0 : btpc[i-1];
  for (i = MM; i <= WB; i = i + 1)  ir[i]     <= rst ? 0 : ir[i-1];
  for (i = MM; i <= WB; i = i + 1)  immi[i]   <= rst ? 0 : immi[i-1];
  for (i = MM; i <= WB; i = i + 1)  immj[i]   <= rst ? 0 : immj[i-1];
  for (i = WA; i <= WB; i = i + 1)  rrs[i]    <= rst ? 0 : rrs[i-1];
  for (i = WA; i <= WB; i = i + 1)  rrt[i]    <= rst ? 0 : rrt[i-1];
  for (i = WB; i <= WB; i = i + 1)  rslt[i]   <= rst ? 0 : rslt[i-1];
  for (i = MM; i <= WB; i = i + 1)  rwe[i]    <= rst ? 0 : rwe[i-1];
  for (i = MM; i <= WB; i = i + 1)  mld[i]    <= rst ? 0 : mld[i-1];
  for (i = MM; i <= WB; i = i + 1)  mwe[i]    <= rst ? 0 : mwe[i-1];
  for (i = WA; i <= WB; i = i + 1)  valid[i]  <= rst ? 0 : valid[i-1];
  for (i = EX; i <= WB; i = i + 1)  bpred[i]  <= rst ? 0 : bpred[i-1];
end

wire[ 6-1:0]  opcode[IG:WB], funct[IG:WB];
wire[ 5-1:0]  rs[IG:WB],  rt[IG:WB],  rd[IG:WB];
wire[ 5-1:0]  shamt[IG:WB];
generate genvar gi;
  for (gi = IG; gi <= WB; gi = gi + 1)
    assign {opcode[gi], rs[gi], rt[gi], rd[gi], shamt[gi], funct[gi]} =
      gi==IG ? ir_ig : ir[gi];
endgenerate


// IF ------------------------------------------------------------
wire[32-1:0]  pc4_if = pc[IF]+4;
wire[33-1:0]  bpred_ig;
always @(posedge clk) begin
  pc[IF] <=
    rst           ? 0                 :
    bmiss_wa      ? bact_wa[0+:32]    :
    bpred_ig[32]  ? bpred_ig[0+:32]   :
                    pc4_if;
end

MEM #(
  .WIDTH(32),
  .WORD(4096)
) imem (
  .clk(clk),            .rst(rst),
  .addr({2'b0, pc[IF][2+:30]}),
  .out(ir_ig),  .in(0),   .we(1'b0)
);

always @(posedge clk) begin
  pc[IG]    <= rst ? 0 : pc[IF];
  pc4[IG]   <= rst ? 0 : pc[IF]+4;

  // Invalidate instruction on failing branch prediction.
  valid[IG] <= !bmiss_wa;
  valid[ID] <= !bmiss_wa & valid[IG];
  valid[EX] <= !bmiss_wa & valid[ID];
  valid[MM] <= !bmiss_wa & valid[EX];
end

// TODO: add tag to use pc[3+:] , pc[4+:] instead of pc[2+:]
localparam                      BTB_PC_WIDTH = 10;
localparam[32-BTB_PC_WIDTH-1:0] BTB_DUMMYZERO= 0;
MEM_2R1W #(
  .WIDTH(1+32), // valid + PC
  .WORD(2**BTB_PC_WIDTH)
) btb (
  .clk(clk),  .rst(rst),
  .addr0({BTB_DUMMYZERO, pc[WA][2+:BTB_PC_WIDTH]}),
  .in0(bact_wa),
  .we0(bmiss_wa),
  .out0(),
// HACK: 2+:BTB_PC_WIDTH assumes consecutive branch instruction. 4 is also OK.
  .addr1({BTB_DUMMYZERO, pc[IF][2+:BTB_PC_WIDTH]}),
  .out1(bpred_ig)
);


// IG ------------------------------------------------------------
always @(posedge clk) begin
  bpred[ID] <= rst ? 0 : bpred_ig;
  ir[ID]    <= rst ? 0 : ir_ig;
end


// ID ------------------------------------------------------------
wire[32-1:0]  w_rrs, w_rrt, w_rrd;
// w_rrd is forwarded to w_rr[st] in GPR
GPR regfile (
  .clk(clk),    .rst(rst),
  .rs(rs[ID]),  .rt(rt[ID]),  .rrs(w_rrs),  .rrt(w_rrt),
  .rd(rd[WB]),  .rrd(w_rrd),  .we(rwe[WB]&&valid[WB])
);

wire[32-1:0]  rslt_mm, w_rrd_wa;
always @(posedge clk) begin
  // 1st forwarding
  // rwe includes rd!=0
  rrs[EX] <=
    rst                                     ? 0         : // $0
    rs[ID]==rd[WA] && rwe[WA] && valid[WA]  ? w_rrd_wa  : // result in WA
    rs[ID]==rd[MM] && rwe[MM] && valid[MM]  ? rslt_mm   : // alu result in MM
                                              w_rrs;
  rrt[EX] <=
    rst                                     ? 0         : // $0
    rt[ID]==rd[WA] && rwe[WA] && valid[WA]  ? w_rrd_wa  : //
    rt[ID]==rd[MM] && rwe[MM] && valid[MM]  ? rslt_mm   : // alu result in MM
                                              w_rrt;
  immi[EX] <= ir[ID][0+:16];
  immj[EX] <= ir[ID][0+:26];
  // Fix register dstination if opcode was not R format.
  ir[EX] <= {
    ir[ID][31:16],
    opcode[ID]==`INST_R ? rd[ID] : rt[ID],
    ir[ID][10:0]
  };
  // reg/mem read/write flag.
  mld[EX]<= opcode[ID]==`INST_I_LW;
  mwe[EX]<= opcode[ID]==`INST_I_SW;
  rwe[EX]<= (opcode[ID]==`INST_R ? rd[ID]!=0 : rt[ID]!=0) &&
    opcode[ID]!=`INST_I_BEQ  &&
    opcode[ID]!=`INST_I_BNE  &&
    opcode[ID]!=`INST_I_SW   &&
    opcode[ID]!=`INST_J_J;
    //&& !(opcode_ex==`INST_R && funct_ex==`FUNCT_JR);
end

// Forward rd in MM in 2nd forwarding?
reg rsrd=0, rtrd=0;
always @(posedge clk) rsrd <= rs[ID]==rd[EX] && rwe[EX] && valid[EX];
always @(posedge clk) rtrd <= rt[ID]==rd[EX] && rwe[EX] && valid[EX];


// EX ------------------------------------------------------------
// 2nd forwarding
wire[32-1:0]  rrs_fwd =
    rsrd /*&&~mld[MM]*/ ?   rslt_mm   : // alu result in MM
                            rrs[EX];
wire[32-1:0]  rrt_fwd =
    rtrd /*&&~mld[MM]*/ ?   rslt_mm   : // alu result
                            rrt[EX];
ALU alu (
  .clk(clk),  .rst(rst),
  .opcode_fwd(opcode[ID]),  .opcode(opcode[EX]),
  .rrs(rrs_fwd),  .rrt_in(rrt_fwd),   .imm(immi[EX]),
  .funct_fwd(funct[ID]),  .funct(funct[EX]),
  .shamt_in(shamt[EX]),
  .rslt(rslt_mm)
);

always @(posedge clk) rrs[MM] <= rst ? 0 :rrs_fwd; // update
always @(posedge clk) rrt[MM] <= rst ? 0 :rrt_fwd;

wire[32-1:0]  branch_addr = {{14{immi[EX][15]}}, immi[EX], 2'b0} + pc4[EX];
wire[32-1:0]  jump_addr   = {pc[EX][31:28],      immj[EX], 2'b0};
//assign      jal =   //jump and link
//  opcode[EX] == `INST_J_JAL ||
// (opcode[EX] == `INST_R && funct[EX] == `FUNCT_JALR);
//assign      jr  =   //jump register
//  opcode[EX] == `INST_R && (funct[EX] == `FUNCT_JR || funct[EX] == `FUNCT_JALR);
reg   opj=0, opbeq=0, opbne=0;
always @(posedge clk) begin
  btpc[MM] <=  // branch target
    //opcode[EX]==`INST_J_JAL ||
    opcode[EX]==`INST_J_J   ? jump_addr   :
    //jr                      ? rrs_fwd_ex  :
                              branch_addr;
  opj   <= opcode[EX]==`INST_J_J;
  opbeq <= opcode[EX]==`INST_I_BEQ;
  opbne <= opcode[EX]==`INST_I_BNE;
end

always @(posedge clk) begin
  if(((rs[EX]==rd[MM] || rt[EX]==rd[MM]) && mld[MM] && valid[MM]) ||
     ((rs[EX]==rd[WA] || rt[EX]==rd[WA]) && mld[WA] && valid[WA])) begin
    // needs data forwarding from memory && not ready
    $display("Not supported: kuso zako compiler");
    $finish();
  end
end

// MM ------------------------------------------------------------
wire[32-1:0]  ldd_wa;
MEM #(
  .WIDTH(32),
  .WORD(4096)
) dmem (
  .clk(clk),    .rst(rst),
  .addr({2'b0, rslt_mm[2+:30]}),
  .out(ldd_wa),  .in(rrt[MM]), .we(mwe[MM]&&valid[MM])
);
always @(posedge clk) rslt[WA]  <= rst ? 0 : rslt_mm;

// Check branch prediction
wire  btaken = // Is actual condition taken?
  //jal || jr ||
  opj                         ||
  (opbeq && rrs[MM]==rrt[MM]) ||
  (opbne && rrs[MM]!=rrt[MM]);
reg   branch_wa=0, btaken_wa=0;
always @(posedge clk) begin
  if(rst) begin
    bmiss_wa  <= 0;
  end else if(bpred[MM][32]) begin
    // pred was valid
    // miss if (actual target) != (predicted target)
    bmiss_wa  <= valid[MM] && (
      btaken ? btpc[MM]!=bpred[MM][0+:32] : pc4[MM]!=bpred[MM][0+:32]);
  end else begin
    // pred was not valid: always untaken && (predicted target) == pc4
    // miss if taken
    bmiss_wa  <= valid[MM] && (btaken);
  end
  btaken_wa <= rst ? 0 : btaken;
  branch_wa <= rst ? 0 : opj || opbeq || opbne;
end

// WA ------------------------------------------------------------
reg [32-1:0]  rrd_wa = 0;
assign  w_rrd_wa= mld[WA] ? ldd_wa : rslt[WA];
always @(posedge clk) rrd_wa <= rst ? 0 : w_rrd_wa;

assign  bact_wa = {branch_wa, btaken_wa ? btpc[WA] : pc4[WA]};

// WB ------------------------------------------------------------
assign  w_rrd   = rrd_wa;

// misc ----------------------------------------------------------
always @(posedge clk) led <= rslt[WA];

endmodule

