#!/bin/bash

# Tests all hex instruction files within test/1-binary/

for FILENAME in test/1-binary/*.instr.hex; do
    [ -e "$FILENAME" ] || continue # Avoid case where there are no matches
    
    NAME="${FILENAME%.*}"
    NAME="${NAME%.*}"
    BASENAME=`basename ${NAME}`
    echo "Test name $BASENAME"

    if [ -f ${NAME}.data.hex ]; then
        DATANAME=${NAME}.data.hex
    else
        DATANAME=""
    fi

    iverilog -Wall -g 2012 \
        rtl/mips_cpu_*.v \
        test/mips_avalon_slave.v test/mips_CPU_bus_tb_change.v \
        -P  mips_CPU_bus_tb.INSTR_INIT_FILE=\"${FILENAME}\"  \
            mips_CPU_bus_tb.DATA_INIT_FILE=\"${DATANAME}\" \
            TIMEOUT_CYCLES=100 \
        -s mips_CPU_bus_tb \
        -o joe.out

    set +e
    # Auto-run 
    ./joe.out > test/3-output/${BASENAME}.log
    # cat test/3-output/${BASENAME}.log
    # Display some debug output
    grep "TB : CYCLES" test/3-output/${BASENAME}.log
    grep "TB : V0" test/3-output/${BASENAME}.log
    
    set -e
    # Opens with savefiles, Cleanup
    gtkwave mips_CPU_bus_tb.vcd mips_CPU_bus_tb.gtkw -a mips_CPU_bus_tb.gtkw; \
    rm joe.out
done;