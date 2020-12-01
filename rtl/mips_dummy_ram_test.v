// Simulates a dummy Read-Only memory
module dummy_ram(
    input logic clk,

    input logic[31:0] addr,
    input logic read_en,
    output logic[31:0] data,
    output logic dvalid
);
    parameter MEM_BITS = 8;
    parameter MEM_SIZE = $pow(2, MEM_BITS);    // Enough to test for associativity
    parameter DVALID_DELAY = 1;                 // Delay till dvalid is asserted
    parameter MEM_INIT_FILE = "";               // Initialise RAM from elsewhere

    integer i;  // Iterator
    integer delay_ctr;

    logic [31:0] addr_offset;
    assign addr_offset = addr >> 2;

    reg[31:0] memory [MEM_SIZE-1:0];    // Memory is contained here

    initial begin
        /* Initialise to zero by default */
        for (i=0; i<MEM_SIZE; i++) begin
            memory[i] = 0;
        end
        /* Load contents from file if specified */
        if (MEM_INIT_FILE != "") begin
            $display("MEM : INIT : Loading MEM contents from %s with size %d", MEM_INIT_FILE, MEM_SIZE);
            $readmemh(MEM_INIT_FILE, memory);
        end
        delay_ctr = -1;
        dvalid = 0;
    end

    always @ (posedge clk) begin
        if (read_en) begin
            // new read request, wait for given read_delay
            if (delay_ctr == -1) begin
                delay_ctr = DVALID_DELAY-1;
                dvalid = 0;
            // Delay done, set valid to true
            end else if (delay_ctr == 0) begin
                delay_ctr = -1;
                dvalid = 1;
                data = memory[addr_offset];
                $display("MEM : READ : Read 0x%h from address 0x%h", data, addr);
            // Waiting, decrement delay counter
            end else begin
                delay_ctr -= 1;
                $display("MEM : DELAY : Waiting %1d more cycles for memory read from address 0x%h", delay_ctr, addr);
            end

        end else begin
            dvalid = 0;
        end
    end

endmodule