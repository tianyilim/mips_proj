	.section .mdebug.abi32
	.previous
	.nan	legacy
	.module	fp=32
	.module	nooddspreg
	.abicalls
	.text
$Ltext0:
	.cfi_sections	.debug_frame
	.align	2
	.globl	f
$LVL0 = .
$LFB0 = .
	.file 1 "test.c"
	.loc 1 4 13 view -0
	.cfi_startproc
	.set	nomips16
	.set	nomicromips
	.ent	f
	.type	f, @function
f:
	.frame	$sp,0,$31		# vars= 0, regs= 0/0, args= 0, gp= 0
	.mask	0x00000000,0
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	.loc 1 5 5 view $LVU1
	.loc 1 5 22 is_stmt 0 view $LVU2
	lui	$2,%hi(twentyFour)
	lw	$3,%lo(twentyFour)($2)
	lui	$2,%hi(pi)
	lw	$2,%lo(pi)($2)
	nop
	addu	$2,$3,$2
	.loc 1 6 1 view $LVU3
	jr	$31
	addu	$2,$2,$4

	.set	macro
	.set	reorder
	.end	f
	.cfi_endproc
$LFE0:
	.size	f, .-f
	.globl	pi
	.data
	.align	2
	.type	pi, @object
	.size	pi, 4
pi:
	.word	314121
	.globl	twentyFour
	.align	2
	.type	twentyFour, @object
	.size	twentyFour, 4
twentyFour:
	.word	24
	.text
$Letext0:
	.section	.debug_info,"",@progbits
$Ldebug_info0:
	.4byte	0x6d
	.2byte	0x4
	.4byte	$Ldebug_abbrev0
	.byte	0x4
	.uleb128 0x1
	.4byte	$LASF1
	.byte	0xc
	.4byte	$LASF2
	.4byte	$LASF3
	.4byte	$Ltext0
	.4byte	$Letext0-$Ltext0
	.4byte	$Ldebug_line0
	.uleb128 0x2
	.4byte	$LASF0
	.byte	0x1
	.byte	0x1
	.byte	0x5
	.4byte	0x37
	.uleb128 0x5
	.byte	0x3
	.4byte	twentyFour
	.uleb128 0x3
	.byte	0x4
	.byte	0x5
	.ascii	"int\000"
	.uleb128 0x4
	.ascii	"pi\000"
	.byte	0x1
	.byte	0x2
	.byte	0x5
	.4byte	0x37
	.uleb128 0x5
	.byte	0x3
	.4byte	pi
	.uleb128 0x5
	.ascii	"f\000"
	.byte	0x1
	.byte	0x4
	.byte	0x5
	.4byte	0x37
	.4byte	$LFB0
	.4byte	$LFE0-$LFB0
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x6
	.ascii	"n\000"
	.byte	0x1
	.byte	0x4
	.byte	0xb
	.4byte	0x37
	.uleb128 0x1
	.byte	0x54
	.byte	0
	.byte	0
	.section	.debug_abbrev,"",@progbits
$Ldebug_abbrev0:
	.uleb128 0x1
	.uleb128 0x11
	.byte	0x1
	.uleb128 0x25
	.uleb128 0xe
	.uleb128 0x13
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x1b
	.uleb128 0xe
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x10
	.uleb128 0x17
	.byte	0
	.byte	0
	.uleb128 0x2
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x3
	.uleb128 0x24
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0x8
	.byte	0
	.byte	0
	.uleb128 0x4
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x5
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x2117
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0x6
	.uleb128 0x5
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.byte	0
	.section	.debug_aranges,"",@progbits
	.4byte	0x1c
	.2byte	0x2
	.4byte	$Ldebug_info0
	.byte	0x4
	.byte	0
	.2byte	0
	.2byte	0
	.4byte	$Ltext0
	.4byte	$Letext0-$Ltext0
	.4byte	0
	.4byte	0
	.section	.debug_line,"",@progbits
$Ldebug_line0:
	.section	.debug_str,"MS",@progbits,1
$LASF3:
	.ascii	"/mnt/c/Users/0tian/OneDrive - Imperial College London/Ye"
	.ascii	"ar Two/Instruction Arch and Compilers/mips1_project/mips"
	.ascii	"_proj/cross_compiler\000"
$LASF2:
	.ascii	"test.c\000"
$LASF1:
	.ascii	"GNU C17 9.3.0 -mel -march=mips1 -mfp32 -mllsc -mno-lxc1-"
	.ascii	"sxc1 -mno-madd4 -mips1 -mno-shared -mabi=32 -g -O3\000"
$LASF0:
	.ascii	"twentyFour\000"
	.ident	"GCC: (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0"
