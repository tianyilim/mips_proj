/*
TODO: Pseudo-LRU Replacement logic
https://www.seas.upenn.edu/~cit595/cit595s10/handouts/LRUreplacementpolicy.pdf
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
    output logic stall, // Also goes to the cache controller

    // To cache controller
    output logic[31:0] data_addr,
    input logic[31:0] data_in,
    input logic data_valid
);
    // Desiging a 4-way associative cache
    parameter CACHE_BITS = 5;
    parameter CACHE_SIZE = $pow(CACHE_BITS, 2);
    localparam CACHE_ASSOC = 4;  // 4-way. Not adjustable. Just for readability.
    localparam CACHE_ASSOC_BITS = 2;    // [4-bit one-hot becomes 2-bit.]
    localparam CACHE_DEPTH = CACHE_SIZE/CACHE_ASSOC;
    
    integer i;  // Iterators
    integer j;  

    // Cache registers (2d arrays)
    logic [31-CACHE_BITS:0] tags_buf [CACHE_DEPTH-1:0][CACHE_ASSOC-1:0];  // Holding tags
    logic [CACHE_ASSOC-1:0] valid_buf[CACHE_DEPTH-1:0];                  // Holding VALID
    logic [31:0] data_buf [CACHE_DEPTH-1:0][CACHE_ASSOC-1:0];             // Holding data
    logic [1:0] recent_buf [CACHE_DEPTH-1:0][CACHE_ASSOC-1:0];            // For LRU replacement policy

    logic [CACHE_ASSOC-1:0] cache_hit_bus;
    logic cache_hit;
    logic [CACHE_ASSOC_BITS-1:0] cache_assoc_index;   // Converts the cache_hit_bus into a proper index.

    logic [CACHE_BITS-1:0] cache_index; // Used to determine which index of the cache is being accessed
    logic [31:CACHE_BITS] cache_tag;    // Which exact mem address is cache referring to?

    logic [31:0] towrite; // Intermediate signal for updating register; explicit wire

    assign cache_index = addr[CACHE_BITS-1:0];
    assign cache_tag = addr[31:CACHE_BITS];
    assign data_addr = addr;    // When we miss, passthrough address for request to cache controller.

    // Do this translation here, as we don't want to do it again elsewhere.
    // CHECK - default value when cache_hit_bus=4'b0000: can't use this in STALL.
    always @ (cache_hit_bus) begin
        case (cache_hit_bus)
            4'b0001: begin
                cache_assoc_index = 2'b00;
            end
            4'b0010: begin
                cache_assoc_index = 2'b01;
            end
            4'b0100: begin
                cache_assoc_index = 2'b10;
            end
            4'b1000: begin
                cache_assoc_index = 2'b11;
            end
        endcase
    end

    // no choice, can't do this in a loop with continous assignment
    assign cache_hit_bus[0] = valid_buf[cache_index][0] & tags_buf[cache_index][0] == cache_tag;
    assign cache_hit_bus[1] = valid_buf[cache_index][1] & tags_buf[cache_index][1] == cache_tag;
    assign cache_hit_bus[2] = valid_buf[cache_index][2] & tags_buf[cache_index][2] == cache_tag;
    assign cache_hit_bus[3] = valid_buf[cache_index][3] & tags_buf[cache_index][3] == cache_tag;

    assign cache_hit = |cache_hit_bus;  // Takes a bitwise OR of the whole bus
    assign stall = ~cache_hit;   // Prone to error CHECK!
    // Each time our cache doesn't hit we must stall cycle.
    // Exception is when writing an address that has byte_en 1111; the whole register will
    // Be modified anyway so it doesn't matter.

    always @ (posedge clk) begin
        // Reset behaviour
        if (rst) begin
            for (i=0; i<CACHE_DEPTH; i=i+1) begin
                for (j=0; j<CACHE_ASSOC; j=j+1) begin
                    tags_buf[i][j] <= 0;
                    valid_buf[i][j] <= 0;
                    data_buf[i][j] <= 0;
                    recent_buf[i][j] <= 0;
                end
            end
        end else begin
            if (stall) begin
                // Only action the write after valid data is in
                // If byte_en is 1111 and we are writing, simply overwrite.
                // CHECK if there is a write miss - does it resolve itself on the next cycle?

                // And in that case is it necessary to have extra byte_en logic?
                if (data_valid | (|byte_en && write_en)) begin
                    // Trivial case - assoc with something not VALID - write into that.
                    // x: dont care
                    // if 0xxxx; write to 0
                    // if 10xx; write to 1
                    // if 110x; write to 2
                    // and if 1110; write to 3.
                    if (|valid_buf[cache_index]) begin
                        case (valid_buf[cache_index])
                            4'b0xxx: begin
                                tags_buf[cache_index][0] <= cache_tag;
                                valid_buf[cache_index][0] <= 1;
                                data_buf[cache_index][0] <= readdata;
                                recent_buf[cache_index][0] <= 2'b11;    // Automatically the most-recent
                                recent_buf[cache_index][1] <= 2'b10;    // Known state
                                recent_buf[cache_index][2][0] <= 0;     // Unknown first bit
                                recent_buf[cache_index][3][0] <= 0;    
                            end
                            4'b10xx: begin
                                tags_buf[cache_index][1] <= cache_tag;
                                valid_buf[cache_index][1] <= 1;
                                data_buf[cache_index][1] <= readdata;
                                recent_buf[cache_index][0] <= 2'b10;    // Automatically the most-recent
                                recent_buf[cache_index][1] <= 2'b11;    // Known state
                                recent_buf[cache_index][2][0] <= 0;     // Unknown first bit
                                recent_buf[cache_index][3][0] <= 0;    
                            end
                            4'b110x: begin
                                tags_buf[cache_index][2] <= cache_tag;
                                valid_buf[cache_index][2] <= 1;
                                data_buf[cache_index][2] <= readdata;
                                recent_buf[cache_index][0][0] <= 0;     // Unknown first bit
                                recent_buf[cache_index][1][0] <= 0;   
                                recent_buf[cache_index][2] <= 2'b11;   
                                recent_buf[cache_index][3] <= 2'b10; 
                            end
                            4'b1110: begin
                                tags_buf[cache_index][3] <= cache_tag;
                                valid_buf[cache_index][3] <= 1;
                                data_buf[cache_index][3] <= readdata;
                                recent_buf[cache_index][0][0] <= 0;     // Unknown first bit
                                recent_buf[cache_index][1][0] <= 0;   
                                recent_buf[cache_index][2] <= 2'b10;
                                recent_buf[cache_index][3] <= 2'b11;
                            end
                        endcase
                    end else begin
                        // Nontrivial case - write into assoc with 00 in the recent_buf
                        if (recent_buf[cache_index][0] == 2'b00) begin // 0 is LRU
                            tags_buf[cache_index][0] <= cache_tag;
                            valid_buf[cache_index][0] <= 1;    
                            data_buf[cache_index][0] <= readdata;
                            recent_buf[cache_index][0] <= 2'b11;    // Automatically the most-recent
                            recent_buf[cache_index][1] <= 2'b10;    // Known state
                            recent_buf[cache_index][2][0] <= 0;     // Unknown first bit
                            recent_buf[cache_index][3][0] <= 0;    
                        end else if (recent_buf[cache_index][1] == 2'b00) begin // 1 is LRU
                            tags_buf[cache_index][1] <= cache_tag;
                            valid_buf[cache_index][1] <= 1;
                            data_buf[cache_index][1] <= readdata;
                            recent_buf[cache_index][0] <= 2'b10;    // Automatically the most-recent
                            recent_buf[cache_index][1] <= 2'b11;    // Known state
                            recent_buf[cache_index][2][0] <= 0;     // Unknown first bit
                            recent_buf[cache_index][3][0] <= 0;                        
                        end else if (recent_buf[cache_index][2] == 2'b00) begin // 2 is LRU
                            tags_buf[cache_index][2] <= cache_tag;
                            valid_buf[cache_index][2] <= 1;
                            data_buf[cache_index][2] <= readdata;
                            recent_buf[cache_index][0][0] <= 0;     // Unknown first bit
                            recent_buf[cache_index][1][0] <= 0;   
                            recent_buf[cache_index][2] <= 2'b11;   
                            recent_buf[cache_index][3] <= 2'b10; 
                        end else if (recent_buf[cache_index][3] == 2'b00) begin // 3 is LRU
                            tags_buf[cache_index][3] <= cache_tag;
                            valid_buf[cache_index][3] <= 1;
                            data_buf[cache_index][3] <= readdata;
                            recent_buf[cache_index][0][0] <= 0;     // Unknown first bit
                            recent_buf[cache_index][1][0] <= 0;   
                            recent_buf[cache_index][2] <= 2'b10;
                            recent_buf[cache_index][3] <= 2'b11;                   
                        end
                    end
                end
            end else begin
                // handle the LRU aspect here
                if (read_en | write_en) begin
                    // Left/right tree of associative
                    if (cache_hit_bus==4'b0001 | cache_hit_bus==4'b0010) begin
                        recent_buf[cache_index][0][1] <= 1;
                        recent_buf[cache_index][1][1] <= 1;
                    end else if (cache_hit_bus==4'b0100 | cache_hit_bus==4'b1000) begin
                        recent_buf[cache_index][2][1] <= 1;
                        recent_buf[cache_index][3][1] <= 1;
                    end

                    // Lower associative
                    case (cache_hit_bus)
                        4'b0001: begin
                            recent_buf[cache_index][0][0] <= 1;
                            recent_buf[cache_index][1][0] <= 0;
                        end
                        4'b0010: begin
                            recent_buf[cache_index][0][0] <= 0;
                            recent_buf[cache_index][1][0] <= 1;
                        end
                        4'b0100: begin
                            recent_buf[cache_index][2][0] <= 1;
                            recent_buf[cache_index][3][0] <= 0;
                        end
                        4'b1000: begin
                            recent_buf[cache_index][2][0] <= 0;
                            recent_buf[cache_index][3][0] <= 1;
                        end
                    endcase

                end

                if (read_en) begin
                    // Assign return vals
                    readdata <= data_buf[cache_index][cache_assoc_index];

                end else if (write_en) begin
                    // Modify values - Cache miss but byte_en==4'b1111 is handled above.
                    towrite[31:24] = (byte_en[3]) ? writedata[31:24] : data_buf[cache_index][cache_assoc_index][31:24];
                    towrite[23:16] = (byte_en[2]) ? writedata[23:16] : data_buf[cache_index][cache_assoc_index][23:16];
                    towrite[15:8] =  (byte_en[1]) ? writedata[15:8] : data_buf[cache_index][cache_assoc_index][15:8];
                    towrite[7:0] =   (byte_en[0]) ? writedata[7:0] : data_buf[cache_index][cache_assoc_index][7:0];
                    data_buf[cache_index][cache_assoc_index] <= towrite;
                end
            end
        end
    end

    // HANDLE STALL HERE!
    // TODO What happens on write miss?

endmodule