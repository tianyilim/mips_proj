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

    parameter BUF_BITS = 5;
    parameter BUFSIZE = $pow(2, BUF_BITS);  // Keeps it easy to keep track

    reg [31:0] data_buf [BUFSIZE-1:0];
    reg [3:0] byte_en_buf [BUFSIZE-1:0];

    logic [BUF_BITS-1:0] buf_ptr;           // Where is the most recently active item in the buffer?

    integer index;  // Iterator

    assign full = (buf_ptr == BUFSIZE-1);   // "full" if the buffer pointer is at the max val; can't take more stuff

    always @(posedge clk) begin
        if (reset) begin
            buf_ptr <= 0;
            for (index=0; index<BUFSIZE; index=index+1) begin
                data_buf[index] <= 0;
                byte_en_buf[index] <= 0;
            end
        end
        
    end



endmodule