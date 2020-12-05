// Simulates a dummy Read-Only memory
module dummy_harvard_ram(
    input logic clk,

    input logic[31:0]  instr_address,
    output logic[31:0] instr_readdata,


    input logic[3:0] byteenable,
    input logic[31:0] data_address,
    input logic data_write,
    input logic data_read,
    input logic[31:0] data_writedata,
    output logic[31:0] data_readdata
);
    parameter MEM_BITS = 16;                   // CHECK the performance (RAM wise)
    parameter MEM_SIZE = $pow(2, MEM_BITS);    // Enough to test for associativity
    parameter MEM_INIT_FILE = "";              // Initialise RAM from elsewhere
    parameter OFFSET = 32'hBFC00000;           // Where does the memory addressable block start?

    integer i;  // Iterator

    // Offset these words taking into account byte addressing
    logic [31:0] data_addr_real;
    logic [31:0] instr_addr_real;
    assign data_addr_real = (data_address-OFFSET) >> 2;
    assign instr_addr_real = (instr_address-OFFSET) >> 2;
    logic [31:0] towrite;   // byte enable implementation

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
    end

    always @ (posedge clk) begin
        // Always output instruction
        instr_readdata <= memory[instr_addr_real];
        // $display("MEM : INSTR : Read instr 0x%h from address 0x%h", memory[instr_addr_real], instr_address);

        if (data_read) begin
            data_readdata <= memory[data_addr_real];
            // $display("MEM : DATA : Read 0x%h from address 0x%h", memory[instr_addr_real], instr_address);
        end else if (data_write) begin
            towrite = memory[data_addr_real];
            towrite[31:24] = (byteenable[3]) ? data_writedata[31:24] : towrite[31:24];
            towrite[23:16] = (byteenable[2]) ? data_writedata[23:16] : towrite[23:16];
            towrite[15:8] = (byteenable[1]) ? data_writedata[15:8] : towrite[15:8];
            towrite[7:0] = (byteenable[0]) ? data_writedata[7:0] : towrite[7:0];
            memory[data_addr_real] <= towrite;
            $display("MEM : DATA : Wrote 0x%h to address 0x%h with byte_en %4b", towrite, instr_address, byteenable);
        end
    end

endmodule
