module signed_extension_tb(
);

    logic [7:0] eightbit;
    logic [15:0] sixteenbit;
    logic clk;
    wire logic [31:0] out_eight;
    wire logic [31:0] out_sixteen;
    logic run;

    initial begin
        $dumpfile("signed_extension.vcd");
        $dumpvars(0, signed_extension_tb);

        clk=0;

        repeat (15) begin
            #10;
            clk = !clk;
            #10;
            clk = !clk;
        end
    end

    initial begin
        eightbit = 125;
        sixteenbit = 32765;
        run = 0;
        @(posedge clk);
          run = 1;

        while(run) begin
          @(posedge clk);
            $display("eight=%h, sixteen=%h", $signed(out_eight), $signed(out_sixteen)); // should start with 125 as it is sequential
            eightbit <= eightbit+1;
            sixteenbit <= sixteenbit + 1;

        end

    end


    eight_bit_extension eight(
        .x(eightbit),
        .y(out_eight)
    );
    sixteen_bit_extension sixteen(
        .x(sixteenbit),
        .y(out_sixteen)
    );

endmodule
