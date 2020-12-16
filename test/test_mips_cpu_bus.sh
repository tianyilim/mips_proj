#!/bin/bash

chmod +x test/test_hex_files.sh test/compile_tests.sh test/test_functions.sh

if (("$#" < 1)); then
    # echo "Please enter the name of the directory."
    exit 1
else
    TEST_DIR=$1
    # get rid of trailing / if it exists
    TEST_DIR=${TEST_DIR%/}
fi

# instructions to test / compile for
# Slice the input argv array without considering the first (directory) element
TEST_INSTRS=()
COMPILE=1
VERBOSE=0

if (("$#" > 1)); then
    for args in "${@:2}"; do
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

# echo \'"${TEST_INSTRS[@]}"\'

# assemble the code
if [ $COMPILE -gt 0 ]; then
    # echo "Compiling code..."
    ./test/compile_tests.sh "${TEST_INSTRS[@]}"
fi

if [ ! $COMPILE = 2 ]; then
    # echo "Running testcases..."
    set -e
    ./test/test_hex_files.sh "$TEST_DIR" "${TEST_INSTRS[@]}"
    ./test/test_functions.sh "$TEST_DIR" "${TEST_INSTRS[@]}"   # Todo - link the functions to their test-cases
    exit $?
fi