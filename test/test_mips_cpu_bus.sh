#!/bin/bash

if (("$#" < 1)); then
    echo "Please enter the name of the directory."
    exit 1
else
    TEST_DIR=$1
fi

# instructions to test / compile for
# Slice the input argv array without considering the first (directory) element
TEST_INSTRS=()
COMPILE=1
VERBOSE=0

if (("$#" > 1)); then
    for args in "${@:2}"; do
        echo "$args"
        if [ "$args" = "-nc" ]; then
            echo "Skipping compilation step"
            COMPILE=0
        elif [ "$args" = "-c" ]; then
            echo "Compile only"
            COMPILE=2
        elif [ "$args" = "-v" ]; then
            echo "Verbose mode"
            VERBOSE=1
        else
            TEST_INSTRS+=("$args") # Instruction
        fi
    done
else
    TEST_INSTRS+=("")
fi

# assemble the code
if [ $COMPILE -gt 0 ]; then
    echo "Compiling code..."
    ./test/compile_tests.sh "${TEST_INSTRS[@]}"
fi

if [ ! $COMPILE = 2 ]; then
    echo "Running testcases..."
    ./test/test_hex_files.sh "$TEST_DIR" "${TEST_INSTRS[@]}"
fi