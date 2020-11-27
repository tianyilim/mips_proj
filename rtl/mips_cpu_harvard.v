module mips_cpu_harvard(
    /* Standard signals */
    input logic clk,
    input logic clk_enable,
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

    typedef enum logic[1:0] {
        FETCH = 2'b00,
        EXEC1 = 2'b01,
        EXEC2 = 2'b10
    } state_t;
    typedef enum logic[1:0] {
        R = 2'b00,
        I = 2'b01,
        J = 2'b10
    } instr_type_t;
    typedef enum logic[5:0] {
        ADDU = 6'b100001,
        EXEC1 = 2'b01,
        EXEC2 = 2'b10
    } function_t;

    logic [1:0] state;
    logic [1:0] instr_type;

    //Control Logic
    logic[31:0] pc, pc_next;

    //Decoding of instruction
    logic[15:0] imm;
    logic[4:0] rs_addr, rt_addr, rd_addr, shift;
    logic[5:0] fn_code;
    logic[5:0] opcode;
    logic[25:0] jump_addr;

    //Execute
    logic[31:0] Hi, Lo;
    logic[31:0] rs_data, rt_data;

    //Control assignments
    assign pc_next = pc + 4;

    //Decode assignments
    assign opcode = instr_readdata[31:26];
    assign instr_type = (opcode = 6'b000000) ? R : (opcode[5:1] = 5'b00001)? J : I;
    assign rs_addr = instr_readdata[25:21];
    assign rt_addr = instr_readdata[20:16];
    assign rd_addr = instr_readdata[15:11];
    assign shift = instr_readdata[10:6];
    assign fn_code = instr_readdata[5:0];
    assign imm = instr_readdata[15:0];
    assign jump_addr = instr_readdata[25:0];


endmodule
