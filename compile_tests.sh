#!/bin/bash

# Recompile assembler code
g++ test/Assembler/src/assembler.cpp -o test/Assembler/src/assembler.out

declare -i PASS=0
declare -i FAIL=0

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
    for FILENAME in test/0-assembly/${i}*.asm.txt; do
        [ -e "$FILENAME" ] || continue # Avoid case where there are no matches
        BASENAME=`basename ${FILENAME}` # Name of test case
        BASENAME="${BASENAME%.*.*}"

        python3 test/parse_comments.py ${FILENAME} # Get rid of comments and move items into the test file

        ./test/Assembler/src/assembler.out # Perform assembly
        if [ $? != 0 ]; then
            echo $FILENAME, $BASENAME.instr.hex # Debug outputs
            cat test/Assembler/src/test.txt # Debug outputs
            # Remove the assembled file (if it exists) if no success
            rm test/1-binary/$BASENAME.instr.hex
            FAIL=$FAIL+1
        else
            cp test/Assembler/src/output.txt test/1-binary/$BASENAME.instr.hex # Write to output only if successful
            PASS=$PASS+1
        fi
        # cat test/1-binary/$BASENAME.instr.hex # Debug outputs
    done
done
echo $FAIL, $PASS