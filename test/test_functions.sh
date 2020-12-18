#!/bin/bash

# Assumption is that assembler has been recompiled; it has been run before hand in compile_tests.sh
# Assemble test-cases
if (("$#" < 1)); then
    echo "Please enter the name of the directory."
    exit 1
else
    TEST_DIR=$1
fi

# instructions to test / compile for
# Slice the input argv array without considering the first (directory) element
TEST_INSTRS=()
if (("$#" > 1)); then
    for args in "${@:2}"; do
        if [ ! "$args" = "" ]; then
            TEST_INSTRS+=("$args") # Instruction
        else
            TEST_INSTRS=("")
            break
        fi
    done
else
    # echo "No argument given, will run for all testcases"
    TEST_INSTRS=("")
fi

# Clean out the testcases
rm test/function/logs/* > /dev/null 2>&1
rm test/function/waveforms/* > /dev/null 2>&1
rm test/function/expected_output/* > /dev/null 2>&1
rm test/function/src_bin/*.data.hex > /dev/null 2>&1

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

for TESTCASE in "${TEST_INSTRS[@]}"; do
    # echo \'"$TESTCASE"\'
    
    for FILENAME in test/function/src_asm/*"${TESTCASE}"*.asm.txt; do
        [ -e "$FILENAME" ] || continue # Avoid case where there are no matches
        # echo "Assembling '$FILENAME'"

        BASENAME=`basename ${FILENAME}` # Name of test case
        BASENAME="${BASENAME%.*.*}"
        TESTNAME="${BASENAME%_*}"
        INSTR_NAME="${BASENAME#*_}"
        # echo $BASENAME, $TESTNAME, $INSTR_NAME

        python3 test/parse_comments.py ${FILENAME} # Get rid of comments and move items into the test file

        ./test/Assembler/src/assembler.out # Perform assembly
        if [ $? != 0 ]; then
            # echo $FILENAME, $BASENAME.instr.hex # Debug outputs
            cat test/Assembler/src/test.txt # Debug outputs
            # Remove the assembled file (if it exists) if no success
            rm test/function/src_bin/$BASENAME.instr.hex
        else
            cp test/Assembler/src/output.txt test/function/src_bin/$BASENAME.instr.hex # Write to output only if successful
        fi

        # There will be a Python file with corresponding name that generates inputs and outputs
        python3 test/function/src_py/"$BASENAME".py

        COMMENT=$(grep -w --ignore-case "comment" test/function/src_asm/${BASENAME}.asm.txt)
        # echo ""
        # echo "Testing function ${BASENAME} with $COMMENT"

        # Run testbench and check if outputs are as expected.
        for INPUT in test/function/src_bin/"${BASENAME}"*.data.hex; do
            if [ ! -e "$INPUT" ]; then
                echo "No input tests found for $BASENAME"
                exit 1
            fi

            INPUT_BASENAME=`basename ${INPUT}` # Name for each test case
            INPUT_BASENAME="${INPUT_BASENAME%.*.*}"
            INSTR_NUM="${INPUT_BASENAME#*_*_}"
            # echo $INSTR_NUM

            iverilog -g 2012 ${TESTING} \
            test/mips_avalon_slave.v test/mips_CPU_bus_tb.v \
            -P mips_CPU_bus_tb.INSTR_INIT_FILE=\"test/function/src_bin/"${BASENAME}.instr.hex"\"  \
            -P mips_CPU_bus_tb.DATA_INIT_FILE=\""${INPUT}"\" \
            -P mips_CPU_bus_tb.TIMEOUT_CYCLES=50000 \
            -P mips_CPU_bus_tb.READ_DELAY=1 \
            -s mips_CPU_bus_tb \
            -o joe.out

            # Auto-run and log into the a log file
            ./joe.out > test/function/logs/${INPUT_BASENAME}.log
            cp mips_CPU_bus_tb.vcd test/function/waveforms/${INPUT_BASENAME}.vcd
            # cat test/3-output/${BASENAME}.log  # Display debug output directly

            V0_OUT=$(grep "TB : V0" test/function/logs/${INPUT_BASENAME}.log)
            CYCLES_STR=$(grep "TB : CYCLES" test/function/logs/${INPUT_BASENAME}.log)
            V0_OUT=${V0_OUT#"TB : V0 : "}

            V0_CHECK=$(cat test/function/expected_output/${INPUT_BASENAME}.txt)
            DIFF_FOUND=$(diff -q --ignore-all-space --ignore-blank-lines --strip-trailing-cr --ignore-case <(echo $V0_OUT) <(echo $V0_CHECK)) # compare expected and given output
            DIFFPASS=$?

            FATAL_FOUND=$(grep "FATAL" test/function/logs/${INPUT_BASENAME}.log)
            FATAL_PASS=$?
        
            # If fatal is found anywhere in the log file, consider the testcase as failed
            if [ $DIFFPASS = 0 ] && [ $FATAL_PASS = 1 ]; then
                FAIL="Pass"
                PASS_COUNT=$PASS_COUNT+1
            else
                FAIL="Fail"
                FAIL_COUNT=$FAIL_COUNT+1
            fi

            echo -e ""$TESTNAME"_"$INSTR_NUM" "$INSTR_NAME" $FAIL | "V0: "$V0_OUT, "EXP: "$V0_CHECK | $FATAL_FOUND | $COMMENT"
        done
    done
done

rm joe.out > /dev/null 2>&1

# Factorial cases

# Fibonacci cases

# Array Sum

# Array Average

# Array Search

# Array Sort

# Linked-list traverse