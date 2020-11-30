`timescale 1ns/100ps

module register_file_tb_simple(
);
    logic clk;
    logic reset;

    logic[4:0]    rs_index;
    logic[31:0]  rs_data;

    logic[4:0]    rt_index;
    logic[31:0]  rt_data;

    logic[4:0]    rd_index;
    logic         write_enable;
    logic[31:0]   rd_data;

    logic[31:0]  register_v0;

    /* Generate clock, set stimulus, and also check output. */
    initial begin
        $timeformat(-9, 1, " ns", 20);
        $dumpfile("register_file_tb_simple.vcd");
        $dumpvars(0, register_file_tb_simple);

        /* Clock low. */
        clk = 0;
        reset = 1;
        rd_index=0;
        write_enable=0;
        rd_data=0;
        rs_index=0;
        rt_index=31;

        /* Rising edge */
        #5 clk = 1;

        /* Falling edge */
        #5 clk = 0;
        /* Check outputs */
        assert(rs_data==0);
        assert(rt_data==0);
        $display("rs=%d,  rt=%d", rs_data, rt_data);
        /* Drive new inputs */
        reset = 0;
        rs_index = 2;
        rd_index = 2;
        rd_data = 32134;
        write_enable = 1;

        /* Rising edge */
        #5 clk = 1;

        /* Falling edge */
        #5 clk = 0;
        /* Check outputs */
        assert(rs_data==32134);
        assert(register_v0 == 32134);
        $display("rs=%d,  rt=%d, r2=%d", rs_data, rt_data, register_v0);
        /* Drive new inputs */
        rt_index = 0;
        rd_index = 0;
        rd_data = 20;
        write_enable = 1;

        /* Rising edge */
        #5 clk = 1;

        /* Falling edge */
        #5 clk = 0;
        /* Check outputs */
        assert(rt_data==0);
        $display("rs=%d,  rt=%d", rs_data, rt_data);
        /* Drive new inputs */
        rs_index = 30;
        rd_index = 30;
        rd_data = 1432;
        write_enable = 0;

        /* Rising edge */
        #5 clk = 1;

        /* Falling edge */
        #5 clk = 0;
        /* Check outputs */
        assert(rs_data==0);
        $display("rs=%d,  rt=%d", rs_data, rt_data);
    end


    register_file regs(
        .clk(clk),
        .reset(reset),
        .rs_index(rs_index), .rs_data(rs_data),
        .rt_index(rt_index), .rt_data(rt_data),
        .rd_index(rd_index), .rd_data(rd_data),
        .register_v0(register_v0),
        .write_enable(write_enable)
    );
endmodule
