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
    logic instr_read;

    logic[31:0]  data_address;
    logic        data_write;
    logic        data_read;
    logic[31:0]  data_writedata;
    logic[3:0] data_byteenable;
    logic[31:0]  data_readdata;

    logic[1:0] cc_state;

    parameter RAM_INIT_FILE = "test/avalon_slave_sample.txt";
    parameter TEST_MEM_SIZE = 1024;
    parameter TEST_READ_DELAY = 2;
    parameter TEST_WRITE_DELAY = TEST_READ_DELAY;
    parameter TIMEOUT_CYCLES = 1000;
    parameter OFFSET = 32'hBFC00000;

    integer i;  // iterator

    mips_cache_controller cache_ctrl(.clk(clk), .rst(rst), .mem_address(mem_address),
                                    .mem_write(mem_write), .mem_read(mem_read), .mem_writedata(mem_writedata),
                                    .mem_byteenable(mem_byteenable), .waitrequest(waitrequest),
                                    .mem_readdata(mem_readdata),
                                    .clk_enable(clk_enable), 
                                    .instr_address(instr_address), .instr_readdata(instr_readdata),
                                    .instr_read(instr_read),
                                    .data_address(data_address), .data_write(data_write),
                                    .data_read(data_read), .data_writedata(data_writedata),
                                    .data_byteenable(data_byteenable), .data_readdata(data_readdata)
                                    ,.cc_state(cc_state));

    mips_avalon_slave #(.RAM_INIT_FILE(RAM_INIT_FILE), .MEM_SIZE(TEST_MEM_SIZE),
                        .READ_DELAY(TEST_READ_DELAY), .WRITE_DELAY(TEST_WRITE_DELAY))
                        ram(.clk(clk), .rst(rst), .address(mem_address),
                        .write(mem_write), .read(mem_read), .writedata(mem_writedata),
                        .byteenable(mem_byteenable), .waitrequest(waitrequest),
                        .readdata(mem_readdata)    
                        );

    // Looks like a CPU to the cache controller to simulate read and write transactions
    // and test the different states of the cache controller.

    initial begin
        assert(TEST_MEM_SIZE > 1023) else $fatal(2, "Mem size too small, must be >1024"); // check memory size
        $dumpfile("tb_mips_cache_controller.vcd");
        $dumpvars(0, tb_mips_cache_controller);
        clk=0;
        instr_read = 0;     // These must be asserted to make instr/data_stall not X
        data_read = 0;      // These must be asserted to make instr/data_stall not X
        data_write = 0;     // These must be asserted to make instr/data_stall not X
        instr_address = OFFSET; // Corresponding to the reset vector
        data_address = 0;       // I guess?

        repeat (TIMEOUT_CYCLES) begin
            #5;
            clk = !clk;
            #5;
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
        @(posedge clk);

        /// INSTRUCTION CACHE TEST
        $display("\nTB : %2t : Checking for instruction read misses\n", $time);
        // Test instruction read
        for (i=0; i<8; i++) begin
            instr_read <= 1;
            instr_address <= OFFSET + i*4;
            @(posedge clk);
            $display("TB : %2t : Read requested from address 0x%h", $time, instr_address);

            while (~clk_enable) begin
                @(posedge clk);
                $display("TB : %2t : Wait as clk_enable is low", $time);
            end
            
            @(posedge clk);
            assert(instr_readdata==(32'hFFFFFF00|i)) else $error("TB : %2t : Read 0x%h but expected 0x%h", $time, instr_readdata, (32'hFFFFFF00|i));
            $display("TB : %2t : Read 0x%h from address 0x%h", $time, instr_readdata, instr_address);
        end

        instr_read <= 0;
        @(posedge clk);
        @(posedge clk);
        // Wait for state to settle
        $display("\nTB : %2t : Reading addresses again to check that they do not miss\n", $time);

        for (i=0; i<8; i++) begin
            instr_read <= 1;
            instr_address <= OFFSET + i*4;
            @(posedge clk);
            $display("TB : %2t : Read requested from address 0x%h", $time, instr_address);
            assert(cc_state==2'b00) else $error("TB : %2t : Cache miss on re-read", $time);
            while (~clk_enable) begin
                @(posedge clk);
                $display("TB : %2t : Wait as clk_enable is low", $time);
                $error("TB : %2t : clk_enable pulled low on re-read");
            end
            
            @(posedge clk);
            assert(instr_readdata==(32'hFFFFFF00|i)) else $error("TB : %2t : Read 0x%h but expected 0x%h", $time, instr_readdata, (32'hFFFFFF00|i));
            $display("TB : %2t : Read 0x%h from address 0x%h", $time, instr_readdata, instr_address);
        end

        instr_read <= 0;
        @(posedge clk);

        /// DATA CACHE TEST
        $display("\nTB : %2t : Checking for data read misses\n", $time);
        // Test instruction read
        for (i=64; i<64+8; i++) begin
            data_read <= 1;
            data_address <= OFFSET + i*4;
            @(posedge clk);
            $display("TB : %2t : Read requested from address 0x%h", $time, data_address);

            while (~clk_enable) begin
                @(posedge clk);
                $display("TB : %2t : Wait as clk_enable is low", $time);
            end
            
            @(posedge clk);
            assert(data_readdata==(32'hFFFFFF00|i)) else $error("TB : %2t : Read 0x%h but expected 0x%h", $time, data_readdata, (32'hFFFFFF00|i));
            $display("TB : %2t : Read 0x%h from address 0x%h", $time, data_readdata, data_address);
        end

        data_read <= 0;
        @(posedge clk);
        @(posedge clk);
        // Wait for state to settle
        $display("\nTB : %2t : Reading addresses again to check that they do not miss\n", $time);

        for (i=64; i<64+8; i++) begin
            data_read <= 1;
            data_address <= OFFSET + i*4;
            @(posedge clk);
            $display("TB : %2t : Read requested from address 0x%h", $time, data_address);
            assert(cc_state==2'b00) else $error("TB : %2t : Cache miss on re-read", $time);
            while (~clk_enable) begin
                @(posedge clk);
                $display("TB : %2t : Wait as clk_enable is low", $time);
                $error("TB : %2t : clk_enable pulled low on re-read");
            end
            
            @(posedge clk);
            assert(data_readdata==(32'hFFFFFF00|i)) else $error("TB : %2t : Read 0x%h but expected 0x%h", $time, data_readdata, (32'hFFFFFF00|i));
            $display("TB : %2t : Read 0x%h from address 0x%h", $time, data_readdata, data_address);
        end
        data_read <= 0;
        @(posedge clk);

        $finish;
    end 

endmodule
