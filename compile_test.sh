#!/bin/bash

iverilog -Wall -g 2012 \
    rtl/sixteen_bit_extension.v rtl/eight_bit_extension.v rtl/register_file.v rtl/mips_cpu_harvard.v \
    rtl/mips_cache_controller.v rtl/mips_cache_data.v rtl/mips_cache_instr.v rtl/mips_cache_writebuffer.v rtl/mips_cpu_bus.v \
    test/mips_avalon_slave.v test/mips_CPU_bus_tb.v \
    -s mips_CPU_bus_tb \
    -o joe.out

