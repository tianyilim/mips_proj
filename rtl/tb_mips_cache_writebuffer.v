// Testbench for the Avalon Memory-mapped slave (RAM unit?)

module tb_mips_cache_writebuffer;
    timeunit 1ns / 1ns;

    // Parameters for RAM setup
    parameter RAM_INIT_FILE = "test/avalon_slave_sample.txt";
    parameter TEST_MEM_SIZE = 16;
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

    logic writing; // 0: ram_address from writebuffer, 1: ram_adress from read source

    mips_avalon_slave #(.RAM_INIT_FILE(RAM_INIT_FILE), .MEM_SIZE(TEST_MEM_SIZE),
                        .READ_DELAY(TEST_READ_DELAY), .WRITE_DELAY(TEST_WRITE_DELAY)) 
                        ramInst(.clk(clk), .rst(rst), .address(ram_address),
                            .write(ram_write), .read(ram_read), .writedata(ram_writedata),
                            .byteenable(ram_byteenable), .waitrequest(waitrequest),
                            .readdata(ram_readdata));

    mips_cache_writebuffer #(.BUF_BITS(WB_BUF_BITS)) wbuf(.clk(clk), .rst(rst),
                        .addr(wb_addr), .write_en(wb_write_en), .writedata(wb_writedata),
                        .byteenable(wb_byteenable), .write_addr(wb_write_addr),
                        .waitrequest(waitrequest),
                        .write_data(ram_writedata), .write_byteenable(ram_byteenable),
                        .write_writeenable(ram_write), .full(wb_full), .empty(wb_empty));
    
    // Generate clock
    initial begin
        $dumpfile("tb_mips_cache_writebuffer.vcd");
        $dumpvars(0, tb_mips_cache_writebuffer);
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
        $display("TB : %1t : Started testbench", $time);
        rst <= 0;
        @(posedge clk);
        rst <= 1;
        wb_write_en <= 0;
        wb_addr <= OFFSET;
        wb_writedata <= 0;
        wb_byteenable <= 0;
        // wb_write_addr <= OFFSET;
        ram_address <= OFFSET;
        @(posedge clk);
        rst <= 0;
        @(posedge clk);

        // Fill up write buffer
        for(i=0; i<TEST_MEM_SIZE; i++) begin
            if (wb_full) begin
                @(posedge clk);
                $display("TB : %1t : Stalling as write buffer is full", $time);
            end else begin
                wb_write_en <= 1;
                wb_addr <= OFFSET + i;
                wb_byteenable <= 4'b1111;
                wb_writedata <= $pow(i,2);  // Dummy data
                
                ram_address <= wb_write_addr;
                @(posedge clk);
                $display("TB : %1t : Writing %d into WB for address 0x%h", $time, wb_writedata, wb_addr);
            end
            // Read data in memory
        end
        wb_write_en <= 0;
        @(posedge clk);
        while(~wb_empty) begin
            @(posedge clk);
            $display("TB : %1t : Waiting for WB to empty out", $time);
        end

        for(i=0; i<TEST_MEM_SIZE; i++) begin
            ram_read <= 1;
            ram_address <= i+OFFSET;
            @(posedge clk);
            $display("TB : %1t : Reading from address 0x%h", $time, ram_address);
            
            while(waitrequest) begin
                @(posedge clk);
            end

            @(posedge clk);
            $display("TB : %1t : Read %d from address 0x%h", $time, ram_readdata, ram_address);
        end

        ram_read <= 0;

        $finish;
    end

    

endmodule