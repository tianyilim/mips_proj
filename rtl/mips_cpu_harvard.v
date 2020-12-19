`timescale 1ns / 1ns
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
    output logic        instr_read,

    output logic[31:0]  data_address,
    output logic        data_write,
    output logic        data_read,
    output logic[31:0]  data_writedata,
    input logic[31:0]  data_readdata
);

    typedef enum logic[2:0] {
        FETCH = 3'b000,
        EXEC1 = 3'b001,
        EXEC2 = 3'b010,
        EXEC3 = 3'b011,
        HALTED = 3'b100,
        WAIT_RESET = 3'b101
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
        JR = 6'b001000,
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
        SLTI = 6'b001010,
        SLTIU = 6'b001011,
        SW = 6'b101011,
        XORI = 6'b001110,
        JUMP = 6'b000010,
        JAL = 6'b000011
    } opcode_t;

    logic [2:0] state;
    logic [1:0] instr_type;
    logic [31:0] instr, instr_reg;

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
    logic[63:0] mult_output; // multiplier output
    logic jump_check; // check whether the previous instruction was a jump
    logic[31:0] branch_delay_slot; // storing the address of a branch/jump for the next instr
    logic write_enable; //writing to register
    logic write_enable_r;
    logic write_enable_i_exec2;
    logic write_enable_i_exec3;
    logic[4:0] return_reg; // hold value of reg31
    logic[31:0] imm_base_addr; // hold value of base + imm


    //Control assignments
    assign pc_next = pc + 4;
    assign instr_address = pc;
    assign instr_read = (state == FETCH) ? 1 : 0;
    assign instr = ((state==EXEC2) || (state == EXEC3) ) ? instr_reg : instr_readdata;

    //Decode assignments
    assign opcode = instr[31:26];
    assign instr_type = (opcode == 6'b000000) ? R : ((opcode[5:1] == 5'b00001) ? J : I);

    assign rs_addr = instr[25:21];
    assign rt_addr = instr[20:16];
    assign rd_addr = instr[15:11];
    assign return_reg = 5'b11111;
    assign write_back_addr = (instr_type == R) ? rd_addr : ( ((opcode == BRANCH) ||  (opcode == JAL)) ? return_reg : rt_addr); // write back to register, as the dest reg is different for R type and I type, and for branch and link, return addr is reg31
    assign shift = instr[10:6];

    assign fn_code = instr[5:0];
    assign imm = instr[15:0];
    assign jump_addr = instr[25:0];
    assign imm_base_addr = rs_data + $signed(imm_signed_extended);

    assign write_enable_r =((state == EXEC2) && (instr_type == R) &&((fn_code == ADDU) ||
                                                                    (fn_code == AND) ||
                                                                    (fn_code == JALR) ||
                                                                    (fn_code == OR) ||
                                                                    (fn_code == SLL) ||
                                                                    (fn_code == SLLV) ||
                                                                    (fn_code == SLT) ||
                                                                    (fn_code == SLTU) ||
                                                                    (fn_code == SRA) ||
                                                                    (fn_code == SRAV) ||
                                                                    (fn_code == SRL) ||
                                                                    (fn_code == SRLV) ||
                                                                    (fn_code == SUBU) ||
                                                                    (fn_code == XOR) ||
                                                                    (fn_code == MFHI) ||
                                                                    (fn_code == MFLO))) ? 1 : 0;
    assign write_enable_i_exec2 =  ((state == EXEC2)  && ((opcode == ADDIU) ||
                                                           (opcode == ANDI) ||
                                                           (opcode == JAL) ||
                                                           (opcode == LUI) ||
                                                           (opcode == ORI) ||
                                                           (opcode == SLTI) ||
                                                           (opcode == SLTIU) ||
                                                           ((opcode == BRANCH) && (rt_addr == 5'b10000)) || // BLTZAL
                                                           ((opcode == BRANCH) && (rt_addr == 5'b10001)) || //BGEZAL
                                                           (opcode == XORI))) ? 1 : 0;
    assign write_enable_i_exec3 = ((state == EXEC3) && (instr_type == I) && ((opcode == LB)  ||
                                                                               (opcode == LBU) ||
                                                                               (opcode == LH)  ||
                                                                               (opcode == LHU) ||
                                                                               (opcode == LW)  ||
                                                                               (opcode == LWL) ||
                                                                               (opcode == LWR))) ? 1 : 0;
    assign write_enable = (write_enable_r == 1 || write_enable_i_exec3 == 1 || write_enable_i_exec2 == 1) ? 1 : 0;

    //Mem access assignmemts
    assign data_write = ((state == EXEC2) && (instr_type == I) && ((opcode == SB) || // EXEC1 used to update data_writedata and byteenable
                                                                   (opcode == SH) ||
                                                                   (opcode == SW))) ? 1 : 0;
    assign data_read = ((state == EXEC1) && (instr_type == I) && ((opcode == LB)  || // Loading of registers happens at EXEC3
                                                                  (opcode == LBU) ||
                                                                  (opcode == LH)  ||
                                                                  (opcode == LHU) ||
                                                                  (opcode == LW)  ||
                                                                  (opcode == LWL) ||
                                                                  (opcode == LWR))) ? 1 : 0;
    assign data_address = (data_write == 1 || data_read == 1) ? {imm_base_addr[31:2], 2'b00} : 0; //Only needed for load and store instructions
    
    
    // signed extension logic
    logic[15:0] sixteen_bit;
    logic[31:0] imm_signed_extended;
    assign sixteen_bit = ((instr_type == I) &&                    ((opcode == ADDIU) ||
                                                                   (opcode == BEQ) ||
                                                                   (opcode == BRANCH) ||
                                                                   (opcode == BGTZ) ||
                                                                   (opcode == BLEZ) ||
                                                                   (opcode == BNE) ||
                                                                   (opcode == LB) || // removed only high for EXEC1 because imm_base_addr uses extended imm in EXEC2
                                                                   (opcode == LBU) ||
                                                                   (opcode == LH) ||
                                                                   (opcode == LHU) ||
                                                                   (opcode == LW) ||
                                                                   (opcode == LWL) ||
                                                                   (opcode == LWR) ||
                                                                   (opcode == SB) ||
                                                                   (opcode == SH) ||
                                                                   (opcode == SLTI) ||
                                                                   (opcode == SLTIU) ||
                                                                   (opcode == SW))) ? imm : 0 ; //signed extension of the immediate field



    register_file regs(
        .clk(clk),
        .reset(rst),
        .rs_index(rs_addr), .rs_data(rs_data),
        .rt_index(rt_addr), .rt_data(rt_data),
        .rd_index(write_back_addr), .rd_data(write_back_data),
        .register_v0(register_v0),
        .write_enable(write_enable)
    );

    sixteen_bit_extension sixteen(
        .x(sixteen_bit),
        .y(imm_signed_extended)
    );



    initial begin
        state = HALTED;
        active = 0;
        data_writedata = 0;
        Hi = 0;
        Lo = 0;
        byteenable = 4'b1111;
    end

    always @(posedge clk) begin
        if (rst) begin
            $display("CPU : Resetting");
            state <= WAIT_RESET;
            pc <= 32'hBFC00000; // need to reset to bfc00000
            active <= 1;
        end
        else if (!clk_enable) begin // do nothing

        end
        else if(state == WAIT_RESET) begin
            state <= FETCH;
        end
        else if((state == FETCH) && (active == 1)) begin
            $display("CPU : FETCH : write_en = %d, instr = %h, instr_type =%b, pc = %h, register_v0 = %h", write_enable, instr, instr_type, pc, register_v0);
            if(pc == 0) begin
              state <= HALTED;
              active <= 0;
            end
            else begin
              state <= EXEC1;
            end
        end
        //EXEC1
        else if((state == EXEC1) && (active == 1)) begin
            $display("CPU : EXEC1 : write_en = %d, instr = %h, instr_type =%b, pc = %h, register_v0 = %h", write_enable, instr, instr_type, pc, register_v0);
            state <= EXEC2;
            instr_reg <= instr_readdata;
            //R instruction
            if(instr_type == R) begin
                case(fn_code)
                    ADDU: begin
                      write_back_data <= rs_data + rt_data;
                    end
                    AND: begin
                      write_back_data <= rs_data & rt_data;
                    end
                    DIV: begin// signed
                      Lo <= $signed(rs_data) / $signed(rt_data);
                      Hi <= $signed(rs_data) % $signed(rt_data);
                    end
                    DIVU: begin// unsigned
                      Lo <= rs_data / rt_data;
                      Hi <= rs_data % rt_data;
                    end
                    JALR: begin
                      if (jump_check == 1) begin
                        $fatal(2, "Branch in branch delay slot");
                      end
                      write_back_data <= pc + 8;
                      branch_delay_slot <= rs_data;
                      jump_check <= 1;
                    end
                    JR: begin
                      if (jump_check == 1) begin
                        $fatal(2, "Branch in branch delay slot");
                      end
                      branch_delay_slot <= rs_data;
                      jump_check <= 1;
                    end
                    MTHI: begin
                      Hi <= rs_data;
                    end
                    MTLO: begin
                      Lo <= rs_data;
                    end
                    MULT: begin// signed
                      mult_output <= $signed(rs_data)*$signed(rt_data);
                    end
                    MULTU: begin// unsigned
                      mult_output <= rs_data * rt_data;
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
                    SRA: begin //arithmetic shift
                      write_back_data <= ($signed(rt_data) >>> shift);
                    end
                    SRAV: begin
                      write_back_data <= $signed(rt_data) >>> rs_data[4:0];
                    end
                    SRL: begin
                      write_back_data <= rt_data >> shift;
                    end
                    SRLV: begin
                      write_back_data <= rt_data >> rs_data[4:0];
                    end
                    SUBU: begin // unsigned
                      write_back_data <= rs_data - rt_data;
                    end
                    XOR: begin
                      write_back_data <= rs_data ^ rt_data;
                    end
                    MFHI: begin
                      write_back_data <= Hi;
                    end
                    MFLO: begin
                      write_back_data <= Lo;
                    end
                endcase
            end
            //I instruction
            else if((instr_type == I) || (instr_type == J)) begin
                case(opcode)
                    ADDIU: begin // imm signed extended
                      write_back_data <= rs_data + imm_signed_extended ;
                    end
                    ANDI: begin // imm zero extended
                      write_back_data <= rs_data & {{16'h0000},imm} ;
                    end
                    BEQ: begin
                      if (jump_check == 1) begin
                        $fatal(2, "Branch in branch delay slot");
                      end
                      if (rs_data == rt_data) begin
                          branch_delay_slot <= pc_next + $signed(imm_signed_extended * 4);
                          jump_check <= 1;
                      end
                    end
                    BGTZ: begin
                      if (jump_check == 1) begin
                        $fatal(2, "Branch in branch delay slot");
                      end
                      if ($signed(rs_data) > 0) begin
                          branch_delay_slot <= pc_next + $signed(imm_signed_extended * 4);
                          jump_check <= 1;
                      end
                    end
                    BLEZ: begin
                      if (jump_check == 1) begin
                        $fatal(2, "Branch in branch delay slot");
                      end
                      if ($signed(rs_data) <= 0) begin
                          branch_delay_slot <= pc_next + $signed(imm_signed_extended * 4);
                          jump_check <= 1;
                      end
                    end
                    BRANCH: begin
                      case(rt_addr)
                          5'b00001: begin //BGEZ
                              if (jump_check == 1) begin
                                  $fatal(2, "Branch in branch delay slot");
                              end
                              if ($signed(rs_data) >= 0) begin
                                  branch_delay_slot <= pc_next + $signed(imm_signed_extended * 4);
                                  jump_check <= 1;
                              end
                          end
                          5'b10001: begin //BGEZAL
                              if (jump_check == 1) begin
                                  $fatal(2, "Branch in branch delay slot");
                              end
                              if ($signed(rs_data) >= 0) begin
                                  branch_delay_slot <= pc_next + $signed(imm_signed_extended * 4);
                                  jump_check <= 1;
                              end
                              write_back_data <= pc + 8;
                          end
                          5'b00000: begin // BLTZ
                              if (jump_check == 1) begin
                                  $fatal(2, "Branch in branch delay slot");
                              end
                              if ($signed(rs_data) < 0) begin
                                  branch_delay_slot <= pc_next + $signed(imm_signed_extended * 4);
                                  jump_check <= 1;
                              end
                          end
                          5'b10000: begin //BLTZAL
                              if (jump_check == 1) begin
                                  $fatal(2, "Branch in branch delay slot");
                              end
                              if ($signed(rs_data) < 0) begin
                                  branch_delay_slot <= pc_next + $signed(imm_signed_extended * 4);
                                  jump_check <= 1;
                              end
                              write_back_data <= pc + 8;
                          end

                      endcase
                    end
                    BNE: begin
                      if (jump_check == 1) begin
                        $fatal(2, "Branch in branch delay slot");
                      end
                      if (rs_data != rt_data) begin
                          branch_delay_slot <= pc_next + $signed(imm_signed_extended * 4);
                          jump_check <= 1;
                      end
                    end
                    LUI: begin
                      write_back_data <= {imm,16'h0000};
                    end
                    ORI: begin // imm zero extended
                      write_back_data <= rs_data | {{16'h0000},imm} ;
                    end
                    SB: begin
                        // state <= FETCH;
                        if(imm_base_addr[1:0] == 0) begin
                          data_writedata[7:0] <= rt_data[7:0];
                          byteenable <= 4'b0001;
                        end
                        else if(imm_base_addr[1:0] == 1) begin
                          data_writedata[15:8] <= rt_data[7:0];
                          byteenable <= 4'b0010;
                        end
                        else if(imm_base_addr[1:0] == 2) begin
                          data_writedata[23:16] <= rt_data[7:0];
                          byteenable <= 4'b0100;
                        end
                        else if(imm_base_addr[1:0] == 3) begin
                          data_writedata[31:24] <= rt_data[7:0];
                          byteenable <= 4'b1000;
                        end
                    end
                    SH: begin
                        // state <= FETCH;
                        
                        if(imm_base_addr[1:0] == 0) begin
                          data_writedata <= rt_data[15:0];
                          byteenable <= 4'b0011;
                        end
                        else if(imm_base_addr[1:0] == 2) begin
                          data_writedata[31:16] <= rt_data[15:0];
                          byteenable <= 4'b1100;
                        end
                        else begin
                          $display("CPU : Accessing non-aligned address, base + imm = %b, imm_base_addr");
                        end
                    end
                    SW: begin
                        // state <= FETCH;
                        data_writedata <= rt_data;
                        if(imm_base_addr[1:0] == 0) begin
                          byteenable <= 4'b1111;
                        end
                        else begin
                          $display("CPU : Accessing non-aligned address, base + imm =%b", imm_base_addr);
                        end
                    end
                    SLTI: begin
                      if ($signed(rs_data) < $signed(imm_signed_extended)) begin
                        write_back_data <= 1;
                      end
                      else begin
                        write_back_data <= 0;
                      end
                    end
                    SLTIU: begin
                      if (rs_data < imm_signed_extended) begin
                        write_back_data <= 1;
                      end
                      else begin
                        write_back_data <= 0;
                      end
                    end
                    XORI: begin // imm zero extended
                      write_back_data <= rs_data ^ {{16'h0000},imm} ;
                    end
                    JUMP: begin
                      if (jump_check == 1) begin
                        $fatal(2, "Branch in branch delay slot");
                      end
                      branch_delay_slot <= {pc_next[31:28],jump_addr,2'b00};
                      jump_check <= 1;
                    end
                    JAL: begin
                      if (jump_check == 1) begin
                        $fatal(2, "Branch in branch delay slot");
                      end
                      branch_delay_slot <= {pc_next[31:28],jump_addr,2'b00};
                      jump_check <= 1;
                      write_back_data <= pc + 8;
                    end
                endcase
            end
            //should this be moved up?
            if(jump_check == 1) begin
                pc <= branch_delay_slot;
                jump_check <= 0;
            end
            else begin
                pc <= pc_next;
            end
        end
        //Exec2
        else if((state == EXEC2) && (active == 1)) begin
            $display("CPU : EXEC2 : write_en = %d, instr = %h, instr_type =%b, pc = %h, register_v0 = %h", write_enable, instr, instr_type, pc, register_v0);
            state <= FETCH;
        //R instruction
            if(instr_type == R) begin
                case(fn_code)
                    MULT: begin
                      Hi <= mult_output[63:32];
                      Lo <= mult_output[31:0];
                    end
                    MULTU: begin
                      Hi <= mult_output[63:32];
                      Lo <= mult_output[31:0];
                    end
                endcase
            end
            //I instruction
            else if((instr_type == I) || (instr_type == J)) begin
                case(opcode)
                    LB: begin //8_Bit is signed extended
                        state <= EXEC3;
                        if(imm_base_addr[1:0] == 0) begin
                          write_back_data <= {{24{data_readdata[7]}},data_readdata[7:0]};
                        end
                        else if(imm_base_addr[1:0] == 1) begin
                          write_back_data <= {{24{data_readdata[15]}},data_readdata[15:8]};
                        end
                        else if(imm_base_addr[1:0] == 2) begin
                          write_back_data <= {{24{data_readdata[23]}},data_readdata[23:16]};
                        end
                        else if(imm_base_addr[1:0] == 3) begin
                          write_back_data <= {{24{data_readdata[31]}},data_readdata[31:24]};
                        end
                    end
                    LBU: begin // 8_Bit is zero extended
                        state <= EXEC3;
                        if(imm_base_addr[1:0] == 0) begin
                          write_back_data <= {{24'h000000},data_readdata[7:0]};
                        end
                        else if(imm_base_addr[1:0] == 1) begin
                          write_back_data <= {{24'h000000},data_readdata[15:8]};
                        end
                        else if(imm_base_addr[1:0] == 2) begin
                          write_back_data <= {{24'h000000},data_readdata[23:16]};
                        end
                        else if(imm_base_addr[1:0] == 3) begin
                          write_back_data <= {{24'h000000},data_readdata[31:24]};
                        end
                    end
                    LH: begin //16_Bit is signed extended
                        state <= EXEC3;
                        if(imm_base_addr[1:0] == 0) begin
                          write_back_data <= {{16{data_readdata[15]}},data_readdata[15:0]};
                        end
                        else if(imm_base_addr[1:0] == 2) begin
                          write_back_data <= {{16{data_readdata[31]}},data_readdata[31:16]};
                        end
                        else begin
                          $display("CPU : Accessing non-aligned address, base + imm =%b", imm_base_addr);
                        end
                    end
                    LHU: begin //16_Bit is zero extended
                        state <= EXEC3;
                        if(imm_base_addr[1:0] == 0) begin
                          write_back_data <= {{16'h0000},data_readdata[15:0]};
                        end
                        else if(imm_base_addr[1:0] == 2) begin
                          write_back_data <= {{16'h0000},data_readdata[31:16]};
                        end
                        else begin
                          $display("CPU : Accessing non-aligned address, base + imm =%b", imm_base_addr);
                        end
                    end
                    LW: begin //16_Bit is zero extended
                        state <= EXEC3;
                        if(imm_base_addr[1:0] == 0) begin
                          write_back_data <= data_readdata;
                        end
                        else begin
                          $display("CPU : Accessing non-aligned address, base + imm =%b", imm_base_addr);
                        end
                    end
                    LWL: begin
                        state <= EXEC3;
                        if(imm_base_addr[1:0] == 0) begin
                          write_back_data <= {data_readdata[7:0],rt_data[23:0]};
                        end
                        else if(imm_base_addr[1:0] == 1) begin
                          write_back_data <= {data_readdata[15:0],rt_data[15:0]};
                        end
                        else if(imm_base_addr[1:0] == 2) begin
                          write_back_data <= {data_readdata[23:0],rt_data[7:0]};
                        end
                        else if(imm_base_addr[1:0] == 3) begin
                          write_back_data <= data_readdata;
                        end
                        else begin
                          $display("CPU : Accessing non-aligned address, base + imm =%b", imm_base_addr);
                        end
                    end
                    LWR: begin
                        state <= EXEC3;
                        if(imm_base_addr[1:0] == 0) begin
                          write_back_data <= data_readdata;
                        end
                        else if(imm_base_addr[1:0] == 1) begin
                          write_back_data <= {rt_data[31:24],data_readdata[31:8]};
                        end
                        else if(imm_base_addr[1:0] == 2) begin
                          write_back_data <= {rt_data[31:16],data_readdata[31:16]};
                        end
                        else if(imm_base_addr[1:0] == 3) begin
                          write_back_data <= {rt_data[31:8],data_readdata[31:24]};
                        end
                        else begin
                          $display("CPU : Accessing non-aligned address, base + imm =%b", imm_base_addr);
                        end
                    end
                endcase
            end

        end
        else if((state == EXEC3) && (active == 1)) begin //One more cycle for Load instructions to store the data to register file. Register file takes 2 cycles to load
            $display("CPU : EXEC3 : write_en = %d, instr = %h, instr_type =%b, pc = %h, register_v0 = %h", write_enable, instr, instr_type, pc, register_v0);
            state <= FETCH;
        end
        else if (state == HALTED) begin

        end
        else begin
            $display("CPU : ERROR : Processor in unexpected state %b", state);
            $finish;
        end
    end

endmodule
