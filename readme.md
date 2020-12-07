# MIPS CPU Submission - AM Team 10

## CPU Hierarchy
The CPU is implemented with the following dependencies:
```
mips_cpu_bus
│ 
└───mips_cpu_harvard
│   └───register_file
│   └───eight_bit_extension
│   └───sixteen_bit_extension
│   
└───mips_cache_controller
    └───mips_cache_instr
    └───mips_cache_data
    └───mips_cache_writebuffer
```

## Tianyi
Implemented a memory control unit that sits between a Harvard implementation of the CPU and acts a Avalon Master, converting the Harvard CPU to a Bus CPU, along with their respective testbenches for validation.

In addition, the memory control unit includes separate Data and Instruction caches, and a Write Buffer.

## Directory Guide
- `rtl/mips_cpu_bus.v`: Overall wrapper for the CPU, includes Avalon Bus interface
- `rtl/mips_cache_controller.v`: Controls the Avalon bus interface and when to request reads and writes to the memory stream from the caches and CPU.
- `rtl/mips_cache_instr.v`: 8-index, 4-way pseudo associative instruction cache for the CPU; connects to the instruction lines of the Harvard CPU.
- `rtl/mips_cache_data.v`: 8-index, 4-way pseudo associative data cache for the CPU; connects to the data lines of the Harvard CPU.
- `rtl/mips_cache_writebuffer.v`: 8-item write buffer that enables the CPU to continue operation without waiting for memory writes to complete.
- `test/Memory_CPU_tests/TY_test`: Contain testing primitives for each of the individual components built above.
- `test/mips_avalon_slave.v`: Acts as a dummy Avalon Slave implementation to accurately test slave devices on the Avalon bus to validate our `mips_cpu_bus` implementation.

## Chern Heng
Implemented a Harvard CPU with the required functionality. This MIPS CPU is non-pipelined and takes 3 cycles for most instructions and 4 cycles for Load instructions as the Register file takes 2 Cycles to update. In addition, there is a register file, and the 16-bit and 8-bit signed extension files.

## Directory Guide
- `rtl/mips_cpu_harvard.v`: Harvard CPU implementation. This takes the instruction word and break it into the different parts for the decode logic which happens combinatorially. 
			    The access to memory is handled by the cache, hence this just handles the data path within the CPU.
- `rtl/sixteen_bit_extension.v`: A module to do 16-bit signed extensions combinatorially, particularly useful for sign extending the immediate to be used as the memory_address.
- `rtl/eight_bit_extension.v`: A module to do 8-bit signed extensions combinatorially, not particularly useful and might remove it from the design.
- `rtl/register_file.v`: Implements the 32 register file with an error if there is any attempt to write to register 0.
- `test/Memory_CPU_tests/CH_test`: Contain testing for the individual modules to catch any intial and glaring errors.

