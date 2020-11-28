#!/bin/bash
# Tests the Write Buffer module
# Note, start your X-server or related display driver before running
# Else the gtkwave will not start

# Compilation for the mips avalon testbench.
set -eou pipefail

iverilog -g 2012 -Wall \
   rtl/tb_mips_cache_writebuffer.v rtl/mips_cache_writebuffer.v rtl/mips_avalon_slave.v \
   -s tb_mips_cache_writebuffer \
   -P tb_mips_cache_writebuffer.RAM_INIT_FILE=\"test/avalon_slave_sample.txt\" \
   -o test/tb_mips_cache_writebuffer

# Auto-run 
./test/tb_mips_cache_writebuffer
# Opens with savefiles, Cleanup
gtkwave tb_mips_cache_writebuffer.vcd tb_mips_cache_writebuffer.gtkw -a tb_mips_cache_writebuffer.gtkw; \
rm test/tb_mips_cache_writebuffer