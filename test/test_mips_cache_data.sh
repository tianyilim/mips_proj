
#!/bin/bash
# Tests the Write Buffer module
# Note, start your X-server or related display driver before running
# Else the gtkwave will not start

# Compilation for the mips data cache testbench.
set -eou pipefail

iverilog -g 2012 -Wall \
   rtl/tb_mips_cache_data.v rtl/mips_cache_data.v \
   -s tb_mips_cache_data \
   -o test/tb_mips_cache_data

# Auto-run 
./test/tb_mips_cache_data
# Opens with savefiles, Cleanup
gtkwave tb_mips_cache_data.vcd tb_mips_cache_data.gtkw -a tb_mips_cache_data.gtkw; \
rm test/tb_mips_cache_data