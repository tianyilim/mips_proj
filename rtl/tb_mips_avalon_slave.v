// Testbench for the Avalon Memory-mapped slave (RAM unit?)

module tb_mips_avalon_slave;
    timeunit 1ns / 1ns;

    parameter RAM_INIT_FILE = "test/avalon_slave_sample.txt";
    parameter TEST_MEM_SIZE = 8;
    parameter TEST_READ_DELAY = 2;
    parameter TEST_WRITE_DELAY = TEST_READ_DELAY;
    parameter TIMEOUT_CYCLES = 10000;
    parameter OFFSET = 32'hBFC00000;

    integer i=0;    // iterator variable

    logic clk;
    logic rst;

    logic[31:0] address;
    logic write;
    logic read;
    logic[31:0] writedata;
    logic[3:0] byteenable;

    logic waitrequest;
    logic[31:0] readdata;

    mips_avalon_slave #(.RAM_INIT_FILE(RAM_INIT_FILE), .MEM_SIZE(TEST_MEM_SIZE),
                        .READ_DELAY(TEST_READ_DELAY), .WRITE_DELAY(TEST_WRITE_DELAY)) 
                        ramInst(.clk(clk), .rst(rst), .address(address),
                            .write(write), .read(read), .writedata(writedata),
                            .byteenable(byteenable), .waitrequest(waitrequest),
                            .readdata(readdata));
    
    // Generate clock
    initial begin
        $dumpfile("test_mips_avalon_slave_tb.vcd");
        $dumpvars(0, tb_mips_avalon_slave);
        clk=0;

        address <= 0;
        read <= 0;
        write <= 0;
        writedata <= 0;
        byteenable <= 0;

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

        address <= 0+OFFSET;
        write <= 1;
        writedata <= 32'h11111111;
        byteenable <= 4'b1111;
        @(posedge clk);
        $display("TB : %t : Writing %h to address %h with byteenable %b", $time, writedata, address, byteenable);

        while(waitrequest) begin
            @(posedge clk);
        end

        address <= 1+OFFSET;
        write <= 1;
        writedata <= 32'h11111111;
        byteenable <= 4'b0111;
        @(posedge clk);
        $display("TB : %t : Writing %h to address %h with byteenable %b", $time, writedata, address, byteenable);

        while(waitrequest) begin
            @(posedge clk);
        end

        address <= 2+OFFSET;
        write <= 1;
        writedata <= 32'h11111111;
        byteenable <= 4'b1001;
        @(posedge clk);
        $display("TB : %t : Writing %h to address %h with byteenable %b", $time, writedata, address, byteenable);

        while(waitrequest) begin
            @(posedge clk);
        end

        address <= 3+OFFSET;
        write <= 1;
        writedata <= 32'h11111111;
        byteenable <= 4'b0110;
        @(posedge clk);
        $display("TB : %t : Writing %h to address %h with byteenable %b", $time, writedata, address, byteenable);

        while(waitrequest) begin
            @(posedge clk);
        end

        write <= 0;
        @(posedge clk);

        for(i=0; i<TEST_MEM_SIZE; i++) begin
            read <= 1;
            address <= i+OFFSET;
            @(posedge clk);
            $display("TB : %t : Reading from address %h", $time, address);
            
            while(waitrequest) begin
                @(posedge clk);
            end

            read <= 0;
            @(posedge clk);
            $display("TB : %t : Read %h from address %h", $time, readdata, address);
        end
        
        $finish;
        
    end

    

endmodule