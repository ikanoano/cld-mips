`default_nettype none
`timescale 1ns/100ps
`include "INST.v"

module PROCESSOR (
  input   wire          clk,
  input   wire          rst,
  output  reg [32-1:0]  led
);

localparam IF = 0, ID = 1, EX = 2, MM = 3, WB = 4;

reg [32-1:0]  pc[IF:WB],  pc4[ID:WB], btpc[MM:WB]; // pc, pc+4, branch target pc
reg [32-1:0]  ir[EX:WB];
wire[32-1:0]  ir_id;
reg [16-1:0]  immi[EX:WB];  // immediate for I format
reg [26-1:0]  immj[EX:WB];  // immediate for J format
reg [32-1:0]  rrs[EX:WB], rrt[EX:WB], rslt[WB:WB];
reg           rwe[EX:WB];   // register write enable
reg           mld[EX:WB], mwe[EX:WB];   // dmem load / dmem write enable
reg           valid[ID:WB];
reg [33-1:0]  bpred[EX:WB]; // {pred_taken (1bit), target_pc (32bit)}
wire[33-1:0]  bact_wb;      // actual branch condition
reg           bmiss_wb;

integer i;
always @(posedge clk) begin
  for (i = EX; i <= WB; i = i + 1)  pc[i]     <= rst ? 0 : pc[i-1];
  for (i = EX; i <= WB; i = i + 1)  pc4[i]    <= rst ? 0 : pc4[i-1];
  for (i = WB; i <= WB; i = i + 1)  btpc[i]   <= rst ? 0 : btpc[i-1];
  for (i = MM; i <= WB; i = i + 1)  ir[i]     <= rst ? 0 : ir[i-1];
  for (i = MM; i <= WB; i = i + 1)  immi[i]   <= rst ? 0 : immi[i-1];
  for (i = MM; i <= WB; i = i + 1)  immj[i]   <= rst ? 0 : immj[i-1];
  for (i = WB; i <= WB; i = i + 1)  rrs[i]    <= rst ? 0 : rrs[i-1];
  for (i = WB; i <= WB; i = i + 1)  rrt[i]    <= rst ? 0 : rrt[i-1];
  for (i = MM; i <= WB; i = i + 1)  rwe[i]    <= rst ? 0 : valid[i-1]&rwe[i-1];
  for (i = MM; i <= WB; i = i + 1)  mld[i]    <= rst ? 0 : valid[i-1]&mld[i-1];
  for (i = MM; i <= WB; i = i + 1)  mwe[i]    <= rst ? 0 : valid[i-1]&mwe[i-1];
  for (i = WB; i <= WB; i = i + 1)  valid[i]  <= rst ? 0 : valid[i-1];
  for (i = MM; i <= WB; i = i + 1)  bpred[i]  <= rst ? 0 : bpred[i-1];
end

wire[ 6-1:0]  opcode[ID:WB], funct[ID:WB];
wire[ 5-1:0]  rs[ID:WB],  rt[ID:WB],  rd[ID:WB];
wire[ 5-1:0]  shamt[ID:WB];
generate genvar gi;
  assign {opcode[ID], rs[ID], rt[ID], rd[ID], shamt[ID], funct[ID]} = ir_id;
  for (gi = EX; gi <= WB; gi = gi + 1) begin
    assign {opcode[gi], rs[gi], rt[gi], rd[gi], shamt[gi], funct[gi]} = ir[gi];
  end
endgenerate
// IF ------------------------------------------------------------
wire[32-1:0]  pc4_if = pc[IF]+4;
wire[33-1:0]  bpred_id;
always @(posedge clk) begin
  pc[IF] <=
    rst           ? 0                 :
    bmiss_wb      ? bact_wb[0+:32]    :
    bpred_id[32]  ? bpred_id[0+:32]  :
                    pc4_if;
end

MEM #(
  .WIDTH(32),
  .WORD(4096)
) imem (
  .clk(clk),            .rst(rst),
  .addr({2'b0, pc[IF][2+:30]}),
  .out(ir_id),  .in(0),   .we(1'b0)
);

always @(posedge clk) begin
  pc[ID]    <= pc[IF];
  pc4[ID]   <= pc[IF]+4;

  // Invalidate instruction on failing branch prediction.
  valid[ID] <= !bmiss_wb;
  valid[EX] <= !bmiss_wb & valid[ID];
  valid[MM] <= !bmiss_wb & valid[EX];
end

// TODO: add tag to use pc[3+:] , pc[4+:] instead of pc[2+:]
localparam                      BTB_PC_WIDTH = 10;
localparam[32-BTB_PC_WIDTH-1:0] BTB_DUMMYZERO= 0;
MEM_2R1W #(
  .WIDTH(1+32), // valid + PC
  .WORD(2**BTB_PC_WIDTH)
) btb (
  .clk(clk),  .rst(rst),
  .addr0({BTB_DUMMYZERO, pc[WB][2+:BTB_PC_WIDTH]}),
  .in0(bact_wb),
  .we0(bmiss_wb),
  .out0(),
// HACK: 2+:BTB_PC_WIDTH assumes consecutive branch instruction. 4 is also OK.
  .addr1({BTB_DUMMYZERO, pc[IF][2+:BTB_PC_WIDTH]}),
  .out1(bpred_id)
);


// ID ------------------------------------------------------------
wire[32-1:0]  w_rrs, w_rrt, w_rrd;
// w_rrd is forwarded to w_rr[st] in GPR
GPR regfile (
  .clk(clk),    .rst(rst),
  .rs(rs[ID]),  .rt(rt[ID]),  .rrs(w_rrs),  .rrt(w_rrt),
  .rd(rd[WB]),  .rrd(w_rrd),  .we(rwe[WB]&&valid[WB])
);

wire[32-1:0]  rslt_mm;
always @(posedge clk) begin
  // 1st forwarding
  // rwe includes rd!=0
  rrs[EX] <=
    rst                                     ? 0         : // $0
    rs[ID]==rd[MM] && rwe[MM] && valid[MM]  ? rslt_mm   : // alu result in MM
                                              w_rrs;
  rrt[EX] <=
    rst                                     ? 0         : // $0
    rt[ID]==rd[MM] && rwe[MM] && valid[MM]  ? rslt_mm   : // alu result in MM
                                              w_rrt;
  immi[EX] = ir_id[0+:16];
  immj[EX] = ir_id[0+:26];
  // Fix register dstination if opcode was not R format.
  ir[EX] <= {
    ir_id[31:16],
    opcode[ID]==`INST_R ? rd[ID] : rt[ID],
    ir_id[10:0]
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

  bpred[EX] <= rst ? 0 : bpred_id;
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
     ((rs[EX]==rd[WB] || rt[EX]==rd[WB]) && mld[WB] && valid[WB])) begin
    // needs data forwarding from memory && not ready
    $display("Not supported: kuso zako compiler");
    $finish();
  end
end

// MM ------------------------------------------------------------
wire[32-1:0]  ldd_wb;
MEM #(
  .WIDTH(32),
  .WORD(4096)
) dmem (
  .clk(clk),    .rst(rst),
  .addr({2'b0, rslt_mm[2+:30]}),
  .out(ldd_wb),  .in(rrt[MM]), .we(mwe[MM]&&valid[MM])
);
always @(posedge clk) rslt[WB]  <= rst ? 0 : rslt_mm;

// Check branch prediction
wire  btaken = // Is actual condition taken?
  //jal || jr ||
  opj                         ||
  (opbeq && rrs[MM]==rrt[MM]) ||
  (opbne && rrs[MM]!=rrt[MM]);
reg   btaken_wb=0;
always @(posedge clk) begin
  if(rst) begin
    bmiss_wb  <= 0;
  end else if(bpred[MM][32]) begin
    // pred was taken
    bmiss_wb  <= valid[MM] && (!btaken || btpc[MM]!=bpred[MM][0+:32]);
  end else begin
    // pred was untaken
    bmiss_wb  <= valid[MM] && (btaken);
  end
  btaken_wb <= rst ? 0 : btaken;
end

// WB ------------------------------------------------------------
assign  w_rrd   = mld[WB] ? ldd_wb : rslt[WB];
assign  bact_wb = {btaken_wb, btaken_wb ? btpc[WB] : pc4[WB]};

// misc ----------------------------------------------------------
always @(posedge clk) led <= rslt[WB];

endmodule

