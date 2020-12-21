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
    output logic[31:0] readdata,
    input logic finishing
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

    logic[31:0] addr_shift;
    assign addr_shift = address >> 2; // Byte addressing

    logic read_txn;                    // Determines when a read/write transaction ends
    logic write_txn;
    logic [31:0] txn_addr;
    logic [31:0] txn_writedata;
    logic [3:0] txn_byteenable;     // Check that these 3 are not modified over the course of a transaction

    logic past_read;

    logic OVF_EXISTS;   // Check if there is indeed a request to fill up overflow

    logic [1:0] readdata_source;

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

        if ( (read_txn && !read) || ( write_txn && (!write && wait_ctr<WRITE_DELAY) ) ) begin
            // $fatal(1, "RAM : FATAL : Read/write not held high through transaction");
            $fatal(1, "RAM : FATAL : Read/write not held high through transaction");
        end
        
        if (read_txn) begin
            // ignore the first instance of waitrequest assertion, as txn_addr has not been asserted yet.
            if (address != txn_addr) begin
                $fatal(1, "RAM : FATAL : Address not constant through READ transaction, Address=0x%h, Txn_addr=0x%h", address, txn_addr);
            end
        end

        if (write_txn) begin
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

        if (read && (wait_ctr==READ_DELAY) && readdata_source==2'b11) begin
            $fatal(1, "RAM : FATAL : Attempted to read initialised address 0x%h", address);
        end

        if (write && (wait_ctr==WRITE_DELAY) && readdata_source!=2'b01) begin
            $fatal(1, "RAM : FATAL : Attempted to write to invalid address 0x%h", address);
        end
    end
    
    // Initialise RAM
    initial begin
        integer i;
        read_txn <= 0;
        write_txn <= 0;
        past_read <= 0;
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

    always @ (negedge clk) begin
        if (finishing==1) begin
            $display("RAM : FIN : Dumping memory content.");
            $writememh("test/3-output/memory_out.hex", memory_data, 0, 200);
        end
    end

    assign waitrequest = ( (wait_ctr<WRITE_DELAY) && (write_txn||write) ) || ( (wait_ctr<READ_DELAY) && (read_txn||read) );

    assign write_prefetch = memory_data[addr_shift];
    assign towrite[31:24] = (byteenable[3]) ? writedata[31:24] : write_prefetch[31:24];
    assign towrite[23:16] = (byteenable[2]) ? writedata[23:16] : write_prefetch[23:16];
    assign towrite[15:8] =  (byteenable[1]) ? writedata[15:8] : write_prefetch[15:8];
    assign towrite[7:0] =   (byteenable[0]) ? writedata[7:0] : write_prefetch[7:0];

    always_ff @ (posedge clk) begin
        if ( read && (wait_ctr==READ_DELAY) ) begin
            case (readdata_source)
            2'b00: readdata <= memory_instr[addr_shift-ADDR_START_SHIFT];
            2'b01: readdata <= memory_data[addr_shift];
            2'b10: readdata <= ovf_instr[addr_shift-(32'hBFFFFFFC >> 2)];
            default: readdata <= 32'hZZZZZZZZ;
            endcase
        end else begin
            readdata <= 32'hZZZZZZZZ;
        end
    end

    // mux outputs
    always_comb begin
        if (address >= ADDR_START & address < ADDR_END) begin
            readdata_source = 2'b00;
        end else if (address < MEM_SIZE) begin // Data memory section
            readdata_source = 2'b01;
        end else if (OVF_EXISTS && (address>=32'hBFFFFFFC) && (address<=32'hC000001C)) begin
            readdata_source = 2'b10;
        end else begin
            readdata_source = 2'b11;
        end
    end

    // Remaining stuff - incrementing wait counters, write
    always@(posedge clk) begin
        if (read) begin
                if (READ_DELAY != 0) begin
                    wait_ctr <= wait_ctr + 1;
                end
            if (wait_ctr==READ_DELAY) begin
            end else begin
                $display("RAM : STATUS : Read requested at address 0x%h, wait for %1d cycles", address, READ_DELAY-wait_ctr);
                if (wait_ctr==0) txn_addr <= address;
            end
        end

        if (write_txn || write) begin
            wait_ctr <= wait_ctr + 1;

            if (wait_ctr==WRITE_DELAY) begin
                memory_data[addr_shift] <= towrite;    // Offset the addressing space
                $display("RAM : WRITE : Wrote 0x%h data at address 0x%h", writedata, address);
            end else begin
                $display("RAM : STATUS : Write 0x%h data request at address 0x%h, wait for %1d cycles", writedata, address, WRITE_DELAY-wait_ctr);
                if (wait_ctr==0) begin
                    txn_addr <= address;
                    txn_byteenable <= byteenable;
                    txn_writedata <= writedata;
                end
            end
        end

        // Begin a transaction
        if (read && read_txn==0 && READ_DELAY!=0 ) begin
            read_txn <= 1;
        end
        // end a transaction
        if (read_txn==1 && wait_ctr>=READ_DELAY ) begin
            read_txn <= 0;
            wait_ctr <= 0;
        end

        if (wait_ctr==READ_DELAY && read) begin
            past_read <= 1;
        end else begin
            past_read <= 0;
        end
        // Output stuff onto stdout
        if (past_read==1) begin
            $display("RAM : READ : Read 0x%h data at address 0x%h", readdata, address);
        end else begin
            // $display("RAM : READ : Waiting to read 0x%h data at address 0x%h, %b", readdata, address, past_read);
        end
        // Begin a transaction
        if (write && write_txn==0 ) begin
            write_txn <= 1;
        end
        // end a transaction
        if (wait_ctr>=WRITE_DELAY) begin
            write_txn <= 0;
            wait_ctr <= 0;
        end

    end

endmodule