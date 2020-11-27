module mips_cache_writebuffer(
    input logic clk,
    input logic rst,
    
    input logic[31:0] addr,
    input write_en,
    input logic[31:0] writedata,
    input logic[3:0] byteenable,
    
    input logic waitrequest,        // When to write the next byte?
    output logic[31:0] write_addr,  // Address to write to avalon bus
    output logic[31:0] write_data, 
    output logic[3:0] write_byteenable, // Signals from the internal write buffer 
    output logic write_writeenable,

    output logic full               // Assert when write buffer is filled!
);

    typedef enum logic[1:0] {
        STATE_IDLE = 3'd0,
        STATE_WRITE = 3'd1,
        STATE_FULL = 3'd2
    } state_t;

    parameter BUF_BITS = 5;
    parameter BUFSIZE = $pow(2, BUF_BITS);  // Keeps it easy to keep track

    reg full_buf [BUFSIZE-1:0]; 
    reg [31:0] addr_buf [BUFSIZE-1:0];
    reg [31:0] data_buf [BUFSIZE-1:0];
    reg [3:0] byte_en_buf [BUFSIZE-1:0];

    logic [1:0] state;
    logic [BUF_BITS-1:0] read_ptr;           // Pointer for Cache to write to WB
    logic [BUF_BITS-1:0] write_ptr;          // Pointer for WB to write to MEM

    integer index;  // Iterator for reset

    always @(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
            read_ptr <= 0;
            write_ptr <= 0;
            full <= 0;
            for (index=0; index<BUFSIZE; index=index+1) begin
                full_buf[index] <= 0;
                addr_buf[index] <= 0;
                data_buf[index] <= 0;
                byte_en_buf[index] <= 0;
            end
        end else begin  // unreset behaviour

            // writing always happens when not empty
            if (full_buf[write_ptr]) begin
                write_writeenable <= 1;
                write_addr <= addr_buf[write_ptr];
                write_data <= data_buf[write_ptr];
                write_byteenable <= byte_en_buf[write_ptr];
                if (~waitrequest) begin
                    // Only do this after waitrequest not asserted
                    write_writeenable <= 1;
                    full_buf[write_ptr] <= 0;
                    write_ptr <= write_ptr + 1;
                end
            end else begin
                // Keep on incrementing the write pointer unless really not meant to
                write_ptr <= write_ptr + (state!=STATE_IDLE);
            end

            case (state)
            STATE_IDLE: begin
                if (write_en) begin
                    full_buf[read_ptr] <= 1;
                    addr_buf[read_ptr] <= addr;
                    data_buf[read_ptr] <= writedata;
                    byte_en_buf[read_ptr] <= byteenable;

                    read_ptr <= read_ptr + 1;    // ovf is intentional
                    state <= STATE_WRITE;
                end
            end
            STATE_WRITE: begin
                // full check
                if (full_buf==BUFSIZE-1) begin
                    state <= STATE_FULL;        // Dont' accept any more write requests
                    read_ptr <= write_ptr;      
                    // Our next empty slot for reading is the one currently being written out of
                    full <= 1;
                end else if (write_en) begin    // elseif is here - won't read anything if fulled
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
                    full <= 0;
                    state <= STATE_WRITE;
                    // Writing is an always process
                end
            end
        end
        
    end



endmodule