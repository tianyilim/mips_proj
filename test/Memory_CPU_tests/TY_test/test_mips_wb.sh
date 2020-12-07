#!/bin/bash
# Tests the Write Buffer module
# Note, start your X-server or related display driver before running
# Else the gtkwave will not start

# Compilation for the mips avalon testbench.
set -eou pipefail

iverilog -g 2012 -Wall \
   test/Memory_CPU_tests/TY_test/tb_mips_cache_writebuffer.v rtl/mips_cache_writebuffer.v test/mips_avalon_slave.v \
   -s tb_mips_cache_writebuffer \
   -P tb_mips_cache_writebuffer.RAM_INIT_FILE=\"test/avalon_slave_sample.txt\" \
   -o test/Memory_CPU_tests/TY_test/tb_mips_cache_writebuffer.out

set +e
# Auto-run 
./test/Memory_CPU_tests/TY_test/tb_mips_cache_writebuffer.out

set -e
# Opens with savefiles, Cleanup
gtkwave tb_mips_cache_writebuffer.vcd tb_mips_cache_writebuffer.gtkw -a tb_mips_cache_writebuffer.gtkw; \
rm test/Memory_CPU_tests/TY_test/tb_mips_cache_writebuffer.out