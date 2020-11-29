/*
TODO: LRU Replacement logic
Read and Write stalls
Byte enables when writing
*/

module mips_cache_data(
    input logic clk,
    input logic rst,
    
    // to cpu
    input logic[31:0] addr,
    input read_en,
    input write_en,
    input logic[31:0] writedata,
    input logic[3:0] byte_en,
    
    output logic[31:0] readdata,
    output logic stall,

    // To cache controller
    input logic[31:0] data_in,
    input logic[31:0] data_addr,
    input logic data_valid
);
    // Desiging a 4-way associative cache
    parameter CACHE_BITS = 5;
    parameter CACHE_SIZE = $pow(CACHE_BITS, 2);
    parameter CACHE_ASSOC = 4;  // 4-way
    parameter CACHE_DEPTH = CACHE_SIZE/CACHE_ASSOC;
    
    integer i;  // Iterators
    integer j;  

    // Cache registers (2d arrays)
    logic [31-CACHE_BITS:0] tags_buf [CACHE_DEPTH-1:0][CACHE_ASSOC-1:0];  // Holding tags
    logic [CACHE_DEPTH-1:0] valid_buf[CACHE_ASSOC-1:0];                  // Holding VALID
    logic [31:0] data_buf [CACHE_DEPTH-1:0][CACHE_ASSOC-1:0];             // Holding data
    logic [1:0] recent_buf [CACHE_DEPTH-1:0][CACHE_ASSOC-1:0];            // For LRU replacement policy

    logic [CACHE_ASSOC:0] cache_hit_bus;
    logic cache_hit;

    logic [CACHE_BITS-1:0] cache_index; // Used to determine which index of the cache is being accessed
    logic [31:CACHE_BITS] cache_tag;    // Which exact mem address is cache referring to?

    assign cache_index = addr[CACHE_BITS-1:0];
    assign cache_tag = addr[31:CACHE_BITS];
    
    for (i=0; i<CACHE_ASSOC; i=i+1) begin
        assign cache_hit_bus[i] = valid_buf[cache_index][i] & tags_buf[cache_index][i] == cache_tag;
    end

    assign cache_hit = |cache_hit_bus;  // Takes a bitwise OR of the whole bus
    assign stall = ~cache_hit;          // Each time our cache doesn't hit we must stall cycle.

    always @ (posedge clk) begin
        // Reset behaviour
        if (rst) begin
            for (i=0; i<CACHE_DEPTH; i=i+1) begin
                for (j=0; j<CACHE_ASSOC; j=j+1) begin
                    tags_buf[i][j] <= 0;
                    valid_buf[i][j] <= 0;
                    data_buf[i][j] <= 0;
                    byteen_buf[i][j] <= 0;
                    recent_buf[i][j] <= 0;
                end
            end
            stall <= 0;
        end else begin
            if (read_en) begin
                // Assert LRU here
                if (cache_hit_bus==4'b0001) begin
                    readdata <= data_buf[cache_index][0];
                end else if (cache_hit_bus==4'b0010) begin
                    readdata <= data_buf[cache_index][1];
                end else if (cache_hit_bus==4'b0100) begin
                    readdata <= data_buf[cache_index][2];
                end else if (cache_hit_bus==4'b1000) begin
                    readdata <= data_buf[cache_index][3];
                end
            end else if (write_en) begin
                // Assert LRU here
                // Handle byte enable here!
                for (j=0; j<CACHE_ASSOC; j=j+1) begin
                    if (tags_buf[cache_index][j] == cache_tag) begin
                        valid_buf[cache_index][j] <= 1;
                        data_buf[cache_index][j] <= writedata;
                        recent_buf[cache_index][j] <= j //? This is not complete.
                    end
                end
            end
        end
    end

    // HANDLE STALL HERE!
    // TODO What happens on write miss?

endmodule