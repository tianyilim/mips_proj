#!/bin/bash
set -eou pipefail


#arguments
SOURCE="$1"     #source directory   
INSTRUCTION=${2:-}

TESTCASES="test/0-assembly/${INSTRUCTION}*.asm.txt"    


# Loop over every file matching the TESTCASES pattern
for i in ${TESTCASES} ; do

    TESTNAME=$(basename ${i} .asm.txt)        
 
    ./test_one_instruction.sh ${SOURCE} ${TESTNAME} ${INSTRUCTION}      
done







