#!/bin/bash

# Performs assembly within test/0-assembly
# ./compile_tests.sh
# Tests all hex instruction files within test/1-binary/
# ./parse_intermediate_files.sh

cases=()

if [ $# = 0 ]; then
    echo "No argument given, will run for all testcases"
    cases+=("")
else
    for arg do
        cases+=("$arg")
    done
fi

for i in "${cases[@]}"; do
    for FILENAME in test/1-binary/${i}*.instr.hex; do
        [ -e "$FILENAME" ] || continue # Avoid case where there are no matches
        
        NAME="${FILENAME%.*}"
        NAME="${NAME%.*}"
        BASENAME=`basename ${NAME}` # Name of test case
        INSTR_NAME=${BASENAME%_*}

        # [ -e test/2-simulator/"${BASENAME}".txt ] || echo "No sample out for "${BASENAME}""; continue
        # if sample output does not exist, don't bother running the test case

        if [ -f ${NAME}.data.hex ]; then
            DATANAME=${NAME}.data.hex
        else
            DATANAME="test/datamem.txt"
        fi

        iverilog -Wall -g 2012 \
            rtl/mips_cpu_*.v \
            test/mips_avalon_slave.v test/mips_CPU_bus_tb_change.v \
            -P mips_CPU_bus_tb.INSTR_INIT_FILE=\"${FILENAME}\"  \
            -P mips_CPU_bus_tb.DATA_INIT_FILE=\"${DATANAME}\" \
            -P mips_CPU_bus_tb.TIMEOUT_CYCLES=10000 \
            -s mips_CPU_bus_tb \
            -o joe.out

        # Save the waveforms

        set +e
        # Auto-run and log into the a log file into 3-output
        ./joe.out > test/3-output/${BASENAME}.log
        cp mips_CPU_bus_tb.vcd test/waveforms/${BASENAME}.vcd
        # cat test/3-output/${BASENAME}.log  # Display debug output directly

        V0_OUT=$(grep "TB : V0" test/3-output/${BASENAME}.log)
        CYCLES=$(grep "TB : CYCLES" test/3-output/${BASENAME}.log)
        V0_OUT=${V0_OUT#"TB : V0 : "}
        CYCLES=${CYCLES#"TB : CYCLES : "}

        V0_CHECK=$(cat test/2-simulator/${BASENAME}.txt)
        diff --ignore-all-space -i <(echo $V0_OUT) test/2-simulator/${BASENAME}.txt > /dev/null # compare expected and given output
        DIFFPASS=$?

        # If fatal is found anywhere in the log file, consider the testcase as failed
        if [ $DIFFPASS = 0 ] && ! grep -q "FATAL" test/3-output/${BASENAME}.log; then
            FAIL="Pass"
            echo $BASENAME $INSTR_NAME $FAIL $V0_OUT, $CYCLES
        else
            FAIL="Fail"
            echo $BASENAME $INSTR_NAME $FAIL "V0: "$V0_OUT, "EXP: "$V0_CHECK $CYCLES
        fi


        set -e
        # Opens with savefiles, Cleanup
        # gtkwave mips_CPU_bus_tb.vcd mips_CPU_bus_tb.gtkw -a mips_CPU_bus_tb.gtkw; \

    done;
done

rm joe.out