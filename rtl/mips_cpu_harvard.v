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
        EXEC2 = 2'b10,
        HALTED = 2'b11
    } state_t;

    typedef enum logic[1:0] {
        R = 2'b00,
        I = 2'b01,
        J = 2'b10
    } instr_type_t;

    typedef enum logic[5:0] {
        ADDU = 6'b100001,
        AND = 6'b100100,
        DIV = 6'b011010,
        DIVU = 6'b011011,
        JALR = 6'b001001,
        JR = 6'001000,
        MTHI = 6'b010001,
        MTLO = 6'b010011,
        MULT = 6'b011000,
        MULTU = 6'b011001,
        OR = 6'b100101,
        SLL = 6'b000000,
        SLLV = 6'b000100,
        SLT = 6'b101010,
        SLTU = 6'b101011,
        SRA = 6'b000011,
        SRAV = 6'b000111,
        SRL = 6'b000010,
        SRLV = 6'b000110,
        SUBU = 6'b100011,
        XOR = 6'b100110,
        MFHI = 6'b010000,
        MFLO = 6'b010010
    } function_t;

    typedef enum logic[5:0] {
        ADDIU = 6'b001001,
        ANDI = 6'b001100,
        BEQ = 6'b000100,
        BRANCH = 6'b000001,//4 instructions have the same opcode, determined by Rd
        BGTZ = 6'b000111,
        BLEZ = 6'b000110,
        BNE = 6'b000101,
        LB = 6'b100000,
        LBU = 6'b100100,
        LH = 6'b100001,
        LHU = 6'b100101,
        LUI = 6'b001111,
        LW = 6'b100011,
        LWL = 6'b100010,
        LWR = 6'b100110,
        ORI = 6'b001101,
        SB = 6'b101000,
        SH = 6'b101001,
        SLTI = 6'b001010
        SLTIU = 6'b001011,
        SW = 6'b101011,
        XORI = 6'b001110,
        J = 6'b000010,
        JAL = 6'b000011
    } opcode_t;

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

    initial begin
        state = HALTED;
    end

    always @(posedge clk) begin
        if (!clk_enable) begin
        end
        else if (rst) begin
            state <= FETCH;
            pc <= 32'hBFC00000;
            active <= 1;
        end
        else if(state == FETCH) begin
            if(instr_readdata == 0) begin
              state <= HALTED;
              active <= 0;
            end



    end



endmodule
