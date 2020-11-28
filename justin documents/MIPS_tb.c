#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <stdlib.h>

// register constants
#define $zero 0
#define $at 1
#define $v0 2
#define $v1 3
#define $a0 4
#define $a1 5
#define $a2 6
#define $a3 7
#define $t0 8
#define $t1 9
#define $t2 10
#define $t3 11
#define $t4 12
#define $t5 13
#define $t6 14
#define $t7 15
#define $s0 16
#define $s1 17
#define $s2 18
#define $s3 19
#define $s4 20
#define $s5 21
#define $s6 22
#define $s7 23
#define $t8 24
#define $t9 25
#define $k0 26
#define $k1 27
#define $gp 28
#define $sp 29
#define $fp 30
#define $ra 31

// r type
#define addu 0x21
#define and 0x24
#define div 0x1A
#define divu 0x1B
#define jalr 0x9
#define jr 0x8
#define mthi 0x11
#define mtlo 0x13
#define mult 0x18
#define multu 0x19
#define or 0x25
#define sll 0x00
#define sllv 0x04
#define slt 0x2A
#define sltu 0x2B
#define sra 0x03
#define srav 0x07
#define srl 0x02
#define srlv 0c06
#define subu 0x23
#define xor 0x26

// i type
#define addiu 0x09
#define andi 0x0c
#define beq 0x04
#define bgez 0x01
#define bgezal 0x01
#define bgtz 0x07
#define blez 0x06
#define bltz 0x01
#define bltzal 0x01
#define bne 0x05
#define lb 0x20
#define lbu 0x24
#define lh 0x21
#define lhu 0x25
#define lui 0x0f
#define lw 0x23
#define lwl 0x22
#define lwr 0x26
#define ori 0x0d
#define sb 0x28
#define sh 0x29
#define slti 0xa
#define sltiu 0x0b
#define sw 0x2b
#define xori 0x0e


// j type
#define j 0x02
#define jal 0x03


unsigned int rtype(int rs, int rt, int rd, int shift, int fncode)
{
	unsigned int x = 0;

	shift = (shift & 0x3f) << 6;
	rd = (rd & 0x1f) << 11;
	rt = (rt & 0x1f) << 16;
	rs = (rs & 0x1f) << 21;

	x |= rs;
	x |= rt;
	x |= rd;
	x |= shift;
	x |= fncode;

	return x;
}

unsigned int itype(int opcode, int rs, int rd, int imm)
{
	unsigned int x = 0;



	return x;
}

unsigned int jtype(int opcode, int imm)
{
	unsigned int x = 0;



	return x;
}


void addi (FILE *fp)
{
	/*
		addi $v0, $zero, rand() 
	*/
}



int main(int argc, char** argv)
{
	srand(time(NULL));
	FILE* fp = fopen("test_prog_list.txt", "w");
	printf("argc = %d\n", argc);

	if (argc > 1)
	{
		while (--argc)
		{
			puts(*++argv);
		}
	}
	else
	{
		
	}

	printf("yada = %d\n", $v0);

	

	return 0;
}