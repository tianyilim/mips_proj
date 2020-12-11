#!/bin/bash

# Recompile assembler code
g++ test/Assembler/src/assembler.cpp -o test/Assembler/src/assembler.out

# Run through items to be assembled
for FILENAME in test/0-assembly/*.asm.txt; do
    [ -e "$FILENAME" ] || continue # Avoid case where there are no matches
    BASENAME=`basename ${FILENAME}` # Name of test case
    BASENAME="${BASENAME%.*.*}"
    echo $FILENAME, $BASENAME.instr.hex # Debug outputs

    # Move items into the test file
    cp  ${FILENAME} test/Assembler/src/test.txt
    # cat test/Assembler/src/test.txt # Debug outputs
    # Perform assembly
    ./test/Assembler/src/assembler.out
    # Write to output file
    cp  test/Assembler/src/output.txt test/1-binary/$BASENAME.instr.hex
    # cat test/1-binary/$BASENAME.instr.hex # Debug outputs

    continue

done