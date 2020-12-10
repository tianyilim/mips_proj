#!/bin/bash
if [ ! -f test/MIPS_tb.out ]; then
    gcc test/MIPS_tb.c -o test/MIPS_tb.out
fi

iverilog -Wall -g 2012 \
    rtl/mips_cpu_*.v \
    test/mips_avalon_slave.v test/mips_CPU_bus_tb.v \
    -s mips_CPU_bus_tb \
    -o joe.out

set +e
# Auto-run 
./joe.out

set -e
# Opens with savefiles, Cleanup
gtkwave mips_CPU_bus_tb.vcd mips_CPU_bus_tb.gtkw -a mips_CPU_bus_tb.gtkw; \
rm joe.out