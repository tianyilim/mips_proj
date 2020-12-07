`timescale 1ns / 1ns
module sixteen_bit_extension(
    input logic[15:0] x,
    output logic[31:0] y
);

    assign y = {{16{x[15]}},x};

endmodule
