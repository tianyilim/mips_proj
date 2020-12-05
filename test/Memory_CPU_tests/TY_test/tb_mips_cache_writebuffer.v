// Testbench for the Avalon Memory-mapped slave (RAM unit?)

module tb_mips_cache_writebuffer;
    timeunit 1ns / 1ns;

    // Test parameters
    parameter TEST_DURATION = 16;

    // Parameters for RAM setup
    parameter RAM_INIT_FILE = "test/avalon_slave_sample.txt";
    parameter TEST_MEM_SIZE = 1024;
    parameter TEST_READ_DELAY = 2;
    parameter TEST_WRITE_DELAY = TEST_READ_DELAY;
    parameter TIMEOUT_CYCLES = 1000;
    parameter OFFSET = 32'hBFC00000;

    // Parameters for Writebuffer setup
    parameter WB_BUF_BITS = 3;

    integer i=0;    // iterator variable

    logic clk;
    logic rst;

    logic[31:0] ram_address;
    logic ram_write;
    logic ram_read;
    logic[31:0] ram_writedata;
    logic[3:0] ram_byteenable;

    logic waitrequest;
    logic[31:0] ram_readdata;

    logic wb_write_en;
    logic[31:0] wb_addr;
    logic wb_full;               // Assert when write buffer is filled!
    logic wb_empty;
    logic[31:0] wb_writedata;
    logic[3:0] wb_byteenable;

    logic[31:0] wb_write_addr;  // Address to write to avalon bus

    logic[31:0] read_addr;  // Read address for RAM
    logic write_read; // 0: ram_address from writebuffer, 1: ram_adress from read source

    logic wb_active;

    mips_avalon_slave #(.RAM_INIT_FILE(RAM_INIT_FILE), .MEM_SIZE(TEST_MEM_SIZE),
                        .READ_DELAY(TEST_READ_DELAY), .WRITE_DELAY(TEST_WRITE_DELAY)) 
                        ramInst(.clk(clk), .rst(rst), .address(ram_address),
                            .write(ram_write), .read(ram_read), .writedata(ram_writedata),
                            .byteenable(ram_byteenable), .waitrequest(waitrequest),
                            .readdata(ram_readdata));

    mips_cache_writebuffer #(.BUF_BITS(WB_BUF_BITS)) wbuf(.clk(clk), .rst(rst),
                        .addr(wb_addr), .write_en(wb_write_en), .writedata(wb_writedata),
                        .byteenable(wb_byteenable), .write_addr(wb_write_addr),
                        .waitrequest(waitrequest), .active(wb_active),
                        .write_data(ram_writedata), .write_byteenable(ram_byteenable),
                        .write_writeenable(ram_write), .full(wb_full), .empty(wb_empty));
    
    // initial begin
    //     forever begin 
    //         // TODO SOMETHING WRONG HERE
    //         // assign ram_address = (write_read) ? wb_write_addr : read_addr;
    //         ram_address <= (write_read) ? wb_write_addr : read_addr;
    //         @(posedge clk);
    //         // #5; // Add a wait block for fun
    //         $display("TB : %2t : Hello! 0x%h, cond=%1b, write_addr=0x%h, read_addr=0x%h", $time, ram_address, write_read, wb_write_addr, read_addr);
    //     end
    // end

    // initial begin
        // always@(write_read, wb_write_addr, read_addr) begin 
        //     // TODO SOMETHING WRONG HERE
        //     // assign ram_address = (write_read) ? wb_write_addr : read_addr;
        //     ram_address <= (write_read) ? wb_write_addr : read_addr;
        //     // @(posedge clk);
        //     // #5; // Add a wait block for fun
        //     $display("TB : %2t : Hello! 0x%h, cond=%1b, write_addr=0x%h, read_addr=0x%h", $time, ram_address, write_read, wb_write_addr, read_addr);
        // end
    // end

    // Generate clock
    initial begin
        assert(TEST_MEM_SIZE > 1023) else $fatal(2, "Mem size too small, must be >1024"); // check memory size
        $dumpfile("tb_mips_cache_writebuffer.vcd");
        $dumpvars(0, tb_mips_cache_writebuffer);
        clk=0;
        write_read <= 0;
        wb_active <= 1;

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
        wb_write_en <= 0;
        wb_addr <= OFFSET;
        wb_writedata <= 0;
        wb_byteenable <= 0;
        ram_read <= 0;
        // wb_write_addr <= OFFSET;
        ram_address = OFFSET;
        @(posedge clk);
        rst <= 0;
        @(posedge clk);

        // Fill up write buffer
        for(i=0; i<TEST_DURATION; i++) begin
            while (wb_full) begin
                ram_address = wb_write_addr;
                @(posedge clk);
                $display("TB : %2t : Stalling as write buffer is full", $time);
                // $display("TB : %2t : Current ram_address 0x%h, writing=%b", $time, ram_address, writing);
            end
            wb_write_en <= 1;
            wb_addr <= OFFSET + i;
            wb_byteenable <= 4'b1111;
            wb_writedata <= $pow(i,2);  // Dummy data
            
            ram_address = wb_write_addr;
            @(posedge clk);
            $display("TB : %2t : Writing %d into WB for address 0x%h", $time, wb_writedata, wb_addr);
            // $display("TB : %2t : Current ram_address 0x%h, write addr 0x%h, writing=%b", $time, ram_address, wb_write_addr, writing);
            // Read data in memory
        end
        while (wb_full) begin
            ram_address = wb_write_addr;
            @(posedge clk);
        end   // make sure that all data to be written has been done so
        wb_write_en <= 0;
        @(posedge clk);

        // Take a break from writing for a few cycles
        $display("Taking a break 1");
        @(posedge clk);
        $display("Taking a break 2");
        @(posedge clk);
        $display("Taking a break 3");
        @(posedge clk);

        // Round 2
        for(i=TEST_DURATION; i<2*TEST_DURATION; i++) begin
            while (wb_full) begin
                ram_address = wb_write_addr;
                @(posedge clk);
                $display("TB : %2t : Stalling as write buffer is full", $time);
                // $display("TB : %2t : Current ram_address 0x%h, writing=%b", $time, ram_address, writing);
            end
            wb_write_en <= 1;
            wb_addr <= OFFSET + i;
            wb_byteenable <= 4'b1111;
            wb_writedata <= $pow(i,2);  // Dummy data
            
            ram_address = wb_write_addr;
            @(posedge clk);
            $display("TB : %2t : Writing %d into WB for address 0x%h", $time, wb_writedata, wb_addr);
            // $display("TB : %2t : Current ram_address 0x%h, write addr 0x%h, writing=%b", $time, ram_address, wb_write_addr, writing);
            // Read data in memory
        end
        while (wb_full) begin
            ram_address = wb_write_addr;
            @(posedge clk);
        end   // make sure that all data to be written has been done so
        wb_write_en <= 0;
        @(posedge clk);



        while(~wb_empty) begin
            ram_address = wb_write_addr;
            @(posedge clk);
            $display("TB : %2t : Waiting for WB to empty out", $time);
            $display("TB : %2t : Current ram_address 0x%h, write addr 0x%h, writing=%b", $time, ram_address, wb_write_addr, write_read);
            // Test active here
            if (~waitrequest) begin
                wb_active <= 0;
                $display("TB : %2t : Set Active to 0 to see if writing stops", $time);
                repeat (5) begin
                    @(posedge clk);
                    $display("TB : %2t : Waiting cycles, writing should not be happening", $time);
                end
                wb_active <= 1;
                $display("TB : %2t : Reset Active to 1 to see if writing starts", $time);
            end
        end

        for(i=0; i<2*TEST_DURATION; i++) begin
            // write_read <= 1;
            ram_read <= 1;
            // read_addr <= i+OFFSET;
            ram_address = i+OFFSET;
            // ram_address = read_addr;
            @(posedge clk);
            $display("TB : %2t : Reading from address 0x%h", $time, ram_address);
            
            while(waitrequest) begin
                @(posedge clk);
            end

            ram_read <= 0;
            @(posedge clk);
            $display("TB : %2t : Read %d from address 0x%h", $time, ram_readdata, ram_address);
        end


        $finish;
    end

    

endmodule