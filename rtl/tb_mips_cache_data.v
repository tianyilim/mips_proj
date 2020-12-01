// Testbench for the data cache
module tb_mips_cache_data;
    timeunit 1ns / 1ns;

    // Test parameters
    parameter TEST_DURATION = 16;
    parameter TIMEOUT_CYCLES = 1000;
    // parameter OFFSET = 32'hBFC00000;
    parameter MEM_BITS = 8;
    parameter DVALID_DELAY = 3;    // Something
    parameter MEM_INIT_FILE = "";

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

    // Test vector
    integer test_arr[7:0];

    mips_cache_data data_cache(.clk(clk), .rst(rst), .addr(cache_addr),
                                .read_en(cache_read), .write_en(cache_write),
                                .writedata(cache_writedata), .byte_en(cache_byteenable),
                                .readdata(cache_readdata), .stall(cache_stall),
                                .data_addr(mem_addr), .data_in(mem_readdata),
                                .data_valid(mem_dvalid));
    dummy_ram #(.MEM_BITS(MEM_BITS), .DVALID_DELAY(DVALID_DELAY), 
                                .MEM_INIT_FILE(MEM_INIT_FILE)) 
                                dummy_ram(.clk(clk), .addr(mem_addr),
                                .read_en(cache_stall), .data(mem_readdata),
                                .dvalid(mem_dvalid));
    
    // Initialise test vector
    initial begin
        test_arr[0] = 1*8*4;    // Multiply by 4 due to word aligning
        test_arr[1] = 2*8*4;
        test_arr[2] = 3*8*4;
        test_arr[3] = 4*8*4;
        test_arr[4] = 5*8*4;
        test_arr[5] = 2*8*4;
        test_arr[6] = 4*8*4;
        test_arr[7] = 6*8*4;
    end

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
        cache_read = 0;
        cache_write = 0;
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

        $display("\nTB : %2t : Temporal Locality Check\n", $time);
        // Check for cache's ability to retain information (read addresses 0-7 twice over)
        // If the values are correct and there are no stalls the second time round, then it should be correct 
        for (i=0; i<8; i++) begin
            cache_addr <= i*4;
            cache_read <= 1;
            @(posedge clk);
            while(cache_stall) begin
                @(posedge clk);
                $display("TB : %2t : Cache Read stall at address 0x%h", $time, cache_addr);
            end
            @(posedge clk);
            $display("TB : %2t : Cache read value 0x%h at address 0x%h\n", $time, cache_readdata, cache_addr);
        end
        $display("\nTB : %2t : Second round of reading\n", $time);
        for (i=0; i<8; i++) begin
            cache_addr <= i*4;
            cache_read <= 1;
            @(posedge clk);
            while(cache_stall) begin
                @(posedge clk);
                $error("TB : %2t : Cache Read stall at address 0x%h on something in cache", $time, cache_addr);
            end
            @(posedge clk);
            $display("TB : %2t : Cache read value 0x%h at address 0x%h\n", $time, cache_readdata, cache_addr);
        end

        $display("\nTB : %2t : Regular Write Check\n", $time);
        // Check for regular writes
        cache_read <= 0;
        @(posedge clk);

        for (i=0; i<8; i++) begin
            cache_addr <= i*4;
            cache_write <= 1;
            cache_byteenable <= 4'b1111;    // yups
            cache_writedata <= $pow(i,2);
            @(posedge clk);
            while(cache_stall) begin
                @(posedge clk);
                $error("TB : %2t : Cache Write stall at address 0x%h on something in cache", $time, cache_addr);
                // This should not happen!
            end
            @(posedge clk);
        end
        cache_write <= 0;
        @(posedge clk);
        $display("\nTB : %2t : Read check to validate written results\n", $time);
        for (i=0; i<8; i++) begin
            cache_addr <= i*4;
            cache_read <= 1;
            @(posedge clk);
            while(cache_stall) begin
                @(posedge clk);
                $error("TB : %2t : Cache Read stall at address 0x%h on something in cache", $time, cache_addr);
                // This should also not happen!
            end
            @(posedge clk);
            assert(cache_readdata == $pow(i,2)) else $error("did not read expected value");
            $display("TB : %2t : Cache read value 0x%h at address 0x%h\n", $time, cache_readdata, cache_addr);
        end

        $display("\nTB : %2t : Associativity Check\n", $time);
        // Check for cache's ability to retain associativity (0,8,16,24)
        for (i=0; i<4; i++) begin
            cache_addr <= i*8*4;
            cache_read <= 1;
            @(posedge clk);
            while(cache_stall) begin
                @(posedge clk);
                $display("TB : %2t : Cache Read stall at address 0x%h", $time, cache_addr);
            end
            @(posedge clk);
            $display("TB : %2t : Cache read value 0x%h at address 0x%h\n", $time, cache_readdata, cache_addr);
        end
        $display("\nTB : %2t : Second round of reading\n", $time);
        for (i=0; i<4; i++) begin
            cache_addr <= i*8*4;
            cache_read <= 1;
            @(posedge clk);
            while(cache_stall) begin
                @(posedge clk);
                $display("TB : %2t : Cache Read stall at address 0x%h", $time, cache_addr);
            end
            @(posedge clk);
            $display("TB : %2t : Cache read value 0x%h at address 0x%h\n", $time, cache_readdata, cache_addr);
        end

        $display("\nTB : %2t : LRU Check\n", $time);
        // Check for cache's replacement policy
        for (i=0; i<8; i++) begin
            cache_addr <= test_arr[i];
            cache_read <= 1;
            @(posedge clk);
            while(cache_stall) begin
                @(posedge clk);
                $display("TB : %2t : Cache Read stall at address 0x%h", $time, cache_addr);
            end
            @(posedge clk);
            $display("TB : %2t : Cache read value 0x%h at address 0x%h\n", $time, cache_readdata, cache_addr);
        end

        cache_read <= 0;
        rst <= 1;
        @(posedge clk);
        $display("\nTB : %2t : Checking for write misses; resetting cache\n", $time);

        rst <= 0;
        @(posedge clk);

        // Check for write miss (byte_en == 4'b1111)
        $display("\nTB : %2t : Overwrite Check\n", $time);
        // Check for regular writes
        cache_read <= 0;
        @(posedge clk);

        for (i=0; i<8; i++) begin
            cache_addr <= i*4;
            cache_write <= 1;
            cache_byteenable <= 4'b1111;    // yups
            cache_writedata <= $pow(i,2);
            @(posedge clk);
            while(cache_stall) begin
                @(posedge clk);
                $display("TB : %2t : Cache Write stall at address 0x%h despite being full overwrite", $time, cache_addr);
                // This should not happen!
            end
            @(posedge clk);
        end
        cache_write <= 0;
        @(posedge clk);
        $display("\nTB : %2t : Read check to validate written results\n", $time);
        for (i=0; i<8; i++) begin
            cache_addr <= i*4;
            cache_read <= 1;
            @(posedge clk);
            while(cache_stall) begin
                @(posedge clk);
                $error("TB : %2t : Cache Read stall at address 0x%h on something in cache", $time, cache_addr);
                // This should also not happen!
            end
            @(posedge clk);
            assert(cache_readdata == $pow(i,2)) else $error("did not read expected value");
            $display("TB : %2t : Cache read value 0x%h at address 0x%h\n", $time, cache_readdata, cache_addr);
        end

        cache_read <= 0;
        rst <= 1;
        @(posedge clk);
        $display("\nTB : %2t : Checking for write misses; resetting cache\n", $time);

        rst <= 0;
        @(posedge clk);

        // Check for write miss (byte_en =/= 4'b1111)
        $display("\nTB : %2t : Partial Overwrite Check\n", $time);
        // Check for regular writes
        cache_read <= 0;
        @(posedge clk);

        for (i=0; i<8; i++) begin
            cache_addr <= i*4;
            cache_write <= 1;
            cache_byteenable <= 4'b0101;    // yups
            cache_writedata <= $pow(i,2);
            @(posedge clk);
            while(cache_stall) begin
                @(posedge clk);
                $display("TB : %2t : Cache Write stall at address 0x%h", $time, cache_addr);
                // This should not happen!
            end
            @(posedge clk);
        end
        cache_write <= 0;
        @(posedge clk);
        $display("\nTB : %2t : Read check to validate written results\n", $time);
        for (i=0; i<8; i++) begin
            cache_addr <= i*4;
            cache_read <= 1;
            @(posedge clk);
            while(cache_stall) begin
                @(posedge clk);
                $error("TB : %2t : Cache Read stall at address 0x%h on something in cache", $time, cache_addr);
                // This should also not happen!
            end
            @(posedge clk);
            // assert(cache_readdata == $pow(i,2)) else $error("did not read expected value");
            $display("TB : %2t : Cache read value 0x%h at address 0x%h\n", $time, cache_readdata, cache_addr);
        end

        $finish;
    end

    

endmodule