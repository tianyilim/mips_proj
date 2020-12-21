// The cache controller is the middleman between the CPU and the Avalon bus.
// Looks like a Harvard bus to the CPU
// Looks like a Avalon bus to the memory
`timescale 1ns / 1ns
module mips_cache_controller(
    input logic clk,
    input logic rst,
    
    // Avalon Bus
    output logic[31:0] mem_address,
    output logic mem_write,
    output logic mem_read,
    output logic[31:0] mem_writedata,
    output logic[3:0] mem_byteenable,

    input logic waitrequest,
    input logic[31:0] mem_readdata,

    // to/from the CPU
    output logic clk_enable,

    input logic instr_read,
    input logic[31:0]  instr_address,
    output logic[31:0]   instr_readdata,

    input logic[31:0]  data_address,
    input logic        data_write,
    input logic        data_read,
    input logic[31:0]  data_writedata,
    input logic[3:0] data_byteenable,
    output logic[31:0]  data_readdata,

    // Control ports
    output logic wb_empty_out
);

    logic [1:0] state;
    assign wb_empty_out = wb_empty;

    logic [3:0] wb_byteenable;    // Byteenable should be 1 on read
    assign mem_byteenable = (state==STATE_WRITE) ? wb_byteenable : 4'b1111;

    logic instr_stall;  // Instruction cache fetch stall
    logic data_stall;   // Data cache (on read/write) fetch stall
    logic instr_stall_delay;
    logic data_stall_delay;

    logic [1:0] wb_state;
    logic wb_full;      // Write buffer fetch stall (on FULL)
    logic wb_empty;
    logic wb_active;    // activates writing aspect of WB

    logic [31:0] addr_wbtomem;      // Preventing multiple drivers of mem_addr
    logic addr_in_wb;               // Ensuring cache coherency

    logic instr_data_valid;
    logic data_data_valid;

    // Instanstiate the write-buffer and data/instr caches
    // Remember that the addresses when there are stalls correspond to the ones
    // Currently on the bus

    // instr_datain/data_datain is always mem_readdata
    mips_cache_instr cache_instr(.clk(clk), .rst(rst), .read_en(instr_read), .addr(instr_address), 
                                .readdata(instr_readdata), .stall(instr_stall),
                                .data_in(mem_readdata), .data_valid(instr_data_valid)
                                );

    mips_cache_data cache_data(.clk(clk), .rst(rst), .addr(data_address),
                                .read_en(data_read), .write_en(data_write),
                                .writedata(data_writedata), .byte_en(data_byteenable),
                                .readdata(data_readdata), .stall(data_stall),
                                .data_in(mem_readdata), .data_valid(data_data_valid)
                                );

    mips_cache_writebuffer cache_writebuffer(.clk(clk), .rst(rst), .addr(data_address),
                                .instr_addr(instr_address),
                                .write_en(data_write), .writedata(data_writedata), 
                                .byteenable(data_byteenable), .active(wb_active),
                                .waitrequest(waitrequest), .addr_in_wb(addr_in_wb),
                                .write_addr(addr_wbtomem), .write_data(mem_writedata), 
                                .write_byteenable(wb_byteenable), .write_writeenable(mem_write),
                                .state_out(wb_state), .full(wb_full), .empty(wb_empty)
                                );

    typedef enum logic[1:0] {
        STATE_IDLE = 2'd0,
        STATE_WRITE = 2'd1,
        STATE_FETCH = 2'd2
    } state_t;

    //
    assign clk_enable = !(instr_stall || data_stall || wb_full);
    assign mem_address = (state==STATE_WRITE) ? addr_wbtomem : (instr_stall_delay || instr_stall) ? instr_address : data_address;

    // mem_read can go on faster
    assign mem_read = ( (instr_stall) || (data_stall) ) && (state!=STATE_WRITE);
    // assign mem_read = ( instr_stall || data_stall ) && (state==!STATE_WRITE);

    // We know that the data valid cannot be high for two back-to-back cycles
    // And must follow these conditions - the falling edge of waitrequest
    // assign instr_data_valid = instr_stall_delay && !(waitrequest||waitrequest_delay) && (state==STATE_FETCH);
    // assign data_data_valid = data_stall_delay && !(waitrequest||waitrequest_delay) && (state==STATE_FETCH);

    always_ff @(posedge clk) begin
        instr_stall_delay <= instr_stall;
        data_stall_delay <= data_stall;

        if (mem_read && !waitrequest && !rst) begin
            instr_data_valid <= instr_stall;
            data_data_valid <= data_stall;
        end else begin
            instr_data_valid <= 0;
            data_data_valid <= 0;
        end
    end

    // always_comb begin
    //     // We know that the data valid cannot be high for two back-to-back cycles
    //     // And must follow these conditions
    //     instr_data_valid = instr_stall && !waitrequest && (state!=STATE_WRITE);
    //     data_data_valid = data_stall && !waitrequest && (state!=STATE_WRITE);
    // end

    always @ (posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
            wb_active <= 0;
            // instr_data_valid <= 0;
            // data_data_valid <= 0;
            // mem_read <= 0;

        end else begin
            case (state)    // State machine
                STATE_IDLE : begin
                    // Lmao do nothing
                    $display("CACHE_CTRL : STATE : IDLE");
                    // State transitions
                    if (instr_stall || data_stall) begin
                        state <= STATE_FETCH;
                        // mem_read <= 1;
                    end else if (!wb_empty) begin
                        state <= STATE_WRITE;
                        wb_active <= 1;
                    end
                end
                STATE_WRITE : begin
                    $display("CACHE_CTRL : STATE : WRITE");
                    wb_active <= 1;

                    // State transitions
                    if (!waitrequest) begin
                        if ((instr_stall || data_stall) && !(addr_in_wb)) begin
                            // Cache coherency, continue writing if there is something in the cache that will be later accessed
                            state <= STATE_FETCH;
                            // mem_read <= 1;
                            wb_active <= 0;
                        end else if (wb_empty) begin
                            state <= STATE_IDLE;
                            wb_active <= 0;
                        end
                    end
                end

                STATE_FETCH : begin
                    $display("CACHE_CTRL : STATE : FETCH");
                    
                    if (instr_stall || data_stall) begin
                        $display("CACHE_CTRL : STATUS : instr_stall: %b, data_stall: %b", instr_stall, data_stall);
                    end

                    // State transitions
                    if (!waitrequest & !(instr_stall || data_stall) ) begin
                        state <= STATE_IDLE;
                        // mem_read <= 0;
                    end
                end
            endcase
        end
    end    

endmodule