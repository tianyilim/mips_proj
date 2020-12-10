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

TESTBENCH INSTRUCTIONS
1. Compile the testbench test cases generator using: 
   gcc MIPS_tb.c -o MIPS_tb

2. Generate the test cases for all instructions using:
   ./MIPS_tb

   To generate test cases for specific instructions, include them as a space delimited list when running MIP_tb, example:
   ./MIPS_tb addiu bne jl

3. The test cases will be generated into the file test_prog_list.txt

4. Compile the CPU testbench with:
   iverilog -Wall -g 2012 -s mips_CPU_bus_tb -o mips_CPU__tb mips_CPU__tb.v mips_avalon_slave.v mips_CPU_bus.v

5. Ensure that the compiled testbench is in the same directory as the file test_prog_list.txt, and run the testbench:
   ./mips_CPU_bus_tb

6. The file test_prog_list.txt contains many programs to test the MIPS instructions. When a testt program successfully generates the expected
   result in register_v0, a message saying "Pass...(so far) :p" will appear and the next test program will run.

7. If the CPU successfully finishes execution of one program, but the result in register_v0 is not the expected result, a message saying 
   "FAIL! $v0 does not agree with expected result!" will appear, and the next test program will be run.

8. Once the CPU finishes all test programs without the "fatal", the message "End of testbench." will appear, and the testbench exits.

9. If at any point the CPU runs into a "fatal" error like being active while reseeet is asserted or failing to start when reset is deasserted, or 
   trying to access invalid memory locations, the testbench immediately displays the relevant error message and exits.


------------------------------------------------------------------------------------------------------------------------------------------------------------


Brief description of MIPS_tb.c:

1. The functions rtype, itype, and jtype convert input parameters (of type int in C, which usually compiles to 32 bits integer with gcc)
   into one 32 bits MIPS instruction in raw binary. the logical AND performed in the functions are to ensure that only the relevant lower
   bits are kept and any mistakenly passed in higher bits are masked, before they are combined with logical OR. The positions of rd, rs, and
   rt are deliberately placed as they are in order to make the function call more intuitive, as if it was the MIPS instruction itself.

2. The functions test_<instruction name> takes in a pointer of type FILE, which is a pointer to the output file. These functions genearate a 
   short program snippet that aims to test the functionality of the relevant MIPS instruction, with all the values/memory locations randomised 
   to ensure that the CPU truly works.

3. In the main function, the random number generator is seeded with the current system time, and the output file is opened for writing. 
   If no arguments are passed in when the program is launched, it will generate 10 repetitions of the test program for each instruction, with 
   each test program's value/memory locations randomised. If at least one argument is passed in during the program launch, test programs will 
   only be generated for the instructions passed in (10 repetitions each, randomised values and memory locations).


------------------------------------------------------------------------------------------------------------------------------------------------------------


Brief description of the format of test_prog_list.txt:
1. The format of one "complete program" is as follows:
`<space><number of instructions><name of program as string>
#<space><memory location in hex><space><data/program in hex><optional comment starting with ;>
#<space><memory location in hex><space><data/program in hex><optional comment starting with ;>
#<space><memory location in hex><space><data/program in hex><optional comment starting with ;>
#<space><memory location in hex><space><data/program in hex><optional comment starting with ;>
#<space><memory location in hex><space><data/program in hex><optional comment starting with ;>
#<space><memory location in hex><space><data/program in hex><optional comment starting with ;>
#<space><memory location in hex><space><data/program in hex><optional comment starting with ;>
#<space><memory location in hex><space><data/program in hex><optional comment starting with ;>
#<space><memory location in hex><space><data/program in hex><optional comment starting with ;>
#<space><memory location in hex><space><data/program in hex><optional comment starting with ;>
@<space><expected result in $v0>

a) The "`" character indicates the start of a program.
b) Immediately after the "`" character is a number in decimal, stating the number of instructions expected to be run in this program 
   (so we can do cycles per instruction estimates).
c) Immediately following the number is a string that can be used to describe the program. It can be any string.
d) Each line that starts with "#" after the line starting with "`" will be a valid line containing a location-data pair, in hexadecimal.
   The line must start with "#", and then a space, and then the memory location in hex, then a space, then the data/program in hex.
e) It is optional to add a comment after the data/program in hex and it will be ignored by the testbench when it loads this file.
f) The final line of a program starts with "@", then a space, and then the expected result in $v0 register, in hexadecimal


2. An example of one "complete program" is as follows:

` 5 testing lw
# bfc00250 3fe8434b ; load data into data memory
# bfc00000 00008021 ; addu $s0, $zero, $zero
# bfc00004 3c10bcf0 ; lui $s0, ((randloc - 8) >> 16)
# bfc00008 26100248 ; addiu $s0, $s0, (randloc - 8) & 0xffff
# bfc0000c 8e020008 ; lw $v0, 8($s0)
# bfc00010 00000008 ; jr $zero
@ 3fe8434b


------------------------------------------------------------------------------------------------------------------------------------------------------------


Brief description of what mips_CPU_bus_tb.v does:

1. The testbench will instantiate one instance of mips_avalon_slave as MEM, and all the wires connecting into it start with "mem_".

2. The testbench will instantiate one instance of mips_CPU_bus as CPU, and all the wires connecting to it start with "cpu".

3. The CPU clock and the memory clock are controlled by 2 separate initial blocks, with different frequencies to simulate a real computer 
   computer implementation, where the memory frequency is slightly lower than the CPU frequency. The CPU clock has some code to keep track of the 
   total number of cycles taken by the current program to run, and a timeout function in case the program fails to halt. The memory clock has no
   such feature.

4. The next block is an always block which checks if the CPU tries to access and invalid memory location. If the CPU is running (i.e. not reset),
   and the memory is driven to access an invalid memory location, then we immediately declare that the CPU failed the test case.

5. The next always block acts as a multiplexer which allows either the CPU to drive the inputs of the memory, or to allow the testbench to drive
   the inputs of the memory. The outputs of the memory is always connected to the CPU without any multiplexer.

6. The next always block checks to see if the CPU suddenly becomes active when it is reset (testbench is loading program into memory).
   The reason the condition in the if clause is not (cpu_reset == 1 && cpu_active ==1) is because if that were the case, false positives would
   be generated when cpu_reset is asserted but the next clock rising edge has not arrived to let the CPU deassert cpu_active.

7. The last initial block is the main testbench. The testbench initialises the various variables used by it, and then opens the file test_prog_list.txt
(which was generated by the compiled MIPS_tb.c) for reading.

   a) The testbench will loop through each test program, and firstly, it will reset the cpu, and wait for the next cpu clock rising edge to ensure it 
      is truly reset and not active first.
   b) Then, the testbench will set the multiplexer in point 5 to allow "writing directly to the memory". This allows us to have a compact "memory file"
      as we do not need to pad space in between "far apart" memory locations with 0, and we write only to the targeted memory directly. The while loop 
      will loop through each character in the file to search for special characters (the format of test_prog_list.txt is explained above) to identify 
      how to handle the input in the if-else blocks. The verilog built-in functions generate a lot of warning messages in the runtime if their result 
      is not assigned to  variable, hence we just assign them into a dummy variable shut_up. After the relevant data has been loaded into the memory,
      the multiplexer is changed to give control of memory back to the CPU.
   c) Then, the cpu_reset signal is deasserted, the cpu cycles counter mentioned in point 3 is reset, and the CPU is allowed to run. An if clause is 
      used to check if the CPU fails to start even after a positive clock edge is received, and if so, declare that the CPU failed the test case.
   d) The testbench then waits for the falling edge of the cpu_active signal.
   e) The testbench checks the result from the cpu_register_v0 by comparing it with the expected result. If the result is as expected, then the testbench 
      will proceed to the next test program, else it will declare that the CPu fails the test case.