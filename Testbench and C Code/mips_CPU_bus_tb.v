module mips_CPU_bus_tb;

	// testbench parameters and varaibles
	parameter TIMEOUT_CYCLES = 10000;
	integer loading_memory;
	integer total_cpu_cycles_ran;					// total cycles ran since beginning of testbench
	integer current_cpu_cycles_ran;					// total cycles ran for the current program under test
	integer current_program_num_instructions;		// to be read from the file
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

	// loading the program into program memory
	reg[31:0] loader_address;		// master -> slave
	reg[3:0] loader_byteenable;	// master -> slave
	reg loader_read;				// master -> slave
	reg loader_write;				// master -> slave
	reg[31:0] loader_writedata;	// master -> slave
	
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
	logic [1:0] mem_response;		// slave -> master
	logic[31:0] mem_writedata;		// master -> slave
	
		
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
		.address(mem_address),			// master -> slave
		.byteenable(mem_byteenable),	// master -> slave
		.read(mem_read),				// master -> slave
		.write(mem_write),				// master -> slave
		.waitrequest(mem_waitrequest),	// slave -> master
		.readdata(mem_readdata),		// slave -> master
		.response(mem_response), 		// slave -> master
		.writedata(mem_writedata)		// master -> slave
	);
	
	// instantiate the CPU
	mips_CPU_bus CPU(
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
			#10;
			cpu_clk = 1;
			
			// count number of cycles taken to run program, count only when CPU is running
			if (cpu_reset == 0 && cpu_active == 1) begin
				total_cpu_cycles_ran  = total_cpu_cycles_ran + 1;
				current_cpu_cycles_ran = current_cpu_cycles_ran + 1;
				
				// If current program takes too long to finish, abort testing.
				if (current_cpu_cycles_ran > TIMEOUT_CYCLES) begin
					$fatal(2, "FAIL! Current program did not finish within %d cycles.", TIMEOUT_CYCLES);
				end
			end
			
			#10;
			cpu_clk = 0;
		end
	end

	// initial block for memory clock
	initial begin
		mem_clk = 0;

		// We assume that the memory clock is not necessarily in sync with the CPU clock, hence the different delay
		forever begin
			#17;
			mem_clk = ~mem_clk;
		end
	end

	// according to the "Exceptions" section in https://github.com/m8pple/elec50010-2020-cpu-cw, if CPU accesses an address which is outside that set of known addresses (response = 11), consitered to fail the test case
	always @(mem_response) begin
		if ((mem_response == 2'b11) && (cpu_reset == 0)) begin //must AND with cpu_reset == 0, just in case the memory write fails when we are loading the program into it, we don't want that false positive
			$fatal(2, "FAIL! CPU tried to read invalid memory location!\n");
		end
	end

	// if we are loading program data from file into memory, then memory is driven by testbench. Else, memory is driven by the CPU
	always begin
		if (loading_memory == 1) begin
			mem_address = loader_address;		// master(tb) -> slave(MEM)
			mem_byteenable = loader_byteenable;	// master(tb) -> slave(MEM)
			mem_read = loader_read;				// master(tb) -> slave(MEM)
			mem_write = loader_write;			// master(tb) -> slave(MEM)
			mem_writedata = loader_writedata;	// master(tb) -> slave(MEM)
		end
		else begin
			mem_address = cpu_address;			// master(CPU) -> slave(MEM)
			mem_byteenable = cpu_byteenable;	// master(CPU) -> slave(MEM)
			mem_read = cpu_read;				// master(CPU) -> slave(MEM)
			mem_write = cpu_write;				// master(CPU) -> slave(MEM)
			cpu_waitrequest = mem_waitrequest;	// slave(MEM) -> master(CPU)
			cpu_readdata = mem_readdata;		// slave(MEM) -> master(CPU)
			mem_writedata = cpu_writedata;		// master(CPU) -> slave(MEM)
		end
	end

	always begin
		if (loading_memory == 1 && cpu_active == 1) begin
			$fatal(2, "FAIL! CPU somehow started on its own when programs are being loaded into memory!\n");
		end
	end
	
	// initial block for main testbench
	initial begin
		// global initializations
		cpu_reset = 1;
		loading_memory = 0;		
		total_cpu_cycles_ran = 0;
		current_cpu_cycles_ran = 0;
		current_program_num_instructions = 0;
		fp = $fopen("test_prog_list.txt", "r");
		file_flag = 1;
		file_counter = 0;

		// loop through every test program generated bt the C code
		while (!$feof(fp)) begin
	
			// First, inhibit CPU operation
			cpu_reset = 1;		// assert cpu_reset
			@(posedge cpu_clk);
			#1; // wait a bit first... just in case for false positive that the CPU doesnt halt properly
			if (cpu_active != 0) begin
				$fatal(2, "FAIL! CPU didn't halt even after cpu_reset has been asserted!\n");
			end
			
			// Second, read the program txt file & write the program file into MEM
			loading_memory = 1;

			$display("---------------\ntest program number %d loading start", file_counter);		
			while (!$feof(fp) && file_flag) begin
				ccc = $fgetc(fp);
				if (ccc == "`") begin
					shut_up = $fscanf(fp, "%d", current_program_num_instructions); // compiler warnings...
					shut_up = $fgets(str, fp); // compiler warnings...
					$display("num instructions = |%d|, program name-> |%s|", current_program_num_instructions, str[50*8 - 1:8]);
				end
				else if (ccc == "#") begin
					shut_up = $fscanf(fp, "%x", mem_loc); // compiler warnings...
					shut_up = $fscanf(fp, "%x", mem_data); // compiler warnings...
					$display("memloc:data-> |%b|:|%b|", mem_loc, mem_data);
					loader_address = mem_loc;
					loader_byteenable = 4'b1111;
					loader_read = 0;
					loader_write = 1;
					loader_writedata = mem_data;
					// Wait until the RAM successfully latches the data in during a rising clock edge where the waitrequest is not asserted
					mem_load_flag = 1;
					while (mem_load_flag == 1) begin
						@(posedge mem_clk);
						if (mem_waitrequest == 0) begin
							mem_load_flag = 0;
						end
					end
				end
				else if (ccc == "@") begin
					shut_up = $fscanf(fp, "%x", expected_result); // compiler warnings...
					$display("expected result-> |%b|", expected_result);
					file_flag = 0;
				end
			end
			$display("test program number %d loading finish\n----------------\n", file_counter);
			file_counter = file_counter + 1;
			file_flag = 1;

			loading_memory = 0;
			
			// Third, allow CPU to start operation
			cpu_reset = 0;					// deassert cpu_reset
			current_cpu_cycles_ran = 0;		// start counting number of cpu cycles for this program		
			@(posedge cpu_clk); 			// wait for cpu_clk rising edge
			#1; 							// wait a bit first... just in case we get false positives that the CPU didn't start properly
			if (cpu_active != 1) begin
				$fatal(2, "FAIL! CPU didn't start even after cpu_reset has been deasserted!\n");
			end
			
			// Fourth, wait for CPU to finish execution
			@ (negedge cpu_active);

			
			// Fifth, Compare results
			if (expected_result == cpu_register_v0)	begin
				$display("Pass... (so far) :p\n");
			end
			else begin
				$display(2, "FAIL! $v0 does not agree with expected result!\n");
			end

		end
		
		$finish("End of testbench. \n");
	end

endmodule











