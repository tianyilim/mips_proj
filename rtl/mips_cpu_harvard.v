module mips_cpu_harvard(
    /* Standard signals */
    input logic clk,
    input logic reset,
    output logic active,
    output logic[31:0] register_v0,

    output logic[3:0] byteenable,
    output logic[31:0]  instr_address,
    input logic[31:0]   instr_readdata,

    output logic[31:0]  data_address,
    output logic        data_write,
    output logic        data_read,
    output logic[31:0]  data_writedata,
    input logic[31:0]  data_readdata
);

// IF
logic[31:0] pc, pc_next;
logic[31:0] instr, instr_addr;

//Decode
logic[15:0] imm;
logic[4:0] rs_addr, rt_addr, rd_addr, shift;
logic[5:0] fn_code;
logic[5:0] opcode;
logic[n:0] alu_op;
logic[25:0] jump_addr;

//Execute
logic[31:0] Hi, Lo;




assign pc_next = pc + 8;
