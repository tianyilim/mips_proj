# bin bash

#set eou pipefail??


#arguments
SOURCE="$1"     #source directory   
INSTRUCTION="$2"

TESTCASES="test/0-assembly/${INSTRUCTION}*.asm.txt"    


# Loop over every file matching the TESTCASES pattern
for i in ${TESTCASES} ; do

    TESTNAME=$(basename ${i} .asm.txt)        
 
    ./test_one_instruction.sh ${SOURCE} ${TESTNAME} ${INSTRUCTION}      
done







#t. If no instruction is specified, then all test-cases should be run. Your test-bench may choose to ignore the instruction filter, and just produce all outputs.
# if *



#Auxiliary files
#Your test-bench can make use of any number of auxiliary files and directories, for example things like testcase inputs, pre-compiled object files, or whatever you like. You should aim to keep the submission as small as possible (e.g. using .gitignore files), but there is no penalty for including more than is needed.
#but deliverables says otherwise??
