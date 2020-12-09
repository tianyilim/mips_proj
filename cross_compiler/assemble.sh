#!/bin/bash

# replace test with $variable

# -g: also shows debug info, required later
# -c: Compiles the given file
# -S: Assembles to an assembly file
# -T: Add linker file
# -Wl,--build-id=none : Removes the build metadata so that the linker script does start at BFC00000 
# -nostdlib: Does not include standard library functions like printf (that we don't need anyway)
# -O3: optimises away the extraneous stack stuff
# -march=mips1: only use instructions from the mips1 ISA
# -mfp32: assumes floating point regs are 32-bit wide (but not applicable to us)
#       : Reqd for the march=mips1 flag

# Generate an assembly file and an object file
mipsel-linux-gnu-gcc -S -g -O3 -nostdlib -march="mips1" -mfp32 -Wl,--build-id=none -T linker_file.ld test.c -o test.mips.s
mipsel-linux-gnu-gcc -c -g -O3 -nostdlib -march="mips1" -mfp32 -Wl,--build-id=none -T linker_file.ld test.c -o test.mips.o
mipsel-linux-gnu-gcc -g -O3 -nostdlib -march="mips1" -mfp32 -Wl,--build-id=none -T linker_file.ld test.c -o test.mips.elf

# -f: Shows sections in the file
# -S: Display source code intermixed with assembly code, if possible (if previously compiled with -g)
# -d: Dipslays assembly code only
# -j .data: Shows (unformatted) the content of the data section
# -w: W I D E format (for modern terminals)
# And we can use the output of this assembler to obtain the code that we need.

echo "test.mips.asm assembly text dump" > test.mips.asm.txt
echo "########## DATA SECTION ##########" >> test.mips.asm.txt
mipsel-linux-gnu-objdump -s -j .data test.mips.elf >> test.mips.asm.txt
echo "########## TEXT SECTION ##########" >> test.mips.asm.txt
mipsel-linux-gnu-objdump -d test.mips.elf >> test.mips.asm.txt

# debug
# cat test.mips.asm.txt

# TODO format the output text file; feed into MIPS assembler