`default_nettype none
`timescale 1ns/100ps
`include "INST.v"

module ALU (
  input   wire          clk,
  input   wire          rst,
  input   wire[ 6-1:0]  opcode,
  input   wire[32-1:0]  rrs,
  input   wire[32-1:0]  rrt_in,
  input   wire[16-1:0]  imm,
  input   wire[ 6-1:0]  funct,
  input   wire[ 5-1:0]  shamt_in,
  output  wire[32-1:0]  rslt
);

wire[32-1:0]  imm_s     = {{16{imm[15]}}, imm};
wire[32-1:0]  imm_z     = {{16{   1'b0}}, imm};
wire[32-1:0]  rrt       =
  opcode==`INST_R     ? rrt_in :
  opcode==`INST_I_ANDI  ||
  opcode==`INST_I_ORI   ||
  opcode==`INST_I_XORI  ||
  opcode==`INST_I_LB    ||
  opcode==`INST_I_LH  ? imm_z :
                        imm_s;
wire[ 5-1:0]  shamt     = funct[2] ? rrs[4:0] : shamt_in;

wire[32-1:0]  rslt_add, rslt_sub, rslt_and, rslt_or, rslt_xor, rslt_nor,
              rslt_sll, rslt_srl, rslt_sra, rslt_slt, rslt_sltu;

assign  rslt_add    = rrs + rrt;
assign  rslt_sub    = rrs - rrt;
assign  rslt_and    = rrs & rrt;
assign  rslt_or     = rrs | rrt;
assign  rslt_xor    = rrs ^ rrt;
assign  rslt_nor    = ~(rrs | rrt);
assign  rslt_sll    = rrt << shamt;
assign  rslt_srl    = rrt >> shamt;
assign  rslt_sra    = $signed(rrt) >>>shamt;
assign  rslt_slt    = $signed(rrs) < $signed(rrt) ? 32'b1 : 32'b0;
assign  rslt_sltu   =         rrs  <         rrt  ? 32'b1 : 32'b0;

assign  rslt =
  opcode==`INST_I_ADDI  ||
  opcode==`INST_I_ADDIU                      ? rslt_add :
  opcode==`INST_I_ANDI                       ? rslt_and :
  opcode==`INST_I_ORI                        ? rslt_or  :
  opcode==`INST_I_XORI                       ? rslt_xor :
  opcode==`INST_I_SLTI                       ? rslt_slt :
  opcode==`INST_I_SLTIU                      ? rslt_sltu:
  opcode==`INST_I_LB    ||
  opcode==`INST_I_LH    ||
  opcode==`INST_I_LBU   ||
  opcode==`INST_I_LHU   ||
  opcode==`INST_I_LW    ||
//opcode==`INST_I_SB    ||
//opcode==`INST_I_SH    ||
  opcode==`INST_I_SW                         ? rslt_add :
  opcode==`INST_R && funct==`FUNCT_ADD  ||
  opcode==`INST_R && funct==`FUNCT_ADDU      ? rslt_add :
  opcode==`INST_R && funct==`FUNCT_SUB  ||
  opcode==`INST_R && funct==`FUNCT_SUBU      ? rslt_sub :
  opcode==`INST_R && funct==`FUNCT_AND       ? rslt_and :
  opcode==`INST_R && funct==`FUNCT_OR        ? rslt_or  :
  opcode==`INST_R && funct==`FUNCT_XOR       ? rslt_xor :
  opcode==`INST_R && funct==`FUNCT_NOR       ? rslt_nor :
  opcode==`INST_R && funct==`FUNCT_SLL       ? rslt_sll :
  opcode==`INST_R && funct==`FUNCT_SRL       ? rslt_srl :
  opcode==`INST_R && funct==`FUNCT_SRA       ? rslt_sra :
  opcode==`INST_R && funct==`FUNCT_SLLV      ? rslt_sll :
  opcode==`INST_R && funct==`FUNCT_SRLV      ? rslt_srl :
  opcode==`INST_R && funct==`FUNCT_SRAV      ? rslt_sra :
  opcode==`INST_R && funct==`FUNCT_SLT       ? rslt_slt :
  opcode==`INST_R && funct==`FUNCT_SLTU      ? rslt_sltu: 32'hXXXX;

endmodule
