`timescale 1ns / 1ns
module mips_cache_instr(
    input logic clk,
    input logic rst,
    
    // to cpu
    input logic[31:0] addr,
    input read_en,
    output logic[31:0] readdata,
    output logic stall, // Also goes to the cache controller

    // To cache controller
    input logic[31:0] data_in,
    input logic data_valid
);
    // Desiging a 4-way associative cache
    parameter CACHE_BITS = 5;
    parameter CACHE_SIZE = 2**CACHE_BITS;
    localparam CACHE_ASSOC = 4;  // 4-way. Not adjustable. Just for readability.
    localparam CACHE_ASSOC_BITS = 2;    // [4-bit one-hot becomes 2-bit.]
    localparam CACHE_DEPTH = CACHE_SIZE/CACHE_ASSOC;
    localparam CACHE_DEPTH_BITS = 3;    // Depth 8 -> 3 bit vals
    
    integer i;  // Iterators
    integer j;  

    // Cache registers (2d arrays)
    logic [31-CACHE_DEPTH_BITS:0] tags_buf [CACHE_DEPTH-1:0][CACHE_ASSOC-1:0];  // Holding tags
    logic [CACHE_ASSOC-1:0] valid_buf[CACHE_DEPTH-1:0];                  // Holding VALID (one-hot)
    logic [31:0] data_buf [CACHE_DEPTH-1:0][CACHE_ASSOC-1:0];             // Holding data
    logic [1:0] recent_buf [CACHE_DEPTH-1:0][CACHE_ASSOC-1:0];            // For LRU replacement policy

    logic [CACHE_ASSOC-1:0] cache_hit_bus;
    logic cache_hit;
    logic [CACHE_ASSOC_BITS-1:0] cache_assoc_index;   // Converts the cache_hit_bus into a proper index.

    logic [CACHE_DEPTH_BITS-1:0] cache_index; // Used to determine which index of the cache is being accessed
    logic [31:CACHE_DEPTH_BITS] cache_tag;    // Which exact mem address is cache referring to?

    logic [31:0] addr_offset;   // Offset the address bit to 
    assign addr_offset = addr >> 2;
    assign cache_index = addr_offset[CACHE_DEPTH_BITS-1:0];
    assign cache_tag = addr_offset[31:CACHE_DEPTH_BITS];

    // Do this translation here, as we don't want to do it again elsewhere.
    // CHECK - default value when cache_hit_bus=4'b0000: can't use this in STALL.
    always @ (cache_hit_bus) begin
        case (cache_hit_bus)
            4'b0001: cache_assoc_index = 2'b00;
            4'b0010: cache_assoc_index = 2'b01;
            4'b0100: cache_assoc_index = 2'b10;
            4'b1000: cache_assoc_index = 2'b11;
        endcase
    end
    
    // DEBUG
    wire[CACHE_ASSOC-1:0] curr_valid = valid_buf[cache_index];

    // no choice, can't do this in a loop with continous assignment
    // Valid is also one-hot
    assign cache_hit_bus[0] = valid_buf[cache_index][0] & tags_buf[cache_index][0] == cache_tag;
    assign cache_hit_bus[1] = valid_buf[cache_index][1] & tags_buf[cache_index][1] == cache_tag;
    assign cache_hit_bus[2] = valid_buf[cache_index][2] & tags_buf[cache_index][2] == cache_tag;
    assign cache_hit_bus[3] = valid_buf[cache_index][3] & tags_buf[cache_index][3] == cache_tag;

    assign cache_hit = |cache_hit_bus;  // Takes a bitwise OR of the whole bus
    assign stall = !cache_hit && read_en && !data_valid;   // Prone to error CHECK!
    // assign stall = !cache_hit && read_en;   // Prone to error CHECK!

    logic [31:0] readdata_reg;  // Output from registers
    assign readdata = (data_valid) ? data_in : readdata_reg;

    // Each time our cache doesn't hit we must stall cycle.
    // Exception is when writing an address that has byte_en 1111; the whole register will
    // Be modified anyway so it doesn't matter.

    always @ (posedge clk) begin
        // Reset behaviour
        if (rst) begin
            // $display("INSTR_CACHE : parameters : size:%d, depth:%d, assoc:%d", CACHE_SIZE, CACHE_DEPTH, CACHE_ASSOC);
            for (i=0; i<CACHE_DEPTH; i=i+1) begin
                valid_buf[i] <= 4'b0000;  // Valid is a 1d array actually
                for (j=0; j<CACHE_ASSOC; j=j+1) begin
                    // $display("INSTR_CACHE : resetting index i:%d, j:%d", i, j);
                    tags_buf[i][j] <= 0;
                    data_buf[i][j] <= 0;
                    // valid_buf[i][j] <= 0;  // Valid is a 1d array actually
                    recent_buf[i][j] <= 0;
                end
            end
        end else begin
            // $display("INSTR_CACHE : CYCLING..."); // DEBUG
            if (read_en) begin
                if (!cache_hit) begin
                    // Only action the write after valid data is in
                    // If byte_en is 1111 and we are writing, simply overwrite.
                    // CHECK if there is a write miss - does it resolve itself on the next cycle?
                    // $display("INSTR_CACHE : READ STALL, data_valid: %b", data_valid);  // DEBUG
                    // And in that case is it necessary to have extra byte_en logic?
                    if (data_valid) begin
                        $display("INSTR_CACHE : Replacement required: Valid buffer: %4b", valid_buf[cache_index]);
                        readdata_reg <= data_in;
                        // Trivial case - assoc with something not VALID - write into that.
                        // x: dont care. Use casex to include don't cares
                        // if xxx0; write to 0
                        // if xx01; write to 1
                        // if x011; write to 2
                        // if 0111; write to 3.
                        if (!(&valid_buf[cache_index])) begin
                            $display("INSTR_CACHE : Trivial case, current valid buffer is %4b", valid_buf[cache_index]);
                            casex (valid_buf[cache_index])
                                4'bxxx0: begin
                                    $display("INSTR_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[0], address 0x%h", data_in, cache_index, cache_tag, addr);
                                    tags_buf[cache_index][0] <= cache_tag;
                                    valid_buf[cache_index][0] <= 1;
                                    data_buf[cache_index][0] <= data_in;
                                    recent_buf[cache_index][0] <= 2'b11;    // Automatically the most-recent
                                    recent_buf[cache_index][1] <= 2'b10;    // Known state
                                    recent_buf[cache_index][2][1] <= 0;     // Unknown first bit
                                    recent_buf[cache_index][3][1] <= 0;    
                                end
                                4'bxx01: begin
                                    $display("INSTR_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[1], address 0x%h", data_in, cache_index, cache_tag, addr);
                                    tags_buf[cache_index][1] <= cache_tag;
                                    valid_buf[cache_index][1] <= 1;
                                    data_buf[cache_index][1] <= data_in;
                                    recent_buf[cache_index][0] <= 2'b10;    // Automatically the most-recent
                                    recent_buf[cache_index][1] <= 2'b11;    // Known state
                                    recent_buf[cache_index][2][1] <= 0;     // Unknown first bit
                                    recent_buf[cache_index][3][1] <= 0;    
                                end
                                4'bx011: begin
                                    $display("INSTR_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[2], address 0x%h", data_in, cache_index, cache_tag, addr);
                                    tags_buf[cache_index][2] <= cache_tag;
                                    valid_buf[cache_index][2] <= 1;
                                    data_buf[cache_index][2] <= data_in;
                                    recent_buf[cache_index][0][1] <= 0;     // Unknown first bit
                                    recent_buf[cache_index][1][1] <= 0;   
                                    recent_buf[cache_index][2] <= 2'b11;   
                                    recent_buf[cache_index][3] <= 2'b10; 
                                end
                                4'b0111: begin
                                    $display("INSTR_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[3], address 0x%h", data_in, cache_index, cache_tag, addr);
                                    tags_buf[cache_index][3] <= cache_tag;
                                    valid_buf[cache_index][3] <= 1;
                                    data_buf[cache_index][3] <= data_in;
                                    recent_buf[cache_index][0][1] <= 0;     // Unknown first bit
                                    recent_buf[cache_index][1][1] <= 0;   
                                    recent_buf[cache_index][2] <= 2'b10;
                                    recent_buf[cache_index][3] <= 2'b11;
                                end
                            endcase
                        end else begin
                            // Nontrivial case - write into assoc with 00 in the recent_buf
                            $display("INSTR_CACHE : Non-trivial case, recent buffers are 0:%b 1:%b 2:%b 3:%b", recent_buf[cache_index][0], recent_buf[cache_index][1], recent_buf[cache_index][2], recent_buf[cache_index][3]);
                            if (recent_buf[cache_index][0] == 2'b00) begin // 0 is LRU
                                $display("INSTR_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[0]", data_in, cache_index, cache_tag);
                                tags_buf[cache_index][0] <= cache_tag;
                                valid_buf[cache_index][0] <= 1;    
                                data_buf[cache_index][0] <= data_in;
                                recent_buf[cache_index][0] <= 2'b11;    // Automatically the most-recent
                                recent_buf[cache_index][1] <= 2'b10;    // Known state
                                recent_buf[cache_index][2][1] <= 0;     // Unknown first bit
                                recent_buf[cache_index][3][1] <= 0;    
                            end else if (recent_buf[cache_index][1] == 2'b00) begin // 1 is LRU
                                $display("INSTR_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[1]", data_in, cache_index, cache_tag);
                                tags_buf[cache_index][1] <= cache_tag;
                                valid_buf[cache_index][1] <= 1;
                                data_buf[cache_index][1] <= data_in;
                                recent_buf[cache_index][0] <= 2'b10;    // Automatically the most-recent
                                recent_buf[cache_index][1] <= 2'b11;    // Known state
                                recent_buf[cache_index][2][1] <= 0;     // Unknown first bit
                                recent_buf[cache_index][3][1] <= 0;                        
                            end else if (recent_buf[cache_index][2] == 2'b00) begin // 2 is LRU
                                $display("INSTR_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[2]", data_in, cache_index, cache_tag);
                                tags_buf[cache_index][2] <= cache_tag;
                                valid_buf[cache_index][2] <= 1;
                                data_buf[cache_index][2] <= data_in;
                                recent_buf[cache_index][0][1] <= 0;     // Unknown first bit
                                recent_buf[cache_index][1][1] <= 0;   
                                recent_buf[cache_index][2] <= 2'b11;   
                                recent_buf[cache_index][3] <= 2'b10; 
                            end else if (recent_buf[cache_index][3] == 2'b00) begin // 3 is LRU
                                $display("INSTR_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[3]", data_in, cache_index, cache_tag);
                                tags_buf[cache_index][3] <= cache_tag;
                                valid_buf[cache_index][3] <= 1;
                                data_buf[cache_index][3] <= data_in;
                                recent_buf[cache_index][0][1] <= 0;     // Unknown first bit
                                recent_buf[cache_index][1][1] <= 0;   
                                recent_buf[cache_index][2] <= 2'b10;
                                recent_buf[cache_index][3] <= 2'b11;                   
                            end
                        end
                    end
                    // $display("INSTR_CACHE : Not data_valid, wait another cycle"); // DEBUG
                end else begin
                    // handle the LRU aspect here
                    $display("INSTR_CACHE : READ HIT"); // DEBUG
                    if (read_en) begin
                        // Left/right tree of associative
                        if (cache_hit_bus==4'b0001 | cache_hit_bus==4'b0010) begin
                            recent_buf[cache_index][0][1] <= 1;
                            recent_buf[cache_index][1][1] <= 1;
                            recent_buf[cache_index][2][1] <= 0;
                            recent_buf[cache_index][3][1] <= 0;
                        end else if (cache_hit_bus==4'b0100 | cache_hit_bus==4'b1000) begin
                            recent_buf[cache_index][0][1] <= 0;
                            recent_buf[cache_index][1][1] <= 0;
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
                    
                        readdata_reg <= data_buf[cache_index][cache_assoc_index];
                        // $display("INSTR_CACHE : Read 0x%h from index 0x%h, assoc 0x%h", data_buf[cache_index][cache_assoc_index], cache_index, cache_index);
                    end
                end
            end else begin
                // $display("INSTR_CACHE : Stall not high; read_en not asserted"); // DEBUG
            end
        end
    end
endmodule