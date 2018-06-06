`default_nettype none
`timescale 1ns/100ps
`include "INST.v"

module ALU (
  input   wire          clk,
  input   wire          rst,
  input   wire[ 6-1:0]  opcode_fwd,
  input   wire[ 6-1:0]  opcode,
  input   wire[32-1:0]  rrs,
  input   wire[32-1:0]  rrt_in,
  input   wire[16-1:0]  imm,
  input   wire[ 6-1:0]  funct_fwd,
  input   wire[ 6-1:0]  funct,
  input   wire[ 5-1:0]  shamt_in,
  output  wire[32-1:0]  rslt
);

localparam[2-1:0]
  RRT_RRT =  0,
  RRT_IMMZ=  2,
  RRT_IMMS=  3;
reg [2-1:0] rrt_sel=0;
always @(posedge clk) rrt_sel <=
  opcode_fwd==`INST_R       ? RRT_RRT   :
//opcode_fwd==`INST_I_LB    ||
//opcode_fwd==`INST_I_LH    ||
  opcode_fwd==`INST_I_ANDI  ||
  opcode_fwd==`INST_I_ORI   ||
  opcode_fwd==`INST_I_XORI  ? RRT_IMMZ  :
                              RRT_IMMS;

localparam[2-1:0]
  LOGI_AND=  0,
  LOGI_OR =  1,
  LOGI_XOR=  2,
  LOGI_NOR=  3;
reg [2-1:0] logi_sel=0;
always @(posedge clk) logi_sel <=
  opcode_fwd==`INST_I_ANDI                  ||
  opcode_fwd==`INST_R && funct_fwd==`FUNCT_AND  ? LOGI_AND  :
  opcode_fwd==`INST_I_ORI                   ||
  opcode_fwd==`INST_R && funct_fwd==`FUNCT_OR   ? LOGI_OR   :
  opcode_fwd==`INST_I_XORI                  ||
  opcode_fwd==`INST_R && funct_fwd==`FUNCT_XOR  ? LOGI_XOR  :
  opcode_fwd==`INST_R && funct_fwd==`FUNCT_NOR  ? LOGI_NOR  :
                                                  2'hX;

localparam[3-1:0]
  SEL_LOGI=  0,
  SEL_ADD =  1,
  SEL_SUB =  2,
  SEL_SLL =  3,
  SEL_SRL =  4,
  SEL_SLT =  5,
  SEL_LI  =  6;
wire[32-1:0]  imm_s     = {{16{imm[15]}}, imm};
wire[32-1:0]  imm_z     = {{16{   1'b0}}, imm};
wire[32-1:0]  rrt       =
  rrt_sel==RRT_RRT  ? rrt_in  :
  rrt_sel==RRT_IMMZ ? imm_z   :
  rrt_sel==RRT_IMMS ? imm_s   :
                      32'hXXXX;

reg [32-1:0]  rslt_add, rslt_sub, rslt_logi, rslt_li,
              rslt_sll, rslt_srl, rslt_sra, rslt_slt, rslt_sltu;

wire[ 3-1:0]  shamt = shamt_in[0+:3];
reg [ 3-1:0]  rslt_sel=0;
always @(posedge clk) begin
  rslt_logi <=
    rst                 ?   0         :
    logi_sel==LOGI_AND  ?   rrs & rrt :
    logi_sel==LOGI_OR   ?   rrs | rrt :
    logi_sel==LOGI_XOR  ?   rrs ^ rrt :
    logi_sel==LOGI_NOR  ? ~(rrs | rrt):
                            32'hXXXX;
  rslt_li   <=
    rst                 ?   0         :
                            {imm, 16'b0}; // load upper immediate

  rslt_add    <= rst ? 0 : rrs + rrt;
  rslt_sub    <= rst ? 0 : rrs - rrt_in;
  rslt_sll    <= rst ? 0 : rrt_in << shamt;
  rslt_srl    <= rst ? 0 : rrt_in >> shamt;
//rslt_sra    <= rst ? 0 : $signed(rrt_in) >>> shamt_in;
  // NOTE: "rrt_in" in slt(u) should be "rrt" if slti or sltu exists.
  rslt_slt    <= rst ? 0 : $signed(rrs) < $signed(rrt_in) ? 32'b1 : 32'b0;
  rslt_sltu   <= rst ? 0 :         rrs  <         rrt_in  ? 32'b1 : 32'b0;
  rslt_sel    <=
    opcode==`INST_I_ADDI  ||
    opcode==`INST_I_ADDIU                     ? SEL_ADD :
    opcode==`INST_I_ANDI                      ? SEL_LOGI :
    opcode==`INST_I_ORI                       ? SEL_LOGI :
    opcode==`INST_I_XORI                      ? SEL_LOGI :
    opcode==`INST_I_SLTI                      ? SEL_SLT :
//  opcode==`INST_I_SLTIU                     ? SEL_SLTU:
    opcode==`INST_I_LUI                       ? SEL_LI  :
//  opcode==`INST_I_LB    ||
//  opcode==`INST_I_LH    ||
//  opcode==`INST_I_LBU   ||
//  opcode==`INST_I_LHU   ||
    opcode==`INST_I_LW    ||
//  opcode==`INST_I_SB    ||
//  opcode==`INST_I_SH    ||
    opcode==`INST_I_SW                        ? SEL_ADD :
    opcode==`INST_R && funct==`FUNCT_ADD  ||
    opcode==`INST_R && funct==`FUNCT_ADDU     ? SEL_ADD :
    opcode==`INST_R && funct==`FUNCT_SUB  ||
    opcode==`INST_R && funct==`FUNCT_SUBU     ? SEL_SUB :
    opcode==`INST_R && funct==`FUNCT_AND      ? SEL_LOGI :
    opcode==`INST_R && funct==`FUNCT_OR       ? SEL_LOGI :
    opcode==`INST_R && funct==`FUNCT_XOR      ? SEL_LOGI :
    opcode==`INST_R && funct==`FUNCT_NOR      ? SEL_LOGI :
    opcode==`INST_R && funct==`FUNCT_SLL      ? SEL_SLL :
    opcode==`INST_R && funct==`FUNCT_SRL      ? SEL_SRL :
//  opcode==`INST_R && funct==`FUNCT_SRA      ? SEL_SRA :
//  opcode==`INST_R && funct==`FUNCT_SLLV     ? SEL_SLL :
//  opcode==`INST_R && funct==`FUNCT_SRLV     ? SEL_SRL :
//  opcode==`INST_R && funct==`FUNCT_SRAV     ? SEL_SRA :
    opcode==`INST_R && funct==`FUNCT_SLT      ? SEL_SLT :
//  opcode==`INST_R && funct==`FUNCT_SLTU     ? SEL_SLTU:
                                                3'hX;
end

assign  rslt =
  rslt_sel==SEL_LOGI  ? rslt_logi:
  rslt_sel==SEL_ADD   ? rslt_add :
  rslt_sel==SEL_SUB   ? rslt_sub :
  rslt_sel==SEL_SLL   ? rslt_sll :
  rslt_sel==SEL_SRL   ? rslt_srl :
//rslt_sel==SEL_SRA   ? rslt_sra :
  rslt_sel==SEL_SLT   ? rslt_slt :
//rslt_sel==SEL_SLTU  ? rslt_sltu:
  rslt_sel==SEL_LI    ? rslt_li  :
                        32'hXXXX;

reg [5-1:0] last_shamt=0;
always @(posedge clk) begin
  last_shamt <= shamt_in;
  if((rslt_sel==SEL_SLL||rslt_sel==SEL_SRL) && last_shamt[4:3]!=0) begin
    $display("Not suported: shamt >= 8 .");
    $finish();
  end
end

endmodule
