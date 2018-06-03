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

reg [32-1:0]  rslt_add, rslt_sub, rslt_and, rslt_or, rslt_xor, rslt_nor,
              rslt_sll, rslt_srl, rslt_sra, rslt_slt, rslt_sltu;

reg [ 6-1:0]  r_opcode=0, r_funct=0;
always @(posedge clk) begin
  r_opcode    <= rst ? 0 : opcode;
  r_funct     <= rst ? 0 : funct;
  rslt_add    <= rst ? 0 : rrs + rrt;
  rslt_sub    <= rst ? 0 : rrs - rrt;
  rslt_and    <= rst ? 0 : rrs & rrt;
  rslt_or     <= rst ? 0 : rrs | rrt;
  rslt_xor    <= rst ? 0 : rrs ^ rrt;
  rslt_nor    <= rst ? 0 : ~(rrs | rrt);
  rslt_sll    <= rst ? 0 : rrt << shamt;
  rslt_srl    <= rst ? 0 : rrt >> shamt;
  rslt_sra    <= rst ? 0 : $signed(rrt) >>>shamt;
  rslt_slt    <= rst ? 0 : $signed(rrs) < $signed(rrt) ? 32'b1 : 32'b0;
  rslt_sltu   <= rst ? 0 :         rrs  <         rrt  ? 32'b1 : 32'b0;
end

assign  rslt =
  r_opcode==`INST_I_ADDI  ||
  r_opcode==`INST_I_ADDIU                       ? rslt_add :
  r_opcode==`INST_I_ANDI                        ? rslt_and :
  r_opcode==`INST_I_ORI                         ? rslt_or  :
  r_opcode==`INST_I_XORI                        ? rslt_xor :
  r_opcode==`INST_I_SLTI                        ? rslt_slt :
  r_opcode==`INST_I_SLTIU                       ? rslt_sltu:
  r_opcode==`INST_I_LB    ||
  r_opcode==`INST_I_LH    ||
  r_opcode==`INST_I_LBU   ||
  r_opcode==`INST_I_LHU   ||
  r_opcode==`INST_I_LW    ||
//r_opcode==`INST_I_SB    ||
//r_opcode==`INST_I_SH    ||
  r_opcode==`INST_I_SW                          ? rslt_add :
  r_opcode==`INST_R && r_funct==`FUNCT_ADD  ||
  r_opcode==`INST_R && r_funct==`FUNCT_ADDU     ? rslt_add :
  r_opcode==`INST_R && r_funct==`FUNCT_SUB  ||
  r_opcode==`INST_R && r_funct==`FUNCT_SUBU     ? rslt_sub :
  r_opcode==`INST_R && r_funct==`FUNCT_AND      ? rslt_and :
  r_opcode==`INST_R && r_funct==`FUNCT_OR       ? rslt_or  :
  r_opcode==`INST_R && r_funct==`FUNCT_XOR      ? rslt_xor :
  r_opcode==`INST_R && r_funct==`FUNCT_NOR      ? rslt_nor :
  r_opcode==`INST_R && r_funct==`FUNCT_SLL      ? rslt_sll :
  r_opcode==`INST_R && r_funct==`FUNCT_SRL      ? rslt_srl :
  r_opcode==`INST_R && r_funct==`FUNCT_SRA      ? rslt_sra :
  r_opcode==`INST_R && r_funct==`FUNCT_SLLV     ? rslt_sll :
  r_opcode==`INST_R && r_funct==`FUNCT_SRLV     ? rslt_srl :
  r_opcode==`INST_R && r_funct==`FUNCT_SRAV     ? rslt_sra :
  r_opcode==`INST_R && r_funct==`FUNCT_SLT      ? rslt_slt :
  r_opcode==`INST_R && r_funct==`FUNCT_SLTU     ? rslt_sltu: 32'hXXXX;

endmodule
