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
    
    parameter READ_DELAY = 2;               // How long will waitrequest be asserted on read? (can be 0)
    parameter WRITE_DELAY = READ_DELAY;
    // parameter WRITE_DELAY = 100;
    // parameter WRITE_DELAY = (READ_DELAY==0) ? 1 : READ_DELAY;     // How long will waitrequest be asserted on write?
    parameter DATA_INIT_FILE = "";          // 
    parameter RAM_INIT_FILE = "";           // Initialise instruction part (ROM)
    parameter OVF_INIT_FILE = "";           // Initialise extended instructions

    wire[31:0] towrite;                 // Just something to implement byteeenable
    wire[31:0] write_prefetch;

    reg[31:0] memory_data [MEM_SIZE-1:0];     // Data memory
    reg[31:0] memory_instr [MEM_SIZE-1:0];    // Instruction memory is contained here
    reg[31:0] ovf_instr [7:0];

    integer wait_ctr = 0;                   // Waits implemented here
    integer waiting = 0;

    logic[31:0] addr_shift;
    assign addr_shift = address >> 2; // Byte addressing

    logic [31:0] txn_addr;
    logic [31:0] txn_writedata;
    logic [3:0] txn_byteenable;     // Check that these 3 are not modified over the course of a transaction

    logic OVF_EXISTS;   // Check if there is indeed a request to fill up overflow

    logic [31:0] readdata_mux;      // Implements the final output of readdata

    // Assertions go here
    always@(negedge clk) begin
        if (!$isunknown(address) && |address[1:0] && (read || write)) begin
            $fatal(1, "RAM : FATAL : Attempted to access a non word-aligned address 0x%h", address);
        end

        // if ( (wait_ctr != -1) && !(read || write) ) begin
        //     $fatal(1, "RAM : FATAL : De-asserted read or write before termination of a transaction");
        // end

        if ((!$isunknown(read) && !$isunknown(write)) && ( read && write ) ) begin
            $fatal(1, "RAM : FATAL : Read and write asserted at the same time, read: %b, write: %b", read, write);
        end

        if ( waitrequest && !(read || write)) begin
            // $fatal(1, "RAM : FATAL : Read/write not held high through transaction");
            $display("RAM : FATAL : Read/write not held high through transaction, %b, %b, %b", waitrequest, read, write);
        end
        
        if (waitrequest && read && (wait_ctr != 0)) begin
            // ignore the first instance of waitrequest assertion, as txn_addr has not been asserted yet.
            if (address != txn_addr) begin
                $fatal(1, "RAM : FATAL : Address not constant through READ transaction, Address=0x%h, Txn_addr=0x%h", address, txn_addr);
            end
        end

        if (waitrequest && write && (wait_ctr != 0)) begin
            if (address != txn_addr) begin
                $fatal(1, "RAM : FATAL : Address not constant through WRITE transaction, Address=0x%h, Txn_addr=0x%h", address, txn_addr);
            end
            if (writedata != txn_writedata) begin
                $fatal(1, "RAM : FATAL : Writedata not constant through WRITE transaction");
            end
            if (byteenable != txn_byteenable) begin
                $fatal(1, "RAM : FATAL : byteenable not constant through WRITE transaction");
            end
        end
    end
    
    // Initialise RAM
    initial begin
        integer i;
        $display("RAM : INIT : Initialising RAM module with read delay %1d and write delay %1d", READ_DELAY, WRITE_DELAY);
        /* Initialise to zero by default */
        for (i=0; i<MEM_SIZE; i++) begin
            memory_instr[i]=0;
            memory_data[i]=0;
        end
        /* Load contents from file if specified */
        if (RAM_INIT_FILE != "") begin
            $display("RAM : INIT : Loading Instr contents from %s", RAM_INIT_FILE);
            $readmemh(RAM_INIT_FILE, memory_instr);
        end else begin
            $fatal(1, "RAM : FATAL : Unable to find Instr Init file");
        end

        if (DATA_INIT_FILE != "") begin
            $display("RAM : INIT : Loading Data contents from %s", DATA_INIT_FILE);
            $readmemh(DATA_INIT_FILE, memory_data);
        end else begin
            $fatal(1, "RAM : FATAL : Unable to find Data Init file");
        end

        // Ovf_instr sits from 0xBFFFFFFC to 0xC000001C
        if (OVF_INIT_FILE !="") begin
            $display("RAM : INIT : Loading Overflow Check contents from %s", OVF_INIT_FILE);
            $readmemh(OVF_INIT_FILE, ovf_instr);
            OVF_EXISTS = 1'b1;
        end else begin
            // No overflow file required
            $display("RAM : INIT : No Overflow check content required.");
            OVF_EXISTS = 1'b0;
        end
    end

    assign waitrequest = ( (read && wait_ctr!=READ_DELAY) || (write && wait_ctr!=WRITE_DELAY) );
    assign write_prefetch = memory_data[addr_shift];
    assign towrite[31:24] = (byteenable[3]) ? writedata[31:24] : write_prefetch[31:24];
    assign towrite[23:16] = (byteenable[2]) ? writedata[23:16] : write_prefetch[23:16];
    assign towrite[15:8] =  (byteenable[1]) ? writedata[15:8] : write_prefetch[15:8];
    assign towrite[7:0] =   (byteenable[0]) ? writedata[7:0] : write_prefetch[7:0];

    // read might be combinatorial
    always_comb begin
        if (read && wait_ctr==READ_DELAY) begin
            if (address >= ADDR_START & address < ADDR_END) begin   // instr section
                readdata = memory_instr[addr_shift-ADDR_START_SHIFT];
            end else if (address < MEM_SIZE) begin // Data memory section
                readdata = memory_data[addr_shift];
            end else if (OVF_EXISTS && (address>=32'hBFFFFFFC) && (address<=32'hC000001C)) begin
                readdata = ovf_instr[addr_shift-(32'hBFFFFFFC >> 2)];
            end
        end
    end

    // assign readdata = (wait_ctr==0) ? 

    always@(posedge clk) begin

        if (read) begin
            if (wait_ctr==READ_DELAY) begin
                $display("RAM : READ : Read 0x%h data at address 0x%h", readdata, address);
            end else begin
                $display("RAM : STATUS : Read requested at address 0x%h, wait for %1d cycles", address, READ_DELAY-wait_ctr);
            end
        end

        if (write) begin
            if (wait_ctr==WRITE_DELAY) begin
                memory_data[addr_shift] <= towrite;    // Offset the addressing space
                $display("RAM : WRITE : Wrote 0x%h data at address 0x%h", writedata, address);
            end else begin
                $display("RAM : STATUS : Write 0x%h data request at address 0x%h, wait for %1d cycles", writedata, address, WRITE_DELAY-wait_ctr);
            end
        end
        
        // Only respond if address is within address space
        if (address >= ADDR_START & address < ADDR_END) begin
            assert (!write) else $display("RAM : FATAL : Tried to write to instruction area of memory with address 0x%h", address);
            if (read) begin
                if (wait_ctr != READ_DELAY) begin
                    if (wait_ctr==0) txn_addr <= address;
                    wait_ctr = wait_ctr + 1;    // Just increment wait counter haha
                end else begin
                    wait_ctr = 0;
                end
            end
        end else if (address < MEM_SIZE) begin // Data memory section
            if (write) begin
                if (wait_ctr != WRITE_DELAY) begin
                    if (wait_ctr==0) begin
                        txn_addr <= address;
                        txn_byteenable <= byteenable;
                        txn_writedata <= writedata;
                    end
                    wait_ctr = wait_ctr + 1;    // Just increment wait counter haha
                end else begin
                    wait_ctr = 0;
                end
            end else if (read) begin
                if (wait_ctr != READ_DELAY) begin
                    if (wait_ctr==0) txn_addr <= address;
                    wait_ctr = wait_ctr + 1;    // Just increment wait counter haha
                end else begin
                    wait_ctr = 0;
                end
            end
        end else if (OVF_EXISTS && (address>=32'hBFFFFFFC) && (address<=32'hC000001C)) begin
            assert (!write) else $display("RAM : FATAL : Tried to write to instruction overflow area of memory with address 0x%h", address);
            if (read) begin
                if (wait_ctr != READ_DELAY) begin
                    if (wait_ctr==0) txn_addr <= address;
                    wait_ctr = wait_ctr + 1;    // Just increment wait counter haha
                end else begin
                    wait_ctr = 0;
                end
            end
        end else begin
            // $display("RAM : FATAL : Attempted to access 0x%h, not in data space 0x%h to 0x%h or instruction space 0x%h to 0x%h", address, 0, MEM_SIZE, ADDR_START, ADDR_END);
            if ($isunknown(address)) begin
            end else begin
                if (read || write) begin
                    if (OVF_EXISTS) begin
                        $fatal(1, "RAM : FATAL : Attempted to access 0x%h, not in data space 0x%h to 0x%h, instruction space 0x%h to 0x%h, or overflow space 0xBFFFFFFC to 0xC000001C", address, 0, MEM_SIZE, ADDR_START, ADDR_END);
                    end else begin
                        $fatal(1, "RAM : FATAL : Attempted to access 0x%h, not in data space 0x%h to 0x%h or instruction space 0x%h to 0x%h", address, 0, MEM_SIZE, ADDR_START, ADDR_END);
                    end
                end
            end
        end
    end

endmodule