module mips_CPU_bus_tb;
    timeunit 1ns / 1ns;

	// testbench parameters and varaibles
	parameter TIMEOUT_CYCLES = 10000;
	parameter CPU_CLK_TIME = 5;
	parameter MEM_CLK_TIME = CPU_CLK_TIME;
	parameter INSTR_INIT_FILE = "";
	parameter DATA_INIT_FILE = "";

	integer current_cpu_cycles_ran;					// total cycles ran since beginning of testbench
	reg[50*8 - 1:0] str;							// for file io use (read the test program name)
	reg[7:0] ccc;									// for file io use (read the delimiter characters)
	reg[31:0] mem_loc, mem_data;					// for file io use (mem_loc = read the mem loc, mem_data = read the mem data)
	integer fp, shut_up, file_flag, file_counter;	// for file io use (fp = file pointer, shut_up to suppress compiler warnings, file_flag and file_counter for loop control)
	integer mem_load_flag;							// for loop control in loading the program into memory

	// expected result
	reg[31:0] expected_result;						// to be read from file
	
	// testbench interface with the CPU
	reg mem_clk;				// input into memory
	reg cpu_clk;				// input into CPU
	reg cpu_reset;				// input into CPU
	reg cpu_active;				// output from CPU
	wire[31:0] cpu_register_v0;	// output from CPU

	// memory signals out of CPU (master)
	logic[31:0] cpu_address;		// master -> slave
	logic[3:0] cpu_byteenable;		// master -> slave
	logic cpu_read;					// master -> slave
	logic cpu_write;				// master -> slave
	logic cpu_waitrequest;			// slave -> master
	logic[31:0] cpu_readdata;		// slave -> master
	logic[31:0] cpu_writedata;		// master -> slave
		
	// memory signals into memory (slave)
	logic[31:0] mem_address;		// master -> slave
	logic[3:0] mem_byteenable;		// master -> slave
	logic mem_read;					// master -> slave
	logic mem_write;				// master -> slave
	logic mem_waitrequest;			// slave -> master
	logic[31:0] mem_readdata;		// slave -> master
	logic[31:0] mem_writedata;		// master -> slave

	// Connecting these together
	assign mem_address = cpu_address;
	assign mem_byteenable = cpu_byteenable;
	assign mem_read = cpu_read;
	assign mem_write = cpu_write;
	assign cpu_waitrequest = mem_waitrequest;
	assign mem_writedata = cpu_writedata;
	assign cpu_readdata = mem_readdata;
	
	// instantiate the memory
	// THE MEMORY SHOULD NOT HAVE input logic rst
	/* 
		THE MEMORY SHOULD HAVE AN output logic[1:0] response, according to page 15 https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/manual/mnl_avalon_spec.pdf:
		00: OKAY—Successful response for a transaction.
		01: RESERVED—Encoding is reserved.
		10: SLAVEERROR—Error from an endpoint slave. Indicatesan unsuccessful transaction.
		11: DECODEERROR—Indicates attempted access to anundefined location
	*/
	mips_avalon_slave #(.RAM_INIT_FILE(INSTR_INIT_FILE), .DATA_INIT_FILE(DATA_INIT_FILE)) 
		MEM(
		.clk(mem_clk),					
		.address(mem_address),			// master -> slave
		.byteenable(mem_byteenable),	// master -> slave
		.read(mem_read),				// master -> slave
		.write(mem_write),				// master -> slave
		.waitrequest(mem_waitrequest),	// slave -> master
		.readdata(mem_readdata),		// slave -> master
		.writedata(mem_writedata)		// master -> slave
	);
	
	// instantiate the CPU
	mips_cpu_bus CPU(
		.clk(cpu_clk),
		.reset(cpu_reset),
		.active(cpu_active),
		.register_v0(cpu_register_v0),
		
		.address(cpu_address),			// master -> slave
		.byteenable(cpu_byteenable),	// master -> slave
		.read(cpu_read),				// master -> slave
		.write(cpu_write),				// master -> slave
		.waitrequest(cpu_waitrequest),	// slave -> master
		.readdata(cpu_readdata),		// slave -> master
		.writedata(cpu_writedata)		// master -> slave
	);
	
	// initial block for CPU clock
	initial begin
		cpu_clk = 0;

		forever begin
			#CPU_CLK_TIME;
			cpu_clk = 1;
			
			// count number of cycles taken to run program, count only when CPU is running
			if (cpu_reset == 0 && cpu_active == 1) begin
				current_cpu_cycles_ran = current_cpu_cycles_ran + 1;
				// If current program takes too long to finish, abort testing.
				if (current_cpu_cycles_ran > TIMEOUT_CYCLES) begin
					$fatal(2, "TB : FAIL : %02t : Current program did not finish within %d cycles.", $time, TIMEOUT_CYCLES);
				end
			end
			
			#CPU_CLK_TIME;
			cpu_clk = 0;
		end
	end

	// initial block for memory clock
	initial begin
		mem_clk = 0;

		// We assume that the memory clock is not necessarily in sync with the CPU clock, hence the different delay
		forever begin
			#MEM_CLK_TIME;
			mem_clk = ~mem_clk;
		end
	end

	// Remove this test case first
	// always @(negedge mem_clk) begin
	// 	if (loading_memory == 1 && cpu_active == 1) begin
	// 		$fatal(2, "FAIL! CPU somehow started on its own when programs are being loaded into memory!\n");
	// 	end
	// end
	
	// initial block for main testbench
	initial begin
		$dumpfile("mips_CPU_bus_tb.vcd");
        $dumpvars(0, mips_CPU_bus_tb);
		$display("TB : STATUS : %02t : Starting test", $time);
		// global initializations
		cpu_reset = 0;
		current_cpu_cycles_ran = 0;

		@(negedge cpu_clk);
		cpu_reset = 1;
		
		@(negedge cpu_clk);
		cpu_reset = 0;
		$display("TB : STATUS : %02t : CPU out of reset", $time);

		while( cpu_active ) begin
			@(posedge cpu_clk);
		end
		
		$display("TB : CYCLES : %04d", current_cpu_cycles_ran);
		$display("TB : V0 : 0x%h", cpu_register_v0);
		$display("TB : FINISH : %02t : CPU finished execution.", $time);
		$finish;
	end

endmodule











