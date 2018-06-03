`define INST_R          6'h00

`define INST_I_ADDI     6'h08
`define INST_I_ADDIU    6'h09
`define INST_I_ANDI     6'h0C
`define INST_I_ORI      6'h0D
`define INST_I_XORI     6'h0E

`define INST_I_SLTI     6'h0A
`define INST_I_SLTIU    6'h0B

`define INST_I_BEQ      6'h04
`define INST_I_BNE      6'h05

`define INST_J_J        6'h02
//`define INST_J_JAL      6'h03

//`define INST_I_LB       6'h20
//`define INST_I_LH       6'h21
//`define INST_I_LBU      6'h24
//`define INST_I_LHU      6'h25
//`define INST_I_LUI      6'h0f
`define INST_I_LW       6'h23

//`define INST_I_SB       6'h28
//`define INST_I_SH       6'h29
`define INST_I_SW       6'h2B


`define FUNCT_ADD       6'h20
`define FUNCT_ADDU      6'h21
`define FUNCT_SUB       6'h22
`define FUNCT_SUBU      6'h23
`define FUNCT_AND       6'h24
`define FUNCT_OR        6'h25
`define FUNCT_XOR       6'h26
`define FUNCT_NOR       6'h27
`define FUNCT_SLT       6'h2A
`define FUNCT_SLTU      6'h2B

`define FUNCT_SLL       6'h00
`define FUNCT_SRL       6'h02
`define FUNCT_SRA       6'h03
`define FUNCT_SLLV      6'h04
`define FUNCT_SRLV      6'h06
`define FUNCT_SRAV      6'h07

//`define FUNCT_JR        6'h08
//`define FUNCT_JALR      6'h09
