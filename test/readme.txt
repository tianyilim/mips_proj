run script from directory mips_proj

eg: test/test_mips_cpu_bus.sh rtl j

brief description of what the script does:
1)takes argument specifying source directory and an optional argument specifying which instruction to test
2)looks for all tests relating to specified instruction in test/0-assembly
3)inputs the files into the assembler and outputs it into 1-binary
4)compiles all files in the source directory with the testbench and avalon_slave 
5)runs the program and checks for failure exit code
6)extracts out v0 output into a text file and compares it to a reference

------------------------------------------------------------------------------------------------------------------------------------------------------------
write test files "*.asm.txt" in mips_assembly in the 0-assembly folder

datamem.txt - an example initialisation of data memory for commonly used data values in tests

generaltests.txt
-lists some general testcases for types of isntructions

------------------------------------------------------------------------------------------------------------------------------------------------------------

