module mips_cpu_harvard(
    /* Standard signals */
    input logic clk,
    input logic clk_enable,
    input logic rst,
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
    logic[4:0] rs_addr, rt_addr, rd_addr, shift, write_back_addr;
    logic[5:0] fn_code;
    logic[5:0] opcode;
    logic[25:0] jump_addr;

    //Execute
    logic[31:0] Hi, Lo;
    logic[31:0] rs_data, rt_data, write_back_data;
    logic[63:0] mult_div;
    logic jump;
    logic[31:0] jump_store;

    // signed extension logic
    logic[7:0] eight_bit;
    logic[15:0] sixteen_bit;
    logic[31:0] eight_extended;
    logic[31:0] sixteen_extended;

    assign eight_bit = (opcode == LB) ? data_readdata : 0;

    //Control assignments
    assign pc_next = pc + 4;
    assign instr_address = pc;

    /*
    To Do: Ask TianYi about instr_address
    Do signed extension
    Do data_write, data_read logic
    Divide module, mult_div
    Are we expected to do double jumps?
    */

    //Decode assignments
    assign opcode = instr_readdata[31:26];
    assign instr_type = (opcode = 6'b000000) ? R : (opcode[5:1] = 5'b00001)? J : I;

    assign rs_addr = instr_readdata[25:21];
    assign rt_addr = instr_readdata[20:16];
    assign rd_addr = instr_readdata[15:11];
    assign write_back_addr = (instr_type == R) ? rd_addr : rt_addr; // write back to register, as the dest reg is different for R type and I type
    assign shift = instr_readdata[10:6];

    assign fn_code = instr_readdata[5:0];
    assign imm = instr_readdata[15:0];
    assign jump_addr = instr_readdata[25:0];

    //Mem access assignmemts
    assign data_write =
    assign data_read =


    register_file regs(
        .clk(clk),
        .reset(rst),
        .rs_index(rs_addr), .rs_data(rs_data),
        .rt_index(rt_addr), .rt_data(rt_data),
        .rd_index(write_back_addr), .rd_data(write_back_data),
        .register_v0(register_v0),
        .write_enable(data_write)
    );

    eight_bit_extension eight(
        .x(eight_bit),
        .y(eight_extended)
    );
    sixteen_bit_extension sixteen(
        .x(sixteen_bit),
        .y(sixteen_extended)
    );


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
            state <= EXEC1;
        end
        //EXEC1
        else if(state == EXEC1) begin
            state <= EXEC2;
            //R instruction
            if(instr_type == R) begin
                case(fn_code) begin
                    ADDU: begin
                      write_back_data <= rs_data + rt_data;
                    end
                    AND: begin
                      write_back_data <= rs_data & rt_data;
                    end
                    DIV: begin// signed
                      mult_div <= $signed(rs_data)/$signed(rt_data);
                    end
                    DIVU: begin// unsigned
                      mult_div <= rs_data)/rt_data);
                    end
                    JALR: begin
                      write_back_data <= pc + 8;
                      jump_store <= rs_data;
                      jump <= 1;
                    end
                    JR: begin
                      jump_store <= rs_data;
                      jump <= 1;
                    end
                    MTHI: begin
                      Hi <= rs_data;
                    end
                    MTLO: begin
                      Lo <= rs_data;
                    end
                    MULT: begin// signed
                      mult_div <= $signed(rs_data)*$signed(rt_data);
                    end
                    MULTU: begin// unsigned
                      mult_div <= rs_data * rt_data;
                    end
                    OR: begin
                      write_back_data <= rs_data | rt_data;
                    end
                    SLL: begin
                      write_back_data <= rt_data << shift;
                    end
                    SLLV: begin
                      write_back_data <= rt_data << rs_data[4:0];
                    end
                    SLT: begin // signed
                      write_back_data <= ($signed(rs_data) < $signed(rt_data)) ? 1 : 0;
                    end
                    SLTU: begin // unsigned
                      write_back_data <= (rs_data < rt_data) ? 1 : 0;
                    end
                endcase
            end
            //I instruction
            else if(instr_type == I) begin
            end
            //should this be moved up?
            if(jump == 1) begin
                pc <= jump_store;
                jump <= 0;
            end
            else begin
                pc <= pc_next;
            end
        end
        //Exec2
        else if(state == EXEC2) begin
            state <= FETCH;
        //R instruction
            if(instr_type == R) begin
                case(fn_code) begin
                    DIV: begin
                      Hi <= mult_div[63:32];
                      Lo <= mult_div[31:0];
                    end
                    ADDU: begin
                      write_back_data <= rs_data + rt_data;
                      pc <= pc_next;
                    end
                    MULT: begin
                      Hi <= mult_div[63:32];
                      Lo <= mult_div[31:0];
                    end
                    MULTU: begin
                      Hi <= mult_div[63:32];
                      Lo <= mult_div[31:0];
                    end
                endcase
            end
            //I instruction
            else if(instr_type == I) begin
            end

        end



    end



endmodule
