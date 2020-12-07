#!/bin/bash
# Tests the Write Buffer module
# Note, start your X-server or related display driver before running
# Else the gtkwave will not start

# Compilation for the mips data cache testbench.
set -eou pipefail

iverilog -g 2012 -Wall \
   test/Memory_CPU_tests/TY_test/tb_mips_cache_data.v rtl/mips_cache_data.v test/Memory_CPU_tests/TY_test/mips_dummy_ram_test.v \
   -s tb_mips_cache_data \
   -P tb_mips_cache_data.MEM_INIT_FILE=\"test/Memory_CPU_tests/TY_test/dummy_data_sample.txt\" \
   -o test/Memory_CPU_tests/TY_test/tb_mips_cache_data.out

# Auto-run 
./test/Memory_CPU_tests/TY_test/tb_mips_cache_data.out
# Opens with savefiles, Cleanup
gtkwave tb_mips_cache_data.vcd tb_mips_cache_data.gtkw -a tb_mips_cache_data.gtkw; \
rm test/Memory_CPU_tests/TY_test/tb_mips_cache_data.out