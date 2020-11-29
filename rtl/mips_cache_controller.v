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
    
    logic instr_stall;    // 
    logic data_stall;
    logic [1:0] wb_state;
    logic wb_full;
    logic wb_empty;

    // Instanstiate the write-buffer and data/instr caches
    mips_cache_instr cache_instr(.clk(clk), .rst(rst), .addr(instr_address), 
                                .readdata(instr_readdata), .stall(instr_stall));

    mips_cache_data cache_data(.clk(clk), .rst(rst), .addr(data_address),
                                .read_en(data_read), .write_en(data_write),
                                .writedata(data_writedata), .byte_en(data_byteenable),
                                .readdata(data_readdata), .stall(data_stall));

    mips_cache_writebuffer cache_writebuffer(.clk(clk), .rst(rst), .addr(data_address),
                                .write_en(data_write), .writedata(data_writedata), 
                                .byteenable(data_byteenable), .waitrequest(waitrequest),
                                .write_addr(mem_address), .write_data(mem_writedata), 
                                .write_byteenable(mem_byteenable), .write_writeenable(mem_write),
                                .state_out(wb_state), .full(wb_full), .empty(wb_empty));

    typedef enum logic[2:0] {
        STATE_IDLE = 3'd0,
        STATE_WRITE = 3'd1,
        STATE_FETCH = 3'd2
    } state_t;

    

endmodule