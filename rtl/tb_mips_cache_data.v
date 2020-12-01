// Testbench for the data cache
module tb_mips_cache_data;
    timeunit 1ns / 1ns;

    // Test parameters
    parameter TEST_DURATION = 16;
    parameter TIMEOUT_CYCLES = 1000;
    parameter OFFSET = 32'hBFC00000;

    integer i=0;    // iterator variable

    logic clk;
    logic rst;

    logic[31:0] cache_addr;
    logic cache_write;
    logic cache_read;
    logic[31:0] cache_writedata;
    logic[3:0] cache_byteenable;
    logic [31:0] cache_readdata;

    logic cache_stall;

    logic[31:0] mem_addr;
    logic[31:0] mem_readdata;
    logic mem_dvalid;

    mips_cache_data data_cache(.clk(clk), .rst(rst), .addr(cache_addr),
                                .read_en(cache_read), .write_en(cache_write),
                                .writedata(cache_writedata), .byte_en(cache_byteenable),
                                .readdata(cache_readdata), .stall(cache_stall),
                                .data_addr(mem_addr), .data_in(mem_readdata),
                                .data_valid(mem_dvalid));
    
    // Generate clock
    initial begin
        $dumpfile("tb_mips_cache_data.vcd");
        $dumpvars(0, tb_mips_cache_data);
        clk=0;
        repeat (TIMEOUT_CYCLES) begin
            #5;
            clk = !clk;
            #5;
            clk = !clk;
        end
        $fatal(2, "Simulation did not finish within %d cycles.", TIMEOUT_CYCLES);
    end

    initial begin
        $display("TB : %2t : Started testbench", $time);
        rst <= 0;
        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;
        @(posedge clk);

        $finish;
    end

    

endmodule