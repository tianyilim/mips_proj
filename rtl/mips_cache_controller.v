// The cache controller is the middleman between the CPU and the Avalon bus.
// Looks like a Harvard bus to the CPU
// Looks like a Avalon bus to the memory
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

    input logic[31:0]  instr_address,
    output logic[31:0]   instr_readdata,

    input logic[31:0]  data_address,
    input logic        data_write,
    input logic        data_read,
    input logic[31:0]  data_writedata,
    input logic[3:0] data_byteenable,
    output logic[31:0]  data_readdata
);

    logic [1:0] state;
    
    logic instr_stall;  // Instruction cache fetch stall
    logic data_stall;   // Data cache (on read/write) fetch stall

    logic [1:0] wb_state;
    logic wb_full;      // Write buffer fetch stall (on FULL)
    logic wb_empty;
    logic wb_active;    // activates writing aspect of WB

    logic [31:0] addr_wbtomem;      // Preventing multiple drivers of mem_addr

    logic [31:0] instr_data_in;
    logic instr_data_valid;
    logic [31:0] data_data_in;
    logic data_data_valid;

    // Instanstiate the write-buffer and data/instr caches
    // Remember that the addresses when there are stalls correspond to the ones
    // Currently on the bus
    mips_cache_instr cache_instr(.clk(clk), .rst(rst), .addr(instr_address), 
                                .readdata(instr_readdata), .stall(instr_stall),
                                .data_in(instr_data_in), .data_valid(instr_data_valid)
                                );

    mips_cache_data cache_data(.clk(clk), .rst(rst), .addr(data_address),
                                .read_en(data_read), .write_en(data_write),
                                .writedata(data_writedata), .byte_en(data_byteenable),
                                .readdata(data_readdata), .stall(data_stall),
                                .data_in(data_data_in), .data_valid(data_data_valid)
                                );

    mips_cache_writebuffer cache_writebuffer(.clk(clk), .rst(rst), .addr(data_address),
                                .write_en(data_write), .writedata(data_writedata), 
                                .byteenable(data_byteenable), .active(wb_active),
                                .waitrequest(waitrequest),
                                .write_addr(addr_wbtomem), .write_data(mem_writedata), 
                                .write_byteenable(mem_byteenable), .write_writeenable(mem_write),
                                .state_out(wb_state), .full(wb_full), .empty(wb_empty)
                                );

    typedef enum logic[1:0] {
        STATE_IDLE = 2'd0,
        STATE_WRITE = 2'd1,
        STATE_FETCH = 2'd2
    } state_t;

    //
    assign clk_enable = !(instr_stall || data_stall || wb_full);

    always @ (posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
            data_data_valid <= 0;
            instr_data_valid <= 0;
            wb_active <= 0;

        end else begin
            case (state)    // State machine
                STATE_IDLE : begin
                    // Lmao do nothing
                    $display("CACHE_CTRL : STATE : IDLE");

                    // State transitions
                    if (instr_stall || data_stall) begin
                        state <= STATE_FETCH;
                    end else if (!wb_empty) begin
                        state <= STATE_WRITE;
                    end
                end
                STATE_WRITE : begin
                    $display("CACHE_CTRL : STATE : WRITE");
                    // waitrequest already connected directly?
                    wb_active <= 1;
                    mem_address <= addr_wbtomem;

                    // State transitions
                    if (!waitrequest) begin
                        if (instr_stall || data_stall) begin
                            state <= STATE_FETCH;
                            wb_active <= 0;
                        end else if (wb_empty) begin
                            state <= STATE_IDLE;
                            wb_active <= 0;
                        end
                    end
                end
                STATE_FETCH : begin
                    $display("CACHE_CTRL : STATE : FETCH");
                    
                    if (instr_stall) begin
                        mem_address <= instr_address;
                        mem_read <= 1;
                    end else if (data_stall) begin
                        mem_address <= data_address;
                        mem_read <= 1;
                    end else begin
                        $display("CACHE_CTRL : STATUS : Neither instr_stall nor data_stall");
                    end

                    if (!waitrequest) begin
                        $display("CACHE_CTRL : STATUS : waitrequest complete");
                        mem_read <= 0;
                        if (instr_stall) begin
                            instr_data_in <= mem_readdata;
                            instr_data_valid <= 1;
                            data_data_valid <= 0;
                        end else if (data_stall) begin
                            data_data_in <= mem_readdata;
                            data_data_valid <= 1;
                            instr_data_valid <= 0;
                        end
                    end else begin
                        instr_data_valid <= 0;
                        data_data_valid <= 0;
                    end

                    // State transitions
                    if (!waitrequest & !(instr_stall || data_stall) ) begin
                        state <= (wb_empty) ? STATE_IDLE : STATE_WRITE;
                    end
                end
            endcase
        end
    end    

endmodule