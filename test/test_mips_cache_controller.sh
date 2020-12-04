#!/bin/bash
# Tests the Write Buffer module
# Note, start your X-server or related display driver before running
# Else the gtkwave will not start

# Compilation for the mips data cache testbench.
set -eou pipefail

iverilog -g 2012 -Wall \
   rtl/tb_mips_cache_controller.v rtl/mips_cache_controller.v rtl/mips_cache_instr.v rtl/mips_cache_writebuffer.v rtl/mips_cache_data.v  rtl/mips_avalon_slave.v \
   -s tb_mips_cache_controller \
   -P tb_mips_cache_controller.RAM_INIT_FILE=\"test/dummy_data_sample.txt\" \
   -o test/tb_mips_cache_controller

# Auto-run 
./test/tb_mips_cache_controller
# Opens with savefiles, Cleanup
gtkwave tb_mips_cache_controller.vcd tb_mips_cache_controller.gtkw -a tb_mips_cache_controller.gtkw; \
rm test/tb_mips_cache_controller