#!/bin/bash

# Compilation for the mips avalon testbench.
set -eou pipefail

iverilog -g 2012 -Wall \
   test/Memory_CPU_tests/TY_test/tb_mips_avalon_slave.v test/mips_avalon_slave.v \
   -s tb_mips_avalon_slave \
   -P tb_mips_avalon_slave.RAM_INIT_FILE=\"test/avalon_slave_sample.txt\"  \
      tb_mips_avalon_slave.DATA_INIT_FILE=\"test/avalon_slave_sample.txt\" \
   -o test/Memory_CPU_tests/TY_test/mips_avalon_slave_test.out

# Auto-run 
./test/Memory_CPU_tests/TY_test/mips_avalon_slave_test.out
# Opens with savefiles
gtkwave test_mips_avalon_slave_tb.vcd test_mips_avalon_slave_tb.gtkw -a test_mips_avalon_slave_tb.gtkw

# Cleanup
rm test/Memory_CPU_tests/TY_test/mips_avalon_slave_test.out