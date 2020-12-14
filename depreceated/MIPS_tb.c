#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define reset_vct 0xbfc00000

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

char* getreg[32] = {
	"$zero", "$at", "$v0", "$v1",
	"$a0", "$a1", "$a2", "$a3",
	"$t0", "$t1", "$t2", "$t3",
	"$t4", "$t5", "$t6", "$t7",
	"$s0", "$s1", "$s2", "$s3",
	"$s4", "$s5", "$s6", "$s7",
	"$t8", "$t9", "$k0", "$k1",
	"$gp", "$sp", "$fp", "$ra", };

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

int randreg()
{
	int x = rand() & 0x1f;

	while (x == $zero | x == $at | x == $v0 | x == $gp | x == $sp | x == $fp | x == $ra)
	{
		x = rand() & 0x1f;
	}

	return x;
}

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
		jr $zero
	*/
	int memloc, data;

	int randloc = reset_vct + 0x200 + (rand() & 0x3f) * 4;
	int temp = (rand() << 18) ^ (rand() << 10) ^ (rand());

	fprintf(fp, "` 5 testing lw\n");

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

void test_sw(FILE *fp_data, FILE *fp_instr, FILE *fp_output, FILE *fp_comments)
{
	/*
		1. CPU points to a random location using $s0
		2. CPU has a random number in $s1
		3. CPU stores the random number into the random location
		4. CPU reads the random number from the location back into $v0

		addu reg1, $zero, $zero						1
		lui reg1, ((randloc - 8) >> 16)				1
		ori reg1, reg1, (randloc - 8) & 0xffff		1
		lui reg2, (randnum >> 16)						2
		ori reg2, reg2, randnum & 0xffff				2
		sw reg2, 8(reg1)								3
		addiu reg1, reg1, 8							4
		lw $v0, 0(reg1)								4
		jr $zero
	*/
	int data;

	int randloc = reset_vct + 0x200 + (rand() & 0x3f) * 4;
	int randnum = (rand() << 18) ^ (rand() << 10) ^ (rand());

	int reg1 = randreg(), reg2 = randreg();
	while (reg1 == reg2) reg2 = randreg();


	data = rtype(addu, reg1, $zero, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addu %s, $zero, $zero\n", getreg[reg1]);

	data = itype(lui, reg1, 0, (randloc - 8) >> 16);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "lui %s, ((randloc - 8) >> 16)\n", getreg[reg1]);

	data = itype(ori, reg1, reg1, (randloc - 8) & 0xffff);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "ori %s, %s, (randloc - 8) & 0xffff\n", getreg[reg1], getreg[reg1]);

	data = itype(lui, reg2, 0, (randnum) >> 16);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "lui %s, (randnum >> 16)\n", getreg[reg2]);

	data = itype(ori, reg2, reg2, (randnum) & 0xffff);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "ori %s, %s, (randnum) & 0xffff\n", getreg[reg2], getreg[reg2]);

	data = itype(sw, reg2, reg1, 8);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "sw %s, 8(%s)\n", getreg[reg2], getreg[reg1]);

	data = itype(addiu, reg1, reg1, 8);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addiu %s, %s, 8\n", getreg[reg1], getreg[reg1]);

	data = itype(lw, $v0, reg1, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "lw $v0, 0(%s)\n", getreg[reg1]);

	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "jr $zero\n");

	fprintf(fp_output, "%08x\n", randnum);
}

void test_beq1(FILE* fp_data, FILE* fp_instr, FILE* fp_output, FILE* fp_comments)
{
	/*
		This is the case where we branch

		1. reg1 has a random number
		2. reg2 has a random number, and is equal to reg 1
		3. Use beq to set $v0 = 1 if they are equal, else set $v0 = 0 if not equal. Therefore, $v0 should be 1

		addu reg1, $zero, $zero					1
		lui reg1, (randnum1 >> 16)				1
		ori reg1, reg1, (randnum1) & 0xffff		1
		addu reg1, $zero, $zero					2
		lui reg2, (randnum2 >> 16)				2
		ori reg2, reg2, (randnum2) & 0xffff		2
		beq reg1, reg2, 2						3 branch taken
		addiu $v0, $zero, 0						3
		jr $zero								3
		addiu $v0, $zero, 1						3
		jr $zero								3
	*/


	int data;
	int randnum1 = (rand() << 18) ^ (rand() << 10) ^ (rand()), randnum2 = randnum1;

	int reg1 = randreg(), reg2 = randreg();
	while (reg1 == reg2) reg2 = randreg();

	data = rtype(addu, reg1, $zero, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addu %s, $zero, $zero\n", getreg[reg1]);

	data = itype(lui, reg1, 0, (randnum1) >> 16);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "lui %s, 0x%04x\n", getreg[reg1], ((randnum1) >> 16) & 0xffff);

	data = itype(ori, reg1, reg1, (randnum1) & 0xffff);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "ori %s, %s, 0x%04x\n", getreg[reg1], getreg[reg1], (randnum1) & 0xffff);

	data = rtype(addu, reg2, $zero, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addu %s, $zero, $zero\n", getreg[reg2]);

	data = itype(lui, reg2, 0, (randnum2) >> 16);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "lui %s, 0x%04x\n", getreg[reg2], ((randnum2) >> 16) & 0xffff);

	data = itype(ori, reg2, reg2, (randnum2) & 0xffff);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "ori %s, %s, 0x%04x\n", getreg[reg2], getreg[reg2], (randnum2) & 0xffff);

	data = itype(beq, reg1, reg2, 2);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "beq  %s, %s, 2\n", getreg[reg1], getreg[reg2]);

	data = itype(addiu, $v0, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addiu $v0, $zero, 0\n");

	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "jr $zero\n");

	data = itype(addiu, $v0, $zero, 1);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addiu $v0, $zero, 1\n");

	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "jr $zero\n");

	fprintf(fp_output, "%08x\n", 1);
}

void test_beq2(FILE* fp_data, FILE* fp_instr, FILE* fp_output, FILE* fp_comments)
{
	/*
		This is the case where we dont branch

		1. reg1 has a random number
		2. reg2 has a random number, and is NOT equal to reg 1
		3. Use beq to set $v0 = 1 if they are equal, else set $v0 = 0 if not equal. Therefore, $v0 should be 0

		addu reg1, $zero, $zero					1
		lui reg1, (randnum1 >> 16)				1
		ori reg1, reg1, (randnum1) & 0xffff		1
		addu reg1, $zero, $zero					2
		lui reg2, (randnum2 >> 16)				2
		ori reg2, reg2, (randnum2) & 0xffff		2
		beq reg1, reg2, 2						3 branch not taken
		addiu $v0, $zero, 0						3
		jr $zero								3
		addiu $v0, $zero, 1						3
		jr $zero								3




	*/


	int data;
	int randnum1 = (rand() << 18) ^ (rand() << 10) ^ (rand()), randnum2 = (rand() << 18) ^ (rand() << 10) ^ (rand());
	while (randnum1 == randnum2) randnum2 = (rand() << 18) ^ (rand() << 10) ^ (rand());

	int reg1 = randreg(), reg2 = randreg();
	while (reg1 == reg2) reg2 = randreg();

	data = rtype(addu, reg1, $zero, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addu %s, $zero, $zero\n", getreg[reg1]);

	data = itype(lui, reg1, 0, (randnum1) >> 16);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "lui %s, 0x%04x\n", getreg[reg1], ((randnum1) >> 16) & 0xffff);

	data = itype(ori, reg1, reg1, (randnum1) & 0xffff);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "ori %s, %s, 0x%04x\n", getreg[reg1], getreg[reg1], (randnum1) & 0xffff);

	data = rtype(addu, reg2, $zero, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addu %s, $zero, $zero\n", getreg[reg2]);

	data = itype(lui, reg2, 0, (randnum2) >> 16);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "lui %s, 0x%04x\n", getreg[reg2], ((randnum2) >> 16) & 0xffff);

	data = itype(ori, reg2, reg2, (randnum2) & 0xffff);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "ori %s, %s, 0x%04x\n", getreg[reg2], getreg[reg2], (randnum2) & 0xffff);

	data = itype(beq, reg1, reg2, 2);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "beq  %s, %s, 2\n", getreg[reg1], getreg[reg2]);

	data = itype(addiu, $v0, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addiu $v0, $zero, 0\n");

	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "jr $zero\n");

	data = itype(addiu, $v0, $zero, 1);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addiu $v0, $zero, 1\n");

	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "jr $zero\n");

	fprintf(fp_output, "%08x\n", 0);
}

void test_bgez1(FILE* fp_data, FILE* fp_instr, FILE* fp_output, FILE* fp_comments)
{
	/*
		This is the case where we branch

		1. reg1 has a random number which is bigger than or equal to zero
		2. Use bgez to set $v0 = 1 if branch taken, else set $v0 = 0 if not equal. Therefore, $v0 should be 1

		addu reg1, $zero, $zero					1
		lui reg1, (randnum1 >> 16)				1
		ori reg1, reg1, (randnum1) & 0xffff		1
		bgez reg1, 2							2 branch taken
		addiu $v0, $zero, 0						2
		jr $zero								2
		addiu $v0, $zero, 1						2
		jr $zero								2
	*/


	int data;
	int randnum1 = (rand() << 18) ^ (rand() << 10) ^ (rand());
	randnum1 &= 0x7fffffff;

	int reg1 = randreg();

	data = rtype(addu, reg1, $zero, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addu %s, $zero, $zero\n", getreg[reg1]);

	data = itype(lui, reg1, 0, (randnum1) >> 16);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "lui %s, (randnum1 >> 16)\n", getreg[reg1]);

	data = itype(ori, reg1, reg1, (randnum1) & 0xffff);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "ori %s, %s, (randnum1) & 0xffff\n", getreg[reg1], getreg[reg1]);

	data = itype(bgez, 0x1, reg1, 2);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "bgez %s, 2\n", getreg[reg1]);

	data = itype(addiu, $v0, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addiu $v0, $zero, 0\n");

	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "jr $zero\n");

	data = itype(addiu, $v0, $zero, 1);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addiu $v0, $zero, 1\n");

	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "jr $zero\n");

	fprintf(fp_output, "%08x\n", 1);
}

void test_bgez2(FILE* fp_data, FILE* fp_instr, FILE* fp_output, FILE* fp_comments)
{
	/*
		This is the case where we dont branch

		1. reg1 has a random number which is smaller than zero
		2. Use bgez to set $v0 = 1 if branch taken, else set $v0 = 0 if not equal. Therefore, $v0 should be 1

		addu reg1, $zero, $zero					1
		lui reg1, (randnum1 >> 16)				1
		ori reg1, reg1, (randnum1) & 0xffff		1
		bgez reg1, 2							2 branch not taken
		addiu $v0, $zero, 0						2
		jr $zero								2
		addiu $v0, $zero, 1						2
		jr $zero								2
	*/


	int data;
	int randnum1 = (rand() << 18) ^ (rand() << 10) ^ (rand());
	randnum1 |= 0x80000000;

	int reg1 = randreg();

	data = rtype(addu, reg1, $zero, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addu %s, $zero, $zero\n", getreg[reg1]);

	data = itype(lui, reg1, 0, (randnum1) >> 16);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "lui %s, (randnum1 >> 16)\n", getreg[reg1]);

	data = itype(ori, reg1, reg1, (randnum1) & 0xffff);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "ori %s, %s, (randnum1) & 0xffff\n", getreg[reg1], getreg[reg1]);

	data = itype(bgez, 0x1, reg1, 2);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "bgez %s, 2\n", getreg[reg1]);

	data = itype(addiu, $v0, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addiu $v0, $zero, 0\n");

	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "jr $zero\n");

	data = itype(addiu, $v0, $zero, 1);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addiu $v0, $zero, 1\n");

	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "jr $zero\n");

	fprintf(fp_output, "%08x\n", 0);
}

void test_bgezal1(FILE* fp_data, FILE* fp_instr, FILE* fp_output, FILE* fp_comments)
{
	/*
		This is the case where we branch

		1. reg1 has a random number which is bigger than or equal to zero
		2. Use bgez to set $v0 = 1 if branch taken, else set $v0 = 0 if not equal. Therefore, $v0 should be bfc00019

		addu reg1, $zero, $zero					1
		lui reg1, (randnum1 >> 16)				1
		ori reg1, reg1, (randnum1) & 0xffff		1
		bgezal reg1, 2							2 branch taken, $ra = $pc + 8, $pc currently is bfc00010, $ra = bfc00018
		addiu $v0, $ra, 0						2
		jr $zero								2
		addiu $v0, ra, 1						2
		jr $zero								2
	*/


	int data;
	int randnum1 = (rand() << 18) ^ (rand() << 10) ^ (rand());
	randnum1 &= 0x7fffffff;

	int reg1 = randreg();

	data = rtype(addu, reg1, $zero, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addu %s, $zero, $zero\n", getreg[reg1]);

	data = itype(lui, reg1, 0, (randnum1) >> 16);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "lui %s, (randnum1 >> 16)\n", getreg[reg1]);

	data = itype(ori, reg1, reg1, (randnum1) & 0xffff);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "ori %s, %s, (randnum1) & 0xffff\n", getreg[reg1], getreg[reg1]);

	data = itype(bgezal, 0x11, reg1, 2);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "bgezal %s, 2\n", getreg[reg1]);

	data = itype(addiu, $v0, $zero, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addiu $v0, $zero, 0\n");

	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "jr $zero\n");

	data = itype(addiu, $v0, $zero, 1);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "addiu $v0, $zero, 1\n");

	data = rtype(jr, 0, $zero, 0, 0);
	fprintf(fp_instr, "%08x\n", data);
	fprintf(fp_comments, "jr $zero\n");

	fprintf(fp_output, "%08x\n", 1);
}

int main(int argc, char** argv)
{
	srand(time(NULL));
	FILE *fp_data, *fp_instr, *fp_output, *fp_comments;
	char fname[130], fnamehead[100];
	/*
		data file format = "<instruction>_<n-th case>.data.hex", data location starts from 0x00000000
		instr file format = "<instruction>_<n-th case>.instr.hex", instruction location starts from 0xbfc00000
		output file format = "<instruction>_<n-th case>.output.txt"
		assembly comment code = "<instruction>_<n-th case>.asm.txt"
	*/

	char* instructions[46] = {
		"beq", "sw"
	};



	printf("argc = %d\n", argc);

	for (int ii = 0; ii < 2; ii++)
	{
		for (int jj = 0; jj < 5; jj++)
		{
			
			strcpy(fnamehead, "");
			sprintf(fnamehead, "%s_%d", instructions[ii], jj);

			strcpy(fname, "");
			sprintf(fname, "%s.data.hex", fnamehead);
			fp_data = fopen(fname, "w");

			strcpy(fname, "");
			sprintf(fname, "%s.instr.hex", fnamehead);
			fp_instr = fopen(fname, "w");

			strcpy(fname, "");
			sprintf(fname, "%s.output.txt", fnamehead);
			fp_output = fopen(fname, "w");

			strcpy(fname, "");
			sprintf(fname, "%s.asm.txt", fnamehead);
			fp_comments = fopen(fname, "w");

			test_beq1(fp_data, fp_instr, fp_output, fp_comments);
		}
		
	}


	fclose(fp_data);
	fclose(fp_instr);
	fclose(fp_output);
	fclose(fp_comments);

	//char* ptr;

	//if (argc > 1)
	//{
	//	while (--argc)
	//	{
	//		ptr = *++argv;

	//		if (strcmp(ptr, "jr") == 0)
	//			for (int i = 0; i < 10; i++) test_jr(fp);
	//		else if (strcmp(ptr, "addiu") == 0)
	//			for (int i = 0; i < 10; i++) test_addiu(fp);
	//		else if (strcmp(ptr, "lw") == 0)
	//			for (int i = 0; i < 10; i++) test_lw(fp);

	//	}
	//}
	//else
	//{
	//	for (int i = 0; i < 10; i++) test_jr(fp);
	//	for (int i = 0; i < 10; i++) test_addiu(fp);
	//	for (int i = 0; i < 10; i++) test_lw(fp);

	//}

	//fclose(fp);

	return 0;
}