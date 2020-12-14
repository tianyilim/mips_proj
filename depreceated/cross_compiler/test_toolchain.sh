#!/bin/bash

# Setting flag for printing
VERBOSE=1
if [ $# = 0 ] || [ $1 != '-v']; then
    VERBOSE=0
fi

for FILENAME in *.c; do
    [ -e "$FILENAME" ] || continue # Avoid case where there are no matches
    
    FULLNAME=`basename "$FILENAME"`
    NAME="${FULLNAME%.*}"
    echo "Compiling for test case ${NAME}"

    # Compile
    mipsel-linux-gnu-gcc -g -O3 -nostdlib -march="mips1" -mfp32 -Wl,--build-id=none -T linker_file.ld ${NAME}.c -o ${NAME}.mips.elf
    # Generate hex file using objcopy and then formatted hexdump
    mipsel-linux-gnu-objcopy -O binary --only-section=.text ${NAME}.mips.elf ${NAME}.mips.asm.bin
    hexdump -v -e '4/1 "%02x " "\n"' ${NAME}.mips.asm.bin > ${NAME}.mips.asm.hex
    mipsel-linux-gnu-objcopy -O binary --only-section=.data ${NAME}.mips.elf ${NAME}.mips.data.bin
    hexdump -v -e '4/1 "%02x " "\n"' ${NAME}.mips.data.bin > ${NAME}.mips.data.hex

    # Print debug conditional
    if [ $VERBOSE != 0 ]; then
        mipsel-linux-gnu-objdump -d ${NAME}.mips.elf
    fi

    # TODO add test cases to go here.

done;

