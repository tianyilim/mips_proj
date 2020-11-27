module mips_cache_controller(
    input logic clk,
    input logic rst,
    
    output logic[31:0] address,
    output logic write,
    output logic read,
    output logic[31:0] writedata,
    output logic[3:0] byteenable,

    input logic waitrequest,
    input logic[31:0] readdata
);

    typedef enum logic[2:0] {
        STATE_IDLE = 3'd0,
        STATE_WRITE = 3'd1,
        STATE_FETCH = 3'd2
    } state_t;

    

endmodule