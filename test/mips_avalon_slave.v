// Simple, parameterized implementation of an Avalon memory-mapped slave.
`timescale 1ns / 1ns
module mips_avalon_slave(
    input logic clk,

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
    parameter MEM_SIZE = 1024;
    localparam ADDR_END = MEM_SIZE + ADDR_START;
    localparam ADDR_START_SHIFT = ADDR_START >> 2;
    localparam ADDR_END_SHIFT = ADDR_END >> 2;
    
    parameter READ_DELAY = 2;               // How long will waitrequest be asserted on read?
    parameter WRITE_DELAY = READ_DELAY;     // How long will waitrequest be asserted on write?
    parameter DATA_INIT_FILE = "";          // 
    parameter RAM_INIT_FILE = "";           // Initialise RAM from elsewhere

    logic[31:0] towrite;                 // Just something to implement byteeenable
    reg[31:0] memory_data [MEM_SIZE-1:0];     // Data memory
    reg[31:0] memory_instr [MEM_SIZE-1:0];    // Instruction memory is contained here
    integer wait_ctr = -1;                   // Waits implemented here
    integer waiting = 0;

    logic[31:0] addr_shift;
    assign addr_shift = address >> 2; // Byte addressing

    initial begin
        integer i;
        /* Initialise to zero by default */
        for (i=0; i<MEM_SIZE; i++) begin
            memory_instr[i]=0;
            memory_data[i]=0;
        end
        /* Load contents from file if specified */
        if (RAM_INIT_FILE != "") begin
            $display("RAM : INIT : Loading Instr contents from %s", RAM_INIT_FILE);
            $readmemh(RAM_INIT_FILE, memory_instr);
        end
        if (DATA_INIT_FILE != "") begin
            $display("RAM : INIT : Loading Data contents from %s", RAM_INIT_FILE);
            $readmemh(DATA_INIT_FILE, memory_data);
        end

    end

    assign waitrequest = (read | write) & (wait_ctr != 0);

    always@(posedge clk) begin
        // Only respond if address is within address space
        if (address >= ADDR_START & address < ADDR_END) begin
            assert (!write) else $fatal(1,"RAM : FATAL : Tried to write to instruction area of memory with address 0x%h", address);
            if (read) begin
                if (waiting) begin
                    if (wait_ctr==0) begin
                        // Have waited relevant cycles, perform the write operation
                        waiting = 0;
                        wait_ctr = -1;
                        $display("RAM : READ : Read 0x%h data at address 0x%h", readdata, address);
                    end else if (wait_ctr==1) begin
                        readdata = memory_instr[addr_shift-ADDR_START_SHIFT];    // Offset the addressing space (and also in time)
                        wait_ctr = 0;
                    end else begin
                        wait_ctr = wait_ctr-1;  // Decrement wait counter
                        // $display("RAM : STATUS : Waiting for %1d more cycles before writing to address 0x%h", wait_ctr, address);
                    end
                end else begin
                    wait_ctr = READ_DELAY-1; // Offset for timing requirements
                    waiting = 1;
                    $display("RAM : STATUS : Read requested at address 0x%h, wait for %1d cycles", address, wait_ctr);
                end
            end
        end else if (address < MEM_SIZE) begin // Data memory section
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
                        memory_data[addr_shift] = towrite;    // Offset the addressing space
                        wait_ctr = -1;
                        $display("RAM : WRITE : Wrote 0x%h data at address 0x%h", writedata, address);
                    end else begin
                        wait_ctr = wait_ctr-1;  // Decrement wait counter
                        // $display("RAM : STATUS : Waiting for %1d more cycles before writing to address 0x%h", wait_ctr, address);
                    end
                end else begin
                    wait_ctr = WRITE_DELAY-1; // Offset for timing requirements
                    waiting = 1;
                    towrite = memory_data[addr_shift];   // Just fetch this first
                    $display("RAM : STATUS : Write 0x%h data request at address 0x%h, wait for %1d cycles", writedata, address, wait_ctr);
                end
            end else if (read) begin
                if (waiting) begin
                    if (wait_ctr==0) begin
                        // Have waited relevant cycles, perform the write operation
                        waiting = 0;
                        wait_ctr = -1;
                        $display("RAM : READ : Read 0x%h data at address 0x%h", readdata, address);
                    end else if (wait_ctr==1) begin
                        readdata = memory_data[addr_shift];    // Offset the addressing space (and also in time)
                        wait_ctr = 0;
                    end else begin
                        wait_ctr = wait_ctr-1;  // Decrement wait counter
                        // $display("RAM : STATUS : Waiting for %1d more cycles before writing to address 0x%h", wait_ctr, address);
                    end
                end else begin
                    wait_ctr = READ_DELAY-1; // Offset for timing requirements
                    waiting = 1;
                    $display("RAM : STATUS : Read requested at address 0x%h, wait for %1d cycles", address, wait_ctr);
                end
            end
        end else begin
            // $display("Address %h not in address space %h to %h", address, ADDR_START, ADDR_END);
        end
    end


endmodule