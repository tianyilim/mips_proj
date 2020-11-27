#!/bin/bash

# Compilation for the mips avalon testbench.
set -eou pipefail

iverilog -g 2012 -Wall \
   rtl/mips_avalon_slave_tb.v rtl/mips_avalon_slave.v \
   -s mips_avalon_slave_tb \
   -P mips_avalon_slave_tb.RAM_INIT_FILE=\"test/avalon_slave_sample.txt\" \
   -o test/mips_avalon_slave_test

# Auto-run 
./test/mips_avalon_slave_test
gtkwave test_mips_avalon_slave_tb.vcd

# Cleanup
rm test/mips_avalon_slave_test