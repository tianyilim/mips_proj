#!/bin/bash

iverilog -Wall -g 2012 \
    rtl/mips_cpu_*.v \
    test/mips_avalon_slave.v test/mips_CPU_bus_tb.v \
    -s mips_CPU_bus_tb \
    -o joe.out

