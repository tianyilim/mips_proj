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