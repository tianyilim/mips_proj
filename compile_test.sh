#!/bin/bash

iverilog -Wall -g 2012 \
    rtl/mips_cpu_sixteen_bit_extension.v rtl/mips_cpu_eight_bit_extension.v rtl/mips_cpu_register_file.v rtl/mips_cpu_harvard.v \
    rtl/mips_cpu_cache_controller.v rtl/mips_cpu_cache_data.v rtl/mips_cpu_cache_instr.v rtl/mips_cpu_cache_writebuffer.v rtl/mips_cpu_bus.v \
    test/mips_avalon_slave.v test/mips_CPU_bus_tb.v \
    -s mips_CPU_bus_tb \
    -o joe.out

