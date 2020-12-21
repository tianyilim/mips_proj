#!/bin/bash

# Performs assembly within test/0-assembly
# ./compile_tests.sh
# Tests all hex instruction files within test/1-binary/
# ./parse_intermediate_files.sh

# colors
RESTORE='\033[0m'
RED='\033[00;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'

if (("$#" < 1)); then
    echo "Please enter the name of the directory."
    exit 1
else
    TEST_DIR=$1
fi

# Find test directory
if ! find "${TEST_DIR}"/mips_cpu/*.v 1> /dev/null 2>&1; then
    # No mips folder test directory
    TESTING="${TEST_DIR}"/mips_cpu_*.v
elif ! find "${TEST_DIR}"/mips_cpu*.v 1> /dev/null 2>&1; then
    # No mips files in rtl
    TESTING="${TEST_DIR}"/mips_cpu/*.v
else
    # Both testing files
    TESTING=""${TEST_DIR}"/mips_cpu/*.v "${TEST_DIR}"/mips_cpu*.v"
fi
# echo $TESTING

# Clean out the testcases
rm test/waveforms/*.vcd > /dev/null 2>&1
rm test/3-output/* > /dev/null 2>&1

# instructions to test / compile for
# Slice the input argv array without considering the first (directory) element
TEST_INSTRS=()
if (("$#" > 1)); then
    for args in "${@:2}"; do
        if [ ! "$args" = "" ]; then
            TEST_INSTRS+=("$args"_) # Instruction
        else
            TEST_INSTRS=("")
            break
        fi
    done
else
    # echo "No argument given, will run for all testcases"
    TEST_INSTRS=("")
fi

# echo "$TEST_DIR"
# echo \'"${TEST_INSTRS[@]}"\'

declare -i PASS_COUNT=0
declare -i FAIL_COUNT=0

TEST_DELAY=( 0 1 5 )
for DELAY in "${TEST_DELAY[@]}"; do
    # echo \'$DELAY\'
    # continue

    for i in "${TEST_INSTRS[@]}"; do
        for FILENAME in test/1-binary/${i}*.instr.hex; do
            [ -e "$FILENAME" ] || continue # Avoid case where there are no matches
            
            NAME="${FILENAME%.*}"
            NAME="${NAME%.*}"
            BASENAME=`basename ${NAME}` # Name of test case
            INSTR_NAME=${BASENAME%_*}

            declare -i INSTR_COUNT=`wc -l $FILENAME | cut -f1 -d' '`; # echo $INSTR_COUNT

            if [ ! -e test/2-reference/${BASENAME}.txt ]; then
                # echo "Test answer ${BASENAME} does not exist"
                continue
            fi
            # if sample output does not exist, don't bother running the test case

            if [ -e "${NAME}.data.hex" ]; then
                DATANAME=test/1-binary/${BASENAME}.data.hex
            elif [ -e "${NAME}.data.txt" ]; then
                DATANAME=test/1-binary/${BASENAME}.data.txt
            else
                DATANAME="test/datamem.txt"
            fi

            if [ -e "${NAME}.ovf.hex" ]; then
                OVFNAME=test/1-binary/${BASENAME}.ovf.hex
            elif [ -e "${NAME}.ovf.txt" ]; then
                OVFNAME=test/1-binary/${BASENAME}.ovf.txt
            else
                OVFNAME=""
            fi

            # echo \'"$NAME"\', \'"$DATANAME"\', \'"$OVFNAME"\'

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
            set -e

            # iverilog -g 2012 ${TESTING} -Wall \
            # test/mips_avalon_slave.v test/mips_CPU_bus_tb.v \
            # -P mips_CPU_bus_tb.INSTR_INIT_FILE=\"${FILENAME}\"  \
            # -P mips_CPU_bus_tb.DATA_INIT_FILE=\"${DATANAME}\" \
            # -P mips_CPU_bus_tb.OVF_INIT_FILE=\"${OVFNAME}\" \
            # -P mips_CPU_bus_tb.TIMEOUT_CYCLES=1000 \
            # -P mips_CPU_bus_tb.READ_DELAY=$DELAY \
            # -s mips_CPU_bus_tb \
            # -o joe.out

            iverilog -g 2012 ${TESTING} -Wall \
            test/mips_avalon_slave.v test/mips_CPU_bus_tb.v \
            -P mips_CPU_bus_tb.INSTR_INIT_FILE=\"${FILENAME}\"  \
            -P mips_CPU_bus_tb.DATA_INIT_FILE=\"${DATANAME}\" \
            -P mips_CPU_bus_tb.OVF_INIT_FILE=\"${OVFNAME}\" \
            -P mips_CPU_bus_tb.TIMEOUT_CYCLES=20000 \
            -P mips_CPU_bus_tb.READ_DELAY=$DELAY \
            -s mips_CPU_bus_tb \
            -o joe.out
            
            set +e

            # Save the waveforms

            # Auto-run and log into the a log file into 3-output
            ./joe.out > test/3-output/${BASENAME}_${DELAY}.log
            cp mips_CPU_bus_tb.vcd test/waveforms/${BASENAME}_${DELAY}.vcd > /dev/null 2>&1
            cp test/3-output/memory_out.hex test/3-output/${BASENAME}_${DELAY}_mem.hex > /dev/null 2>&1
            # cat test/3-output/${BASENAME}.log  # Display debug output directly

            V0_OUT=$(grep "TB : V0" test/3-output/${BASENAME}_${DELAY}.log)
            CYCLES_STR=$(grep "TB : CYCLES" test/3-output/${BASENAME}_${DELAY}.log)
            V0_OUT=${V0_OUT#"TB : V0 : "}
            declare -i CYCLES=${CYCLES_STR#"TB : CYCLES : "}
            CPI=$(expr $CYCLES / $INSTR_COUNT)  # Check if CPI limit has been exceeded
            CPI_PASS=1 # Removed CPI pass factor
            if [ $CPI -gt 36 ]; then
                # CPI="${RED}$CPI${RESTORE}"
                CPI="$CPI"
            else
                # CPI="${YELLOW}$CPI${RESTORE}"
                CPI="$CPI"
            fi

            if [ -e test/2-reference/${BASENAME}.mem.txt ]; then
                # echo "Ref text test/2-reference/${BASENAME}.mem.txt found"
                MEM_DIFF=$(cmp test/3-output/${BASENAME}_${DELAY}_mem.hex test/2-reference/${BASENAME}.mem.txt)
                MEM_CMP=$?
                if [ ! $MEM_CMP = 0 ]; then
                    MEM_DIFF="Ref Memory and Output differ on ${MEM_DIFF#*, }"
                else 
                    MEM_DIFF=""
                fi
            else
                # echo "Ref text test/2-reference/${BASENAME}.mem.txt not found"
                MEM_DIFF=""
                MEM_CMP=0
            fi

            V0_CHECK=$(cat test/2-reference/${BASENAME}.txt)
            DIFF_FOUND=$(diff -q --ignore-all-space --ignore-blank-lines --strip-trailing-cr --ignore-case <(echo $V0_OUT) test/2-reference/${BASENAME}.txt) # compare expected and given output
            DIFFPASS=$?
            if [ ! $DIFFPASS = 0 ]; then
                V0_CHECK="$V0_CHECK"
                # V0_CHECK="${RED}$V0_CHECK${RESTORE}"
            fi

            FATAL_FOUND=$(grep "FATAL" test/3-output/${BASENAME}_${DELAY}.log)
            FATAL_PASS=$?

            COMMENT=$(grep -w --ignore-case "comment" test/0-assembly/${BASENAME}.asm.txt)
        
            # If fatal is found anywhere in the log file, consider the testcase as failed
            if [ $DIFFPASS = 0 ] && [ $FATAL_PASS = 1 ] && [ ! $CPI_PASS = 0 ] && [ $MEM_CMP = 0 ]; then
                # FAIL="${GREEN}Pass${RESTORE}"
                FAIL="Pass"
                PASS_COUNT=$PASS_COUNT+1
            else
                # FAIL="${RED}Fail${RESTORE}"
                FAIL="Fail"
                FAIL_COUNT=$FAIL_COUNT+1
            fi

            echo -e "$BASENAME $INSTR_NAME $FAIL | "V0: "$V0_OUT, "EXP: "$V0_CHECK, "CYCLES: "$CYCLES, "RAM_DELAY: "$DELAY | $FATAL_FOUND | $MEM_DIFF | $COMMENT"

            # Opens with savefiles, Cleanup
            # gtkwave mips_CPU_bus_tb.vcd mips_CPU_bus_tb.gtkw -a mips_CPU_bus_tb.gtkw; \

        done;
    done
done

# echo -e "Ran $(($FAIL_COUNT+$PASS_COUNT)) testcases."
# echo -e "${GREEN}$PASS_COUNT${RESTORE} testcases passed."
# echo -e "${RED}$FAIL_COUNT${RESTORE} testcases failed."

# echo -e "$PASS_COUNT testcases passed."
# echo -e "$FAIL_COUNT testcases failed."
rm joe.out > /dev/null 2>&1
rm test/3-output/memory_out.hex > /dev/null 2>&1

if [ ! $FAIL_COUNT = 0 ]; then
    # echo "Testbench failed."
    exit 1
else
    # echo "Testbench passed."
    exit 0
fi