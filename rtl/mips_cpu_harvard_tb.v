module mips_cpu_harvard_tb;

    parameter RAM_INIT_FILE = "testcase.hex.txt";
    parameter TIMEOUT_CYCLES = 30;

    logic clk;
    logic clk_enable;
    logic rst;
    logic active;
    logic[31:0] register_v0;

    logic[3:0] byteenable;
    logic[31:0]  instr_address;
    logic[31:0]   instr_readdata;
    logic        instr_read;

    logic[31:0]  data_address;
    logic        data_write;
    logic        data_read;
    logic[31:0]  data_writedata;
    logic[31:0]  data_readdata;

    dummy_harvard_ram #(.MEM_INIT_FILE(RAM_INIT_FILE)) ramInst(clk, instr_address, instr_readdata, byteenable, data_address, data_write, data_read, data_writedata, data_readdata);

    mips_cpu_harvard cpuInst(clk, clk_enable, rst, active, register_v0, byteenable, instr_address, instr_readdata, instr_read, data_address, data_write, data_read, data_writedata, data_readdata);

    // Generate clock
    initial begin
        $dumpfile("harvard_tb.vcd");
        $dumpvars(0, mips_cpu_harvard_tb);
        clk=0;

        repeat (TIMEOUT_CYCLES) begin
            #10;
            clk = !clk;
            #10;
            clk = !clk;
        end

        $fatal(2, "Simulation did not finish within %d cycles.", TIMEOUT_CYCLES);
    end

    initial begin
        rst <= 0;

        @(posedge clk);
        rst <= 1;

        @(posedge clk);
        rst <= 0;
        clk_enable <= 1;

        @(posedge clk);
        assert(active==1)
        assert(clk_enable == 1);
        else $display("TB : CPU did not set running=1 after reset.");

        while (active) begin
            @(posedge clk);
        end

        $display("TB : finished; running=0");

        $finish;

    end



endmodule
