	.file	1 "binarysearch.cpp"
	.section .mdebug.abi32
	.previous
	.nan	legacy
	.module	fp=xx
	.module	nooddspreg
	.abicalls
	.text
	.align	2
	.globl	_Z12binarySearchPiiii
$LFB8313 = .
	.cfi_startproc
	.set	nomips16
	.set	nomicromips
	.ent	_Z12binarySearchPiiii
	.type	_Z12binarySearchPiiii, @function
_Z12binarySearchPiiii:
	.frame	$sp,0,$31		# vars= 0, regs= 0/0, args= 0, gp= 0
	.mask	0x00000000,0
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	slt	$2,$6,$5
	bne	$2,$0,$L7
	nop

	subu	$2,$6,$5
	.option	pic0
	b	$L8
	.option	pic2
	sra	$2,$2,1

$L10:
	addiu	$6,$2,-1
	subu	$2,$6,$5
	slt	$3,$6,$5
	bne	$3,$0,$L7
	sra	$2,$2,1

$L8:
	addu	$2,$2,$5
	sll	$3,$2,2
	addu	$3,$4,$3
	lw	$3,0($3)
	beq	$3,$7,$L11
	slt	$3,$7,$3

	bne	$3,$0,$L10
	nop

	addiu	$5,$2,1
	subu	$2,$6,$5
	slt	$3,$6,$5
	beq	$3,$0,$L8
	sra	$2,$2,1

$L7:
	li	$2,-1			# 0xffffffffffffffff
$L11:
	jr	$31
	nop

	.set	macro
	.set	reorder
	.end	_Z12binarySearchPiiii
	.cfi_endproc
$LFE8313:
	.size	_Z12binarySearchPiiii, .-_Z12binarySearchPiiii
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
$LC0:
	.ascii	"Element is not present in array\000"
	.align	2
$LC1:
	.ascii	"Element is present at index \000"
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
$LFB8314 = .
	.cfi_startproc
	.set	nomips16
	.set	nomicromips
	.ent	main
	.type	main, @function
main:
	.frame	$sp,64,$31		# vars= 24, regs= 3/0, args= 16, gp= 8
	.mask	0x80030000,-4
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	addiu	$sp,$sp,-64
	.cfi_def_cfa_offset 64
	li	$2,2			# 0x2
	lui	$28,%hi(__gnu_local_gp)
	sw	$2,24($sp)
	li	$2,3			# 0x3
	addiu	$28,$28,%lo(__gnu_local_gp)
	sw	$17,56($sp)
	sw	$2,28($sp)
	li	$2,4			# 0x4
	move	$3,$0
	sw	$31,60($sp)
	sw	$2,32($sp)
	li	$2,10			# 0xa
	.cfi_offset 17, -8
	.cfi_offset 31, -4
	lw	$17,%got(__stack_chk_guard)($28)
	li	$4,4			# 0x4
	sw	$2,36($sp)
	li	$2,40			# 0x28
	li	$5,10			# 0xa
	sw	$16,52($sp)
	.cfi_offset 16, -12
	sw	$2,40($sp)
	.cprestore	16
	lw	$2,0($17)
	sw	$2,44($sp)
	subu	$16,$4,$3
$L25:
	addiu	$6,$sp,48
	sra	$16,$16,1
	addu	$16,$16,$3
	sll	$2,$16,2
	addu	$2,$6,$2
	lw	$2,-24($2)
	beq	$2,$5,$L14
	slt	$2,$2,11

$L26:
	bne	$2,$0,$L15
	nop

	addiu	$4,$16,-1
	slt	$2,$4,$3
	beq	$2,$0,$L25
	subu	$16,$4,$3

$L17:
	lui	$5,%hi($LC0)
	lw	$25,%call16(_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc)($28)
	lw	$4,%got(_ZSt4cout)($28)
	.reloc	1f,R_MIPS_JALR,_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
1:	jalr	$25
	addiu	$5,$5,%lo($LC0)

	lw	$28,16($sp)
$L18:
	lw	$4,44($sp)
	move	$2,$0
	lw	$3,0($17)
	bne	$4,$3,$L23
	lw	$31,60($sp)

	lw	$17,56($sp)
	lw	$16,52($sp)
	jr	$31
	addiu	$sp,$sp,64

	.cfi_remember_state
	.cfi_def_cfa_offset 0
	.cfi_restore 16
	.cfi_restore 17
	.cfi_restore 31
$L15:
	.cfi_restore_state
	addiu	$3,$16,1
	slt	$2,$4,$3
	bne	$2,$0,$L17
	subu	$16,$4,$3

	addiu	$6,$sp,48
	sra	$16,$16,1
	addu	$16,$16,$3
	sll	$2,$16,2
	addu	$2,$6,$2
	lw	$2,-24($2)
	bne	$2,$5,$L26
	slt	$2,$2,11

$L14:
	lui	$5,%hi($LC1)
	lw	$25,%call16(_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_i)($28)
	lw	$4,%got(_ZSt4cout)($28)
	li	$6,28			# 0x1c
	.reloc	1f,R_MIPS_JALR,_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_i
1:	jalr	$25
	addiu	$5,$5,%lo($LC1)

	lw	$28,16($sp)
	lw	$25,%call16(_ZNSolsEi)($28)
	lw	$4,%got(_ZSt4cout)($28)
	.reloc	1f,R_MIPS_JALR,_ZNSolsEi
1:	jalr	$25
	move	$5,$16

	.option	pic0
	b	$L18
	.option	pic2
	lw	$28,16($sp)

$L23:
	lw	$25,%call16(__stack_chk_fail)($28)
	.reloc	1f,R_MIPS_JALR,__stack_chk_fail
1:	jalr	$25
	nop

	.set	macro
	.set	reorder
	.end	main
	.cfi_endproc
$LFE8314:
	.size	main, .-main
	.align	2
$LFB9561 = .
	.cfi_startproc
	.set	nomips16
	.set	nomicromips
	.ent	_GLOBAL__sub_I__Z12binarySearchPiiii
	.type	_GLOBAL__sub_I__Z12binarySearchPiiii, @function
_GLOBAL__sub_I__Z12binarySearchPiiii:
	.frame	$sp,32,$31		# vars= 0, regs= 2/0, args= 16, gp= 8
	.mask	0x80010000,-4
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	lui	$28,%hi(__gnu_local_gp)
	addiu	$sp,$sp,-32
	.cfi_def_cfa_offset 32
	addiu	$28,$28,%lo(__gnu_local_gp)
	sw	$16,24($sp)
	.cfi_offset 16, -8
	lui	$16,%hi(_ZStL8__ioinit)
	sw	$31,28($sp)
	.cfi_offset 31, -4
	.cprestore	16
	lw	$25,%call16(_ZNSt8ios_base4InitC1Ev)($28)
	.reloc	1f,R_MIPS_JALR,_ZNSt8ios_base4InitC1Ev
1:	jalr	$25
	addiu	$4,$16,%lo(_ZStL8__ioinit)

	lui	$6,%hi(__dso_handle)
	lw	$28,16($sp)
	addiu	$5,$16,%lo(_ZStL8__ioinit)
	lw	$31,28($sp)
	addiu	$6,$6,%lo(__dso_handle)
	lw	$16,24($sp)
	addiu	$sp,$sp,32
	.cfi_restore 16
	.cfi_restore 31
	.cfi_def_cfa_offset 0
	lw	$25,%call16(__cxa_atexit)($28)
	.reloc	1f,R_MIPS_JALR,__cxa_atexit
1:	jr	$25
	lw	$4,%got(_ZNSt8ios_base4InitD1Ev)($28)

	.set	macro
	.set	reorder
	.end	_GLOBAL__sub_I__Z12binarySearchPiiii
	.cfi_endproc
$LFE9561:
	.size	_GLOBAL__sub_I__Z12binarySearchPiiii, .-_GLOBAL__sub_I__Z12binarySearchPiiii
	.section	.ctors,"aw",@progbits
	.align	2
	.word	_GLOBAL__sub_I__Z12binarySearchPiiii
	.local	_ZStL8__ioinit
	.comm	_ZStL8__ioinit,1,4
	.hidden	__dso_handle
	.ident	"GCC: (Ubuntu 7.5.0-3ubuntu1~18.04) 7.5.0"
