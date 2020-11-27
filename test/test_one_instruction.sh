# bin bash

#set eou pipefail??


#arguments
SOURCE="$1"       
TESTNAME="$2"
INSTRUCTION="$3"

comment=$(grep -w comment /test/0-assembly/${TESTNAME}.asm.txt)  #extract comment
comment=${comment:8}     #maybe 9 instead for space?




#assembly                      DIFF DIRECTORY?? bin?
bin/assembler <test/0-assembly/${TESTNAME}.asm.txt >test/1-binary/${TESTNAME}.hex.txt



# Compile a specific simulator for this variant and testbench.
# -s specifies exactly which testbench should be top-level
# The -P command is used to modify the RAM_INIT_FILE parameter on the test-bench at compile-time
iverilog -g 2012 \
   ${SOURCE}/mips_cpu_bus.v test/mips_cpu_bus_tb.v test/mips_avalon_slave.v \  #ram in test file?
   -s mips_cpu_bus_tb \                                               #compile all files in source?
   -P mips_cpu_bus_tb.RAM_INIT_FILE=\"test/1-binary/${TESTNAME}.hex.txt\" \  #harvard
   -o test/2-simulator/CPU_MU0_bus_tb_${TESTNAME}



# we run the test

# Use +e to disable automatic script failure if the command fails, as
# it is possible the simulation might go wrong.
set +e
test/2-simulator/CPU_MU0_bus_tb_${TESTNAME} > test/3-output/CPU_MU0_bus_tb_${TESTNAME}.stdout
# Capture the exit code of the simulator in a variable
RESULT=$?  
set -e


# Check whether the simulator returned a failure code, and immediately quit
if [[ "${RESULT}" -ne 0 ]] ; then
   echo "${INSTRUCTION} ${TESTNAME} Fail ${comment}"    
   exit                          # still need to compare to ref to know if pass
fi




>&2 echo "    Extracting result of OUT instructions"  #NEED TO DO
#depends on format !!!!!!!!!!!!!!!!!!!!!!!!!!!!
#no OUT instr  regv0




>&2 echo "  b - Comparing output"
# Note the -w to ignore whitespace
set +e
diff -w test/4-reference/${TESTNAME}.out test/3-output/CPU_MU0_bus_tb_${TESTNAME}.out
RESULT=$?         
set -e



# Based on whether differences were found, either pass or fail
if [[ "${RESULT}" -ne 0 ]] ; then
   echo "${INSTRUCTION} ${TESTNAME} Fail ${comment}"
else
   echo "${INSTRUCTION} ${TESTNAME} Pass ${comment}"
fi


#echo comments












#1) assembly
#2)compiling tb and mips
#3)run test bench
#4)extract result
#5) run reference if needed
#6) compare output

#7) where does comment come from??
# assembly files always comment=?? nothing?

#from c?

#Your test-bench should never modify anything located in the mips source directory. So it should not create any files in the source directory (e.g. rtl), and it definitely should not modify any of the files


#do we include reference simulator in submission?
# so instr can be added
#simulator < input > test/4-reference

#replace with /(nothing)  maybe better version cut 8/9



