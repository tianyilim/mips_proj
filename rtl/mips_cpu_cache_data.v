/*
Pseudo-LRU Replacement logic https://www.seas.upenn.edu/~cit595/cit595s10/handouts/LRUreplacementpolicy.pdf
*/
`timescale 1ns / 1ns
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

    logic [31:0] towrite; // Intermediate signal for updating register; explicit wire

    logic [31:0] addr_offset;   // Offset the address bit to 
    assign addr_offset = addr >> 2;
    assign cache_index = addr_offset[CACHE_DEPTH_BITS-1:0];
    assign cache_tag = addr_offset[31:CACHE_DEPTH_BITS];

    logic [31:0] readdata_reg;  // Output from registers
    assign readdata = (data_valid) ? data_in : readdata_reg;

    // // Implementing byte_enable as we write
    // wire [31:0] reg_in_tmp [CACHE_ASSOC-1:0];    // Byte_enable implementation
    // wire [31:0] reg_input [CACHE_ASSOC-1:0]; // Implements the Byte_enable case when writing

    // genvar i2;
    // generate
    //     for(i2=0; i2<CACHE_ASSOC; i2=i2+1) begin
    //             assign reg_in_tmp[i2][31:24] = (byte_en[3]) ? writedata[31:24] : data_buf[cache_index][i2][31:24];
    //             assign reg_in_tmp[i2][23:16] = (byte_en[2]) ? writedata[23:16] : data_buf[cache_index][i2][23:16];
    //             assign reg_in_tmp[i2][15:8] =  (byte_en[1]) ? writedata[15:8] : data_buf[cache_index][i2][15:8];
    //             assign reg_in_tmp[i2][7:0]  =  (byte_en[0]) ? writedata[7:0] : data_buf[cache_index][i2][7:0];

    //             assign reg_input[i2] = (read_en) ? data_in : reg_in_tmp[i2];    
    //     end
    // endgenerate

    wire [31:0] reg_in_tmp;    // Byte_enable implementation
    wire [31:0] reg_input; // Implements the Byte_enable case when writing

    assign reg_in_tmp[31:24] = (byte_en[3]) ? writedata[31:24] : data_in[31:24];
    assign reg_in_tmp[23:16] = (byte_en[2]) ? writedata[23:16] : data_in[23:16];
    assign reg_in_tmp[15:8] =  (byte_en[1]) ? writedata[15:8] : data_in[15:8];
    assign reg_in_tmp[7:0]  =  (byte_en[0]) ? writedata[7:0] : data_in[7:0];
    assign reg_input = (read_en) ? data_in : reg_in_tmp;

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
    wire write_cond;
    assign write_cond = data_valid || (&byte_en && write_en);


    // no choice, can't do this in a loop with continous assignment
    // Valid is also one-hot
    assign cache_hit_bus[0] = valid_buf[cache_index][0] & tags_buf[cache_index][0] == cache_tag;
    assign cache_hit_bus[1] = valid_buf[cache_index][1] & tags_buf[cache_index][1] == cache_tag;
    assign cache_hit_bus[2] = valid_buf[cache_index][2] & tags_buf[cache_index][2] == cache_tag;
    assign cache_hit_bus[3] = valid_buf[cache_index][3] & tags_buf[cache_index][3] == cache_tag;

    assign cache_hit = |cache_hit_bus;  // Takes a bitwise OR of the whole bus
    assign stall = !cache_hit && !data_valid && ( read_en || ( write_en && !(&byte_en))  );
    // Don't need to stall if data is valid already

    // No stall if write_en and byte_en are both asserted

    // Each time our cache doesn't hit we must stall cycle.
    // Exception is when writing an address that has byte_en 1111; the whole register will
    // Be modified anyway so it doesn't matter.

    always @ (posedge clk) begin
        // Reset behaviour
        if (rst) begin
            // $display("DATA_CACHE : parameters : size:%d, depth:%d, assoc:%d", CACHE_SIZE, CACHE_DEPTH, CACHE_ASSOC);
            for (i=0; i<CACHE_DEPTH; i=i+1) begin
                valid_buf[i] <= 4'b0000;  // Valid is a 1d array actually
                for (j=0; j<CACHE_ASSOC; j=j+1) begin
                    // $display("DATA_CACHE : resetting index i:%d, j:%d", i, j);
                    tags_buf[i][j] <= 0;
                    data_buf[i][j] <= 0;
                    // valid_buf[i][j] <= 0;  // Valid is a 1d array actually
                    recent_buf[i][j] <= 0;
                end
            end
        end else begin
            // $display("DATA_CACHE : CYCLING..."); // DEBUG
            if (read_en | write_en) begin
                if (!cache_hit) begin
                    // Only action the write after valid data is in
                    // If byte_en is 1111 and we are writing, simply overwrite.
                    // CHECK if there is a write miss - does it resolve itself on the next cycle?
                    // $display("DATA_CACHE : READ/WRITE STALL, write_cond: %b", write_cond);  // DEBUG
                    // And in that case is it necessary to have extra byte_en logic?
                    if ( write_cond ) begin
                    // if ( data_valid || (|byte_en && write_en)  ) begin
                        $display("DATA_CACHE : Replacement required: Valid buffer: %4b", valid_buf[cache_index]);
                        readdata_reg <= data_in;
                        // Trivial case - assoc with something not VALID - write into that.
                        // x: dont care. Use casex to include don't cares
                        // if xxx0; write to 0
                        // if xx01; write to 1
                        // if x011; write to 2
                        // if 0111; write to 3.
                        if (!(&valid_buf[cache_index])) begin
                            $display("DATA_CACHE : Trivial case, current valid buffer is %4b", valid_buf[cache_index]);
                            casex (valid_buf[cache_index])
                                4'bxxx0: begin
                                    $display("DATA_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[0], address 0x%h", reg_input, cache_index, cache_tag, addr);
                                    tags_buf[cache_index][0] <= cache_tag;
                                    valid_buf[cache_index][0] <= 1;
                                    data_buf[cache_index][0] <= reg_input;
                                    recent_buf[cache_index][0] <= 2'b11;    // Automatically the most-recent
                                    recent_buf[cache_index][1] <= 2'b10;    // Known state
                                    recent_buf[cache_index][2][1] <= 0;     // Unknown first bit
                                    recent_buf[cache_index][3][1] <= 0;    
                                end
                                4'bxx01: begin
                                    $display("DATA_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[1], address 0x%h", reg_input, cache_index, cache_tag, addr);
                                    tags_buf[cache_index][1] <= cache_tag;
                                    valid_buf[cache_index][1] <= 1;
                                    data_buf[cache_index][1] <= reg_input;
                                    recent_buf[cache_index][0] <= 2'b10;    // Automatically the most-recent
                                    recent_buf[cache_index][1] <= 2'b11;    // Known state
                                    recent_buf[cache_index][2][1] <= 0;     // Unknown first bit
                                    recent_buf[cache_index][3][1] <= 0;    
                                end
                                4'bx011: begin
                                    $display("DATA_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[2], address 0x%h", reg_input, cache_index, cache_tag, addr);
                                    tags_buf[cache_index][2] <= cache_tag;
                                    valid_buf[cache_index][2] <= 1;
                                    data_buf[cache_index][2] <= reg_input;
                                    recent_buf[cache_index][0][1] <= 0;     // Unknown first bit
                                    recent_buf[cache_index][1][1] <= 0;   
                                    recent_buf[cache_index][2] <= 2'b11;   
                                    recent_buf[cache_index][3] <= 2'b10; 
                                end
                                4'b0111: begin
                                    $display("DATA_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[3], address 0x%h", reg_input, cache_index, cache_tag, addr);
                                    tags_buf[cache_index][3] <= cache_tag;
                                    valid_buf[cache_index][3] <= 1;
                                    data_buf[cache_index][3] <= reg_input;
                                    recent_buf[cache_index][0][1] <= 0;     // Unknown first bit
                                    recent_buf[cache_index][1][1] <= 0;   
                                    recent_buf[cache_index][2] <= 2'b10;
                                    recent_buf[cache_index][3] <= 2'b11;
                                end
                            endcase
                        end else begin
                            // Nontrivial case - write into assoc with 00 in the recent_buf
                            $display("DATA_CACHE : Non-trivial case, recent buffers are 0:%b 1:%b 2:%b 3:%b", recent_buf[cache_index][0], recent_buf[cache_index][1], recent_buf[cache_index][2], recent_buf[cache_index][3]);
                            if (recent_buf[cache_index][0] == 2'b00) begin // 0 is LRU
                                $display("DATA_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[0]", reg_input, cache_index, cache_tag);
                                tags_buf[cache_index][0] <= cache_tag;
                                valid_buf[cache_index][0] <= 1;    
                                data_buf[cache_index][0] <= reg_input;
                                recent_buf[cache_index][0] <= 2'b11;    // Automatically the most-recent
                                recent_buf[cache_index][1] <= 2'b10;    // Known state
                                recent_buf[cache_index][2][1] <= 0;     // Unknown first bit
                                recent_buf[cache_index][3][1] <= 0;    
                            end else if (recent_buf[cache_index][1] == 2'b00) begin // 1 is LRU
                                $display("DATA_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[1]", reg_input, cache_index, cache_tag);
                                tags_buf[cache_index][1] <= cache_tag;
                                valid_buf[cache_index][1] <= 1;
                                data_buf[cache_index][1] <= reg_input;
                                recent_buf[cache_index][0] <= 2'b10;    // Automatically the most-recent
                                recent_buf[cache_index][1] <= 2'b11;    // Known state
                                recent_buf[cache_index][2][1] <= 0;     // Unknown first bit
                                recent_buf[cache_index][3][1] <= 0;                        
                            end else if (recent_buf[cache_index][2] == 2'b00) begin // 2 is LRU
                                $display("DATA_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[2]", reg_input, cache_index, cache_tag);
                                tags_buf[cache_index][2] <= cache_tag;
                                valid_buf[cache_index][2] <= 1;
                                data_buf[cache_index][2] <= reg_input;
                                recent_buf[cache_index][0][1] <= 0;     // Unknown first bit
                                recent_buf[cache_index][1][1] <= 0;   
                                recent_buf[cache_index][2] <= 2'b11;   
                                recent_buf[cache_index][3] <= 2'b10; 
                            end else if (recent_buf[cache_index][3] == 2'b00) begin // 3 is LRU
                                $display("DATA_CACHE : Loading 0x%h into index 0x%h, tag 0x%h assoc[3]", reg_input, cache_index, cache_tag);
                                tags_buf[cache_index][3] <= cache_tag;
                                valid_buf[cache_index][3] <= 1;
                                data_buf[cache_index][3] <= reg_input;
                                recent_buf[cache_index][0][1] <= 0;     // Unknown first bit
                                recent_buf[cache_index][1][1] <= 0;
                                recent_buf[cache_index][2] <= 2'b10;
                                recent_buf[cache_index][3] <= 2'b11;
                            end
                        end
                    end else begin
                        // $display("DATA_CACHE : Neither data_valid nor overwrite skippable, wait another cycle");
                    end
                end else begin
                    $display("DATA_CACHE : READ/WRITE HIT");
                    // handle the LRU aspect here
                    if (read_en | write_en) begin
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
                    end

                    if (read_en) begin
                        // Assign return vals
                        readdata_reg <= data_buf[cache_index][cache_assoc_index];
                        // $display("DATA_CACHE : Read 0x%h from index 0x%h, assoc 0x%h", data_buf[cache_index][cache_assoc_index], cache_index, cache_index);

                    end else if (write_en) begin
                        // Modify values - Cache miss but byte_en==4'b1111 is handled above.
                        towrite[31:24] = (byte_en[3]) ? writedata[31:24] : data_buf[cache_index][cache_assoc_index][31:24];
                        towrite[23:16] = (byte_en[2]) ? writedata[23:16] : data_buf[cache_index][cache_assoc_index][23:16];
                        towrite[15:8] =  (byte_en[1]) ? writedata[15:8] : data_buf[cache_index][cache_assoc_index][15:8];
                        towrite[7:0] =   (byte_en[0]) ? writedata[7:0] : data_buf[cache_index][cache_assoc_index][7:0];
                        data_buf[cache_index][cache_assoc_index] <= towrite;
                    end
                end
            end else begin
                // $display("DATA_CACHE : Stall not high; read_en nor write_en asserted");
            end
        end
    end
endmodule