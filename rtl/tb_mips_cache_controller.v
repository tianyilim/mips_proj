// Testbench for the data cache
module tb_mips_cache_controller;
    timeunit 1ns / 1ns;

    logic clk;
    logic rst;
    // Avalon Bus
    logic[31:0] mem_address;
    logic mem_write;
    logic mem_read;
    logic[31:0] mem_writedata;
    logic[3:0] mem_byteenable;

    logic waitrequest;
    logic[31:0] mem_readdata;

    // to/from the CPU
    logic clk_enable;

    logic[31:0]  instr_address;
    logic[31:0]   instr_readdata;

    logic[31:0]  data_address;
    logic        data_write;
    logic        data_read;
    logic[31:0]  data_writedata;
    logic[3:0] data_byteenable;
    logic[31:0]  data_readdata;

    parameter RAM_INIT_FILE = "test/avalon_slave_sample.txt";
    parameter TEST_MEM_SIZE = 1024;
    parameter TEST_READ_DELAY = 2;
    parameter TEST_WRITE_DELAY = TEST_READ_DELAY;
    parameter TIMEOUT_CYCLES = 1000;
    parameter OFFSET = 32'hBFC00000;

    mips_cache_controller cache_ctrl(.clk(clk), .rst(rst), .mem_address(mem_address),
                                    .mem_write(mem_write), .mem_read(mem_read), .mem_writedata(mem_writedata),
                                    .mem_byteenable(mem_byteenable), .waitrequest(waitrequest),
                                    .mem_readdata(mem_readdata),
                                    .clk_enable(clk_enable), 
                                    .instr_address(instr_address), .instr_readdata(instr_readdata),
                                    .data_address(data_address), .data_write(data_write),
                                    .data_read(data_read), .data_writedata(data_writedata),
                                    .data_byteenable(data_byteenable), .data_readdata(data_readdata)
                                    );
    mips_avalon_slave #(.RAM_INIT_FILE(RAM_INIT_FILE), .MEM_SIZE(TEST_MEM_SIZE),
                        .READ_DELAY(TEST_READ_DELAY), .WRITE_DELAY(TEST_WRITE_DELAY))
                        ram(.clk(clk), .rst(rst), .address(mem_address),
                        .write(mem_write), .read(mem_read), .writedata(mem_writedata),
                        .byteenable(mem_byteenable), .waitrequest(waitrequest),
                        .readdata(mem_readdata)    
                        );

    // Looks like a CPU to the cache controller to simulate read and write transactions
    // and test the different states of the cache controller.

endmodule
