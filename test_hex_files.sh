#!/bin/bash

# Performs assembly within test/0-assembly
# ./compile_tests.sh
# Tests all hex instruction files within test/1-binary/
# ./parse_intermediate_files.sh

# colors
RESTORE='\033[0m'
RED='\033[00;31m'

cases=()

if [ $# = 0 ]; then
    echo "No argument given, will run for all testcases"
    cases+=("")
else
    for arg do
        cases+=("$arg"_)
    done
fi

for i in "${cases[@]}"; do
    for FILENAME in test/1-binary/${i}*.instr.hex; do
        [ -e "$FILENAME" ] || continue # Avoid case where there are no matches
        
        NAME="${FILENAME%.*}"
        NAME="${NAME%.*}"
        BASENAME=`basename ${NAME}` # Name of test case
        INSTR_NAME=${BASENAME%_*}

        declare -i INSTR_COUNT=`wc -l $FILENAME | cut -f1 -d' '`; # echo $INSTR_COUNT

        if [ ! -e test/2-simulator/${BASENAME}.txt ]; then
            echo "Test answer ${BASENAME} does not exist"
            continue
        fi
        # if sample output does not exist, don't bother running the test case

        if [ -f ${NAME}.data.hex ]; then
            DATANAME=${NAME}.data.hex
        else
            DATANAME="test/datamem.txt"
        fi

        # List of files:
            # rtl/mips_cpu_bus.v \
            # rtl/mips_cpu_cache_controller.v \
            # rtl/mips_cpu_cache_data.v \
            # rtl/mips_cpu_cache_instr.v \
            # rtl/mips_cpu_cache_writebuffer.v \
            # rtl/mips_cpu_eight_bit_extension.v \
            # rtl/mips_cpu_harvard.v \
            # rtl/mips_cpu_register_file.v \
            # rtl/mips_cpu_sixteen_bit_extension.v \

        iverilog -Wall -g 2012 \
            rtl/mips_cpu_*.v \
            test/mips_avalon_slave.v test/mips_CPU_bus_tb_change.v \
            -P mips_CPU_bus_tb.INSTR_INIT_FILE=\"${FILENAME}\"  \
            -P mips_CPU_bus_tb.DATA_INIT_FILE=\"${DATANAME}\" \
            -P mips_CPU_bus_tb.TIMEOUT_CYCLES=10000 \
            -P mips_CPU_bus_tb.READ_DELAY=2 \
            -s mips_CPU_bus_tb \
            -o joe.out

        # Save the waveforms

        # Auto-run and log into the a log file into 3-output
        ./joe.out > test/3-output/${BASENAME}.log
        cp mips_CPU_bus_tb.vcd test/waveforms/${BASENAME}.vcd
        # cat test/3-output/${BASENAME}.log  # Display debug output directly

        V0_OUT=$(grep "TB : V0" test/3-output/${BASENAME}.log)
        CYCLES_STR=$(grep "TB : CYCLES" test/3-output/${BASENAME}.log)
        V0_OUT=${V0_OUT#"TB : V0 : "}
        declare -i CYCLES=${CYCLES_STR#"TB : CYCLES : "}
        CPI=$(expr $CYCLES / $INSTR_COUNT)  # Check if CPI limit has been exceeded
        if [ $CPI -gt 36 ]; then
            CPI_PASS=0
            CPI="${RED}$CPI${RESTORE}"
        else
            CPI_PASS=1
        fi

        V0_CHECK=$(cat test/2-simulator/${BASENAME}.txt)
        DIFF_FOUND=$(diff -q --ignore-all-space --ignore-blank-lines --strip-trailing-cr --ignore-case <(echo $V0_OUT) test/2-simulator/${BASENAME}.txt) # compare expected and given output
        DIFFPASS=$?
        if [ ! $DIFFPASS = 0 ]; then
            V0_CHECK="${RED}$V0_CHECK${RESTORE}"
        fi

        FATAL_FOUND=$(grep "FATAL" test/3-output/${BASENAME}.log)
        FATAL_PASS=$?
    
        # If fatal is found anywhere in the log file, consider the testcase as failed
        if [ $DIFFPASS = 0 ] && [ $FATAL_PASS = 1 ] && [ ! $CPI_PASS = 0 ]; then
            FAIL="Pass"
        else
            FAIL="${RED}Fail${RESTORE}"
        fi

        echo -e "$BASENAME $INSTR_NAME $FAIL | "V0: "$V0_OUT, "EXP: "$V0_CHECK, "CYCLES: "$CYCLES, "INSTRS: "$INSTR_COUNT, "CPI: "$CPI, $FATAL_FOUND"

        # Opens with savefiles, Cleanup
        # gtkwave mips_CPU_bus_tb.vcd mips_CPU_bus_tb.gtkw -a mips_CPU_bus_tb.gtkw; \

    done;
done

rm joe.out