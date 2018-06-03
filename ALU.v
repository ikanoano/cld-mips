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

localparam[4-1:0]
  SEL_ADD =  0,
  SEL_SUB =  1,
  SEL_AND =  2,
  SEL_OR  =  3,
  SEL_XOR =  4,
  SEL_NOR =  5,
  SEL_SLL =  6,
  SEL_SRL =  7,
  SEL_SRA =  8,
  SEL_SLT =  9,
  SEL_SLTU= 10;

wire[32-1:0]  imm_s     = {{16{imm[15]}}, imm};
wire[32-1:0]  imm_z     = {{16{   1'b0}}, imm};
wire[32-1:0]  rrt       =
  opcode==`INST_R     ? rrt_in :
//opcode==`INST_I_LB    ||
//opcode==`INST_I_LH    ||
  opcode==`INST_I_ANDI  ||
  opcode==`INST_I_ORI   ||
  opcode==`INST_I_XORI  ? imm_z :
                          imm_s;

reg [32-1:0]  rslt_add, rslt_sub, rslt_and, rslt_or, rslt_xor,
              rslt_sll, rslt_srl, rslt_sra, rslt_slt, rslt_sltu;

wire[ 3-1:0]  shamt = shamt_in[0+:3];
reg [ 4-1:0]  rslt_sel=0;
always @(posedge clk) begin
  rslt_add    <= rst ? 0 : rrs + rrt;
  rslt_sub    <= rst ? 0 : rrs - rrt;
  rslt_and    <= rst ? 0 : rrs & rrt;
  rslt_or     <= rst ? 0 : rrs | rrt;
  rslt_xor    <= rst ? 0 : rrs ^ rrt;
  rslt_sll    <= rst ? 0 : rrt << shamt;
  rslt_srl    <= rst ? 0 : rrt >> shamt;
//rslt_sra    <= rst ? 0 : $signed(rrt) >>> shamt_in;
  rslt_slt    <= rst ? 0 : $signed(rrs) < $signed(rrt) ? 32'b1 : 32'b0;
  rslt_sltu   <= rst ? 0 :         rrs  <         rrt  ? 32'b1 : 32'b0;
  rslt_sel    <=
    opcode==`INST_I_ADDI  ||
    opcode==`INST_I_ADDIU                     ? SEL_ADD :
    opcode==`INST_I_ANDI                      ? SEL_AND :
    opcode==`INST_I_ORI                       ? SEL_OR  :
    opcode==`INST_I_XORI                      ? SEL_XOR :
    opcode==`INST_I_SLTI                      ? SEL_SLT :
    opcode==`INST_I_SLTIU                     ? SEL_SLTU:
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
    opcode==`INST_R && funct==`FUNCT_AND      ? SEL_AND :
    opcode==`INST_R && funct==`FUNCT_OR       ? SEL_OR  :
    opcode==`INST_R && funct==`FUNCT_XOR      ? SEL_XOR :
    opcode==`INST_R && funct==`FUNCT_NOR      ? SEL_NOR :
    opcode==`INST_R && funct==`FUNCT_SLL      ? SEL_SLL :
    opcode==`INST_R && funct==`FUNCT_SRL      ? SEL_SRL :
//  opcode==`INST_R && funct==`FUNCT_SRA      ? SEL_SRA :
//  opcode==`INST_R && funct==`FUNCT_SLLV     ? SEL_SLL :
//  opcode==`INST_R && funct==`FUNCT_SRLV     ? SEL_SRL :
//  opcode==`INST_R && funct==`FUNCT_SRAV     ? SEL_SRA :
    opcode==`INST_R && funct==`FUNCT_SLT      ? SEL_SLT :
    opcode==`INST_R && funct==`FUNCT_SLTU     ? SEL_SLTU:
                                                4'hX;

end

assign  rslt =
  rslt_sel==SEL_ADD   ? rslt_add :
  rslt_sel==SEL_SUB   ? rslt_sub :
  rslt_sel==SEL_AND   ? rslt_and :
  rslt_sel==SEL_OR    ? rslt_or  :
  rslt_sel==SEL_XOR   ? rslt_xor :
  rslt_sel==SEL_NOR   ? ~rslt_or :
  rslt_sel==SEL_SLL   ? rslt_sll :
  rslt_sel==SEL_SRL   ? rslt_srl :
//rslt_sel==SEL_SRA   ? rslt_sra :
  rslt_sel==SEL_SLT   ? rslt_slt :
  rslt_sel==SEL_SLTU  ? rslt_sltu:
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
