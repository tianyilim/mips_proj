module mips_CPU_bus_tb;
	parameter TIMEOUT_CYCLES = 10000;

	// expected result
	logic[31:0] expected_result;	
	
	// testbench interface
	logic cpu_clk;
	logic cpu_reset;
	logic cpu_active;
	logic[31:0] cpu_register_v0;

	// Avalon memory interface
	logic mem_clk;
	logic[31:0] mem_address;
	logic mem_write;
	logic mem_read;
	logic[31:0] mem_writedata;
        logic[3:0] mem_byteenable;
        
        logic mem_waitrequest;
        logic [1:0] mem_response;
        logic[31:0] mem_readdata;
        
        // instantiate the memory
        // THE MEMORY SHOULD NOT HAVE input logic rst
        /* 
        THE MEMORY SHOULD HAVE AN output logic[1:0] response, according to page 15 https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/manual/mnl_avalon_spec.pdf:
        	00: OKAY—Successful response for a transaction.
		01: RESERVED—Encoding is reserved.
		10: SLAVEERROR—Error from an endpoint slave. Indicatesan unsuccessful transaction.
		11: DECODEERROR—Indicates attempted access to anundefined location
	*/
	mips_avalon_slave MEM(
		.clk(mem_clk),
		.address(mem_address),
		.write(mem_write),
		.read(mem_read),
		.writedata(mem_writedata),
		.byteenable(mem_byteenable),
		.waitrequest(mem_waitrequest),
		.readdata(mem_readdata),
		.response(mem_response); // according to the "Exceptions" section in https://github.com/m8pple/elec50010-2020-cpu-cw, if CPU accesses an address which is outside that set of known addresses (response = 11), consitered to fail the test case
	); 
	
	// instantiate the CPU
	mips_CPU_bus CPU(
		.clk(cpu_clk),
		.reset(cpu_reset),
		.active(cpu_active),
		.register_v0(cpu_register_v0),
		
		.address(mem_address),
		.write(mem_write),
		.read(mem_read),
		.writedata(mem_writedata),
		.byteenable(mem_byteenable),
		.waitrequest(mem_waitrequest),
		.readdata(mem_readdata)
	);
	
	// initial block for CPU clock
	initial begin
		cpu_clk = 0;

		repeat (TIMEOUT_CYCLES) begin
			#10;
			cpu_clk = 1;
			#10;
			cpu_clk = 0;
		end

		$fatal(2, "Simulation did not finish within %d cycles.", TIMEOUT_CYCLES);
	end
	
	// initial block for memory clock
	initial begin
		mem_clk = 0;

		repeat forever begin
			#26;
			mem_clk = 1;
			#26; 
			mem_clk = 0;
		end

	end
	
	// initial block for loading program into memory
	initial begin
		// First, inhibit CPU operation
		cpu_reset = 1;
		
		// Second, read the program file & write the program file into MEM
		/*
			expected_result = read_from_program_file()
			#delays and code to load program into memory
		*/
		
		// Third, allow CPU to start operation
		cpu_reset = 0;
		@(posedge cpu_clk); // wait for cpu_clk rising edge
		assert(cpu_active == 1);
		
		// wait for CPU to finish execution
		while (cpu_active == 1)
		begin
				#1;
		end
		
		// Compare results
		if (expected_result == cpu_register_v0)
		begin
			$display("pass\n");
		end
		else
		begin
			$display("fail\n");
		end
		
		$finish("End of testbench\n");
		
	end


endmodule
















