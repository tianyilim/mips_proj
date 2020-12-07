`timescale 1ns / 1ns
module register_file(
    input logic clk,
    input logic reset,

    input logic[4:0]    rs_index,
    output logic[31:0]  rs_data,

    input logic[4:0]    rt_index,
    output logic[31:0]  rt_data,

    input logic[4:0]    rd_index,
    input logic         write_enable,
    input logic[31:0]   rd_data,

    output logic[31:0]  register_v0
);

    logic [31:0] regs[31:0];

    /*  Can be useful to bring array signals out - allows us to view them in waveforms.
        Will be optimised out for synthesis.
    */

    assign register_v0 = regs[2];

    assign rs_data = reset==1 ? 0 : regs[rs_index];//output can be read at any time not only during clock edges
    assign rt_data = reset==1 ? 0 : regs[rt_index];//output can be read at any time not only during clock edges
    // assign regs[0] = 0; // reg0 always == 0
    /*
    Commented out the above line, i think that the above synthesizes reg[0] (and thus all the regs) to something not a register.
    So maybe do some other logic for reg[0] = 0; also respecting the timing requriements of reading from a regfile
    because the above line should be combinational (which might not be what we want)
    */

    integer index;
    always @(posedge clk) begin
        if (reset==1) begin
            //reset reg0 to reg31
            for (index=0; index<32; index=index+1) begin
                regs[index]<= 0;//using a for loop
            end
        end
        else if (write_enable==1) begin
            if(rd_index == 0) begin
                $display("ERROR: Writing to r0");
            end
            else begin
                regs[rd_index] <= rd_data;
            end
        end
    end

endmodule
