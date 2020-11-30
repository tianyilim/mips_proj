#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define reset_vct 0xbcf00000

// registers
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

/*
example:
FOR addu $s1, $s2, $s3 CALL AS rtype(addu, $s1, $s2, $s3, 0)
FOR sll $s1, $s2, 5 CALL AS rtype(sll, $s1, 0, $s2, 5)
FOR jr $s0 CALL AS rtype(jr, 0 $s0, 0, 0, 0)
*/
int rtype(int fncode, int rd, int rs, int rt,  int shift)
{
	int x = 0;

	fncode = (fncode & 0x3f);
	shift = (shift & 0x1f) << 6;
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


/*
example:
FOR addiu $s1, $s2, 46 CALL AS itype(addiu, $s1, $s2, 46)
FOR beq $s1, $s2, 5 CALL AS itype(beq, $s1, $s2, 5)
FOR lw $s1, 100($s2) CALL AS itype(lw, $s1, $s2, 100)
FOR sw $s1, 100($s2) CALL AS itype(sw, $s1, $s2, 100)
*/
int itype(int opcode, int rt, int rs, int imm)
{
	int x = 0;

	imm = (imm & 0xffff);
	rt = (rt & 0x1f) << 16;
	rs = (rs & 0x1f) << 21;
	opcode = (opcode & 0x3f) << 26;

	x |= imm;
	x |= rt;
	x |= rs;
	x |= opcode;

	return x;
}

int jtype(int opcode, int imm)
{
	int x = 0;

	imm = (imm & 0x03ffffff);
	opcode = (opcode & 0x3f) << 26;

	x |= imm;
	x |= opcode;

	return x;
}

void test_jr(FILE* fp)
{
	/*
		addiu $v0, $zero, 0
		jr $zero
	*/
	int memloc, data;

	fprintf(fp, "` 2 testing jr\n");

	memloc = reset_vct;
	data = itype(addiu, $v0, $zero, 0);
	fprintf(fp, "# %08x %08x ; addiu $v0, $zero, 0\n", memloc, data);

	memloc += 4;
	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp, "# %08x %08x ; jr $zero\n", memloc, data);

	fprintf(fp, "@ %08x\n", 0);
}

void test_addiu(FILE *fp)
{
	/*
		addiu $v0, $zero, rand()
		jr $zero
	*/
	int memloc, data;

	int temp = rand() & 0xffff;

	fprintf(fp, "` 2 testing addiu\n");

	memloc = reset_vct;
	data = itype(addiu, $v0, $zero, temp);
	fprintf(fp, "# %08x %08x ; addiu $v0, $zero, rand()\n", memloc, data);

	memloc += 4;
	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp, "# %08x %08x ; jr $zero\n", memloc, data);

	fprintf(fp, "@ %08x\n", temp);
}

void test_lw(FILE* fp)
{
	/*
		addu $s0, $zero, $zero
		lui $s0, ((randloc - 8) >> 16)
		addiu $s0, $s0, (randloc - 8) & 0xffff
		lw $v0, 8($s0)
	*/
	int memloc, data;

	int randloc = reset_vct + 0x200 + (rand() & 0x3f) * 4;
	int temp = (rand() << 18) ^ (rand() << 10) ^ (rand());

	fprintf(fp, "` 4 testing lw\n");

	memloc = randloc;
	data = temp;
	fprintf(fp, "# %08x %08x ; load data into data memory\n", memloc, data);


	memloc = reset_vct;
	data = rtype(addu, $s0, $zero, $zero, 0);
	fprintf(fp, "# %08x %08x ; addu $s0, $zero, $zero\n", memloc, data);
	
	memloc += 4;
	data = itype(lui, $s0, 0, (randloc - 8) >> 16);
	fprintf(fp, "# %08x %08x ; lui $s0, ((randloc - 8) >> 16)\n", memloc, data);

	memloc += 4;
	data = itype(addiu, $s0, $s0, (randloc - 8) & 0xffff);
	fprintf(fp, "# %08x %08x ; addiu $s0, $s0, (randloc - 8) & 0xffff\n", memloc, data);

	memloc += 4;
	data = itype(lw, $v0, $s0, 8);
	fprintf(fp, "# %08x %08x ; lw $v0, 8($s0)\n", memloc, data);

	memloc += 4;
	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp, "# %08x %08x ; jr $zero\n", memloc, data);


	fprintf(fp,"@ %08x\n", temp);
}


int main(int argc, char** argv)
{
	srand(time(NULL));
	FILE* fp = fopen("test_prog_list.txt", "w");
	printf("argc = %d\n", argc);

	char* ptr;

	if (argc > 1)
	{
		while (--argc)
		{
			ptr = *++argv;

			if (strcmp(ptr, "jr") == 0)
				for (int i = 0; i < 10; i++) test_jr(fp);
			else if (strcmp(ptr, "addiu") == 0)
				for (int i = 0; i < 10; i++) test_addiu(fp);
			else if (strcmp(ptr, "lw") == 0)
				for (int i = 0; i < 10; i++) test_lw(fp);

		}
	}
	else
	{
		for (int i = 0; i < 10; i++) test_jr(fp);
		for (int i = 0; i < 10; i++) test_addiu(fp);
		for (int i = 0; i < 10; i++) test_lw(fp);

	}

	fclose(fp);

	return 0;
}