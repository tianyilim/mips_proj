`timescale 1ns / 1ns
module eight_bit_extension(
    input logic[7:0] x,
    output logic[31:0] y
);

    assign y = {{24{x[7]}},x};

endmodule
