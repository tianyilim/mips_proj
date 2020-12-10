#!/bin/bash

# Tests all hex instruction files within test/1-binary/

for FILENAME in test/1-binary/*.instr.hex; do
    [ -e "$FILENAME" ] || continue # Avoid case where there are no matches
    
    NAME="${FILENAME%.*}"
    NAME="${NAME%.*}"
    BASENAME=`basename ${NAME}` # Name of test case
    INSTR_NAME=${BASENAME#"_"}

    if [ -f ${NAME}.data.hex ]; then
        DATANAME=${NAME}.data.hex
    else
        DATANAME=""
    fi

    iverilog -Wall -g 2012 \
        rtl/mips_cpu_*.v \
        test/mips_avalon_slave.v test/mips_CPU_bus_tb_change.v \
        -P mips_CPU_bus_tb.INSTR_INIT_FILE=\"${FILENAME}\"  \
        -P mips_CPU_bus_tb.DATA_INIT_FILE=\"${DATANAME}\" \
        -P mips_CPU_bus_tb.TIMEOUT_CYCLES=100 \
        -s mips_CPU_bus_tb \
        -o joe.out

    set +e
    # Auto-run and log into the a log file into 3-output
    ./joe.out > test/3-output/${BASENAME}.log
    # cat test/3-output/${BASENAME}.log  # Display debug output directly


    V0_OUT=$(grep "TB : V0" test/3-output/${BASENAME}.log)
    CYCLES=$(grep "TB : CYCLES" test/3-output/${BASENAME}.log)
    
    V0_OUT=${V0_OUT#"TB : V0 : "}
    CYCLES=${CYCLES#"TB : CYCLES : "}

    # If fatal is found anywhere in the log file, consider the testcase as failed
    if ! grep -q "FATAL" test/3-output/${BASENAME}.log && [ "$V0_OUT" == "" ]; then
        FAIL="Pass"
    else
        FAIL="Fail"
    fi

    echo $BASENAME $INSTR_NAME $FAIL $V0_OUT, $CYCLES

    set -e
    # Opens with savefiles, Cleanup
    # gtkwave mips_CPU_bus_tb.vcd mips_CPU_bus_tb.gtkw -a mips_CPU_bus_tb.gtkw; \

    rm joe.out
done;