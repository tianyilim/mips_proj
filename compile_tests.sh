#!/bin/bash

# Recompile assembler code
g++ test/Assembler/src/assembler.cpp -o test/Assembler/src/assembler.out

if [ $# = 0 ]; then
    echo "No argument given, will run for all testcases"

    # Run through items to be assembled
    for FILENAME in test/0-assembly/*.asm.txt; do
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
        else
            cp test/Assembler/src/output.txt test/1-binary/$BASENAME.instr.hex # Write to output only if successful
        fi
        # cat test/1-binary/$BASENAME.instr.hex # Debug outputs
    done

else
    for arg do 
        echo "Assembling all tests starting with $arg"
        for FILENAME in test/0-assembly/${arg}*.asm.txt; do
            [ -e "$FILENAME" ] || continue # Avoid case where there are no matches
            BASENAME=`basename ${FILENAME}` # Name of test case
            BASENAME="${BASENAME%.*.*}"

            python3 test/parse_comments.py ${FILENAME} # Get rid of comments

            ./test/Assembler/src/assembler.out # Perform assembly
            if [ $? != 0 ]; then
                echo $FILENAME, $BASENAME.instr.hex # Debug outputs
                cat test/Assembler/src/test.txt # Debug outputs
                # Remove the assembled file (if it exists) if no success
                test/1-binary/$BASENAME.instr.hex
            else
                cp test/Assembler/src/output.txt test/1-binary/$BASENAME.instr.hex # Write to output only if successful
            fi

            # cat test/1-binary/$BASENAME.instr.hex # Debug outputs

        done
    done
fi