// Simple, parameterized implementation of an Avalon memory-mapped slave.

module mips_avalon_slave(
    input logic clk,
    input logic rst,

    input logic[31:0] address,
    input logic write,
    input logic read,
    input logic[31:0] writedata,
    input logic[3:0] byteenable,

    output logic waitrequest,
    output logic[31:0] readdata
);

    // Implements a memory-mapped avalon controller RAM module
    // Not synthesizable!

    parameter ADDR_START = 32'hBFC00000;    // By default, aligned to the start of the memory space
    parameter MEM_SIZE = 8;
    integer ADDR_END = MEM_SIZE + ADDR_START;
    parameter READ_DELAY = 2;               // How long will waitrequest be asserted on read?
    parameter WRITE_DELAY = READ_DELAY;     // How long will waitrequest be asserted on write?
    parameter RAM_INIT_FILE = "";           // Initialise RAM from elsewhere

    logic[31:0] towrite;                 // Just something to implement byteeenable
    reg[31:0] memory [MEM_SIZE-1:0];    // Memory is contained here
    integer wait_ctr = -1;                   // Waits implemented here
    integer waiting = 0;

    initial begin
        integer i;
        /* Initialise to zero by default */
        for (i=0; i<MEM_SIZE; i++) begin
            memory[i]=0;
        end
        /* Load contents from file if specified */
        if (RAM_INIT_FILE != "") begin
            $display("RAM : INIT : Loading RAM contents from %s", RAM_INIT_FILE);
            $readmemh(RAM_INIT_FILE, memory);
        end
    end

    assign waitrequest = (read | write) & (wait_ctr != 0);

    always@(posedge clk) begin
        // Only respond if address is within address space
        if (address >= ADDR_START & address < ADDR_END) begin
            if (write) begin
                if (waiting) begin
                    if (wait_ctr==0) begin
                        // Have waited relevant cycles, perform the write operation
                        // Damn, this feels inefficient...
                        waiting = 0;
                        towrite[31:24] = (byteenable[3]) ? writedata[31:24] : towrite[31:24];
                        towrite[23:16] = (byteenable[2]) ? writedata[23:16] : towrite[23:16];
                        towrite[15:8] =  (byteenable[1]) ? writedata[15:8] : towrite[15:8];
                        towrite[7:0] =   (byteenable[0]) ? writedata[7:0] : towrite[7:0];
                        memory[address-ADDR_START] = towrite;    // Offset the addressing space
                        wait_ctr = -1;
                        $display("RAM : WRITE : Wrote %h data at address %h", writedata, address);
                    end else begin
                        wait_ctr = wait_ctr-1;  // Decrement wait counter
                        $display("RAM : STATUS : Waiting for %d more cycles before writing to address %h", wait_ctr, address);
                    end
                end else begin
                    wait_ctr = WRITE_DELAY-1; // Offset for timing requirements
                    waiting = 1;
                    towrite = memory[address-ADDR_START];   // Just fetch this first
                    $display("RAM : STATUS : Write requested at address %h, wait for %d cycles", address, wait_ctr);
                end
            end else if (read) begin
                if (waiting) begin
                    if (wait_ctr==0) begin
                        // Have waited relevant cycles, perform the write operation
                        waiting = 0;
                        wait_ctr = -1;
                        $display("RAM : READ : Read %h data at address %h", readdata, address);
                    end else if (wait_ctr==1) begin
                        readdata = memory[address-ADDR_START];    // Offset the addressing space (and also in time)
                        wait_ctr = 0;
                    end else begin
                        wait_ctr = wait_ctr-1;  // Decrement wait counter
                        $display("RAM : STATUS : Waiting for %d more cycles before writing to address %h", wait_ctr, address);
                    end
                end else begin
                    wait_ctr = READ_DELAY-1; // Offset for timing requirements
                    waiting = 1;
                    $display("RAM : STATUS : Read requested at address %h, wait for %d cycles", address, wait_ctr);
                end
            end
        end else begin
            // $display("Address %h not in address space %h to %h", address, ADDR_START, ADDR_END);
        end
    end


endmodule