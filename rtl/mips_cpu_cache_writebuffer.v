`timescale 1ns / 1ns
module mips_cache_writebuffer(
    input logic clk,
    input logic rst,
    
    input logic[31:0] addr,
    input logic[31:0] instr_addr,

    input write_en,
    input logic[31:0] writedata,
    input logic[3:0] byteenable,

    output logic addr_in_wb,        // is the current data address contained in
                                    // in the WB?
                                    // if so, is there a risk of cache in-coherency?

    input logic active,             // Enable this when the module is to be active
                                    // Sometimes we need to temporarily stop writing
                                    // and 'hijack' the process for a read miss.
    
    input logic waitrequest,        // When to write the next byte?
    output logic[31:0] write_addr,  // Address to write to avalon bus
    output logic[31:0] write_data, 
    output logic[3:0] write_byteenable, // Signals from the internal write buffer 
    output logic write_writeenable,

    output logic[1:0] state_out,    // Debug

    output logic full,               // Assert when write buffer is filled!
    output logic empty               // Assert when empty (debug output)
);

    typedef enum logic[1:0] {
        STATE_IDLE = 2'd0,
        STATE_WRITE = 2'd1,
        STATE_FULL = 2'd2
    } state_t;

    parameter BUF_BITS = 3;
    parameter BUFSIZE = 2**BUF_BITS;  // Keeps it easy to keep track

    reg [BUFSIZE-1:0] full_buf; 
    reg [31:0] addr_buf [BUFSIZE-1:0];
    reg [31:0] data_buf [BUFSIZE-1:0];
    reg [3:0] byte_en_buf [BUFSIZE-1:0];

    logic [1:0] state;
    logic [BUF_BITS-1:0] read_ptr;           // Pointer for Cache to write to WB
    logic [BUF_BITS-1:0] write_ptr;          // Pointer for WB to write to MEM

    logic [BUFSIZE-1:0] addr_in_wb_arr;     // Keeps track if the current address is in the buffer

    logic write_sense;                      // Only take the first write in the case where write_en is high

    integer index;  // Iterator for reset

    // Combinatorial FULL/EMPTY
    assign full = full_buf==(2**BUFSIZE-1);
    assign empty = full_buf==0;
    assign state_out = state;   // Debug
    assign write_writeenable = !empty && active; // Write when there are things to write - and when we are allowed to!

    assign write_addr = addr_buf[write_ptr];
    assign write_data = data_buf[write_ptr];
    assign write_byteenable = byte_en_buf[write_ptr];   // These can be combinatorially assigned as write is handled elsewhere

    always_comb begin
        for (index=0; index<BUFSIZE; index=index+1) begin
            addr_in_wb_arr[index] = (addr==addr_buf[index]) || (instr_addr==addr_buf[index]);
        end
        addr_in_wb = |addr_in_wb_arr;   // Take the bitwise or
    end

    always @(posedge clk) begin
        if (rst) begin
            // $display("WB : Reset");
            state <= STATE_IDLE;
            read_ptr <= 0;
            write_ptr <= 0;
            write_sense <= 0;
            for (index=0; index<BUFSIZE; index=index+1) begin
                full_buf[index] <= 0;
                addr_buf[index] <= 0;
                data_buf[index] <= 0;
                byte_en_buf[index] <= 0;
            end
        end else begin  // unreset behaviour
            write_sense <= write_en;
            // $display("WB : Unreset");
            // writing always happens when not empty unless active low
            if (active) begin
                // $display("WB : Active");
                // if (write_valid) begin
                //     // Only do this the cycle after waitrequest
                //     write_ptr <= write_ptr + 1;
                // end
                // write_ptr <= write_ptr + (state!=STATE_IDLE || write_valid);

                if (full_buf[write_ptr]) begin
                    if (!waitrequest) begin
                        full_buf[write_ptr] <= 0;
                        write_ptr <= write_ptr + 1;
                    end
                end else begin
                    // Keep on incrementing the write pointer encounters empty
                    // If not empty
                    write_ptr <= write_ptr + (state!=STATE_IDLE);
                end
            end

            case (state)
            STATE_IDLE: begin
                if (write_en && !write_sense) begin
                    full_buf[read_ptr] <= 1;
                    addr_buf[read_ptr] <= addr;
                    data_buf[read_ptr] <= writedata;
                    byte_en_buf[read_ptr] <= byteenable;

                    read_ptr <= read_ptr + 1;    // ovf is intentional
                end
            end
            STATE_WRITE: begin
                // full check
                if (full_buf== (2**BUFSIZE-1) ) begin
                    state <= STATE_FULL;        // Dont' accept any more write requests
                    read_ptr <= write_ptr;      
                    // Our next empty slot for reading is the one currently being written out of
                    // full <= 1;
                end else if (write_en && !write_sense) begin    // elseif is here - won't read anything if fulled
                    full_buf[read_ptr] <= 1;
                    addr_buf[read_ptr] <= addr;
                    data_buf[read_ptr] <= writedata;
                    byte_en_buf[read_ptr] <= byteenable;

                    read_ptr <= read_ptr + 1;    // ovf is intentional

                end else if (full_buf==0) begin
                    state <= STATE_IDLE;
                    read_ptr <= 0;
                    write_ptr <= 0;
                end
            end
            STATE_FULL: begin
                if (full_buf != BUFSIZE-1) begin
                    state <= STATE_WRITE;
                    // Writing is an always process
                end
            end
            endcase
        end
    end



endmodule