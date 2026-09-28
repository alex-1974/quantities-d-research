	.text
	.file	"codegen.d"
	.section	.text.rawAddFD,"ax",@progbits
	.globl	rawAddFD
	.p2align	4, 0x90
	.type	rawAddFD,@function
rawAddFD:
	.cfi_startproc
	cvtss2sd	%xmm0, %xmm0
	addsd	%xmm1, %xmm0
	retq
.Lfunc_end0:
	.size	rawAddFD, .Lfunc_end0-rawAddFD
	.cfi_endproc

	.section	.text.quantityAddFD,"ax",@progbits
	.globl	quantityAddFD
	.p2align	4, 0x90
	.type	quantityAddFD,@function
quantityAddFD:
	.cfi_startproc
	cvtss2sd	%xmm0, %xmm0
	addsd	%xmm1, %xmm0
	retq
.Lfunc_end1:
	.size	quantityAddFD, .Lfunc_end1-quantityAddFD
	.cfi_endproc

	.section	.text._D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2bTdZQvMxFNaNbNiNfSQCp__TQCkTQClTdZQCuZQv,"axG",@progbits,_D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2bTdZQvMxFNaNbNiNfSQCp__TQCkTQClTdZQCuZQv,comdat
	.weak	_D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2bTdZQvMxFNaNbNiNfSQCp__TQCkTQClTdZQCuZQv
	.p2align	4, 0x90
	.type	_D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2bTdZQvMxFNaNbNiNfSQCp__TQCkTQClTdZQCuZQv,@function
_D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2bTdZQvMxFNaNbNiNfSQCp__TQCkTQClTdZQCuZQv:
	.cfi_startproc
	movss	(%rdi), %xmm1
	cvtss2sd	%xmm1, %xmm1
	addsd	%xmm1, %xmm0
	retq
.Lfunc_end2:
	.size	_D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2bTdZQvMxFNaNbNiNfSQCp__TQCkTQClTdZQCuZQv, .Lfunc_end2-_D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2bTdZQvMxFNaNbNiNfSQCp__TQCkTQClTdZQCuZQv
	.cfi_endproc

	.section	.text.rawScaleFD,"ax",@progbits
	.globl	rawScaleFD
	.p2align	4, 0x90
	.type	rawScaleFD,@function
rawScaleFD:
	.cfi_startproc
	cvtss2sd	%xmm0, %xmm0
	mulsd	%xmm1, %xmm0
	retq
.Lfunc_end3:
	.size	rawScaleFD, .Lfunc_end3-rawScaleFD
	.cfi_endproc

	.section	.text.quantityScaleFD,"ax",@progbits
	.globl	quantityScaleFD
	.p2align	4, 0x90
	.type	quantityScaleFD,@function
quantityScaleFD:
	.cfi_startproc
	cvtss2sd	%xmm0, %xmm0
	mulsd	%xmm1, %xmm0
	retq
.Lfunc_end4:
	.size	quantityScaleFD, .Lfunc_end4-quantityScaleFD
	.cfi_endproc

	.section	.text._D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2aTdZQvMxFNaNbNiNfdZSQCr__TQCmTQCnTdZQCw,"axG",@progbits,_D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2aTdZQvMxFNaNbNiNfdZSQCr__TQCmTQCnTdZQCw,comdat
	.weak	_D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2aTdZQvMxFNaNbNiNfdZSQCr__TQCmTQCnTdZQCw
	.p2align	4, 0x90
	.type	_D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2aTdZQvMxFNaNbNiNfdZSQCr__TQCmTQCnTdZQCw,@function
_D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2aTdZQvMxFNaNbNiNfdZSQCr__TQCmTQCnTdZQCw:
	.cfi_startproc
	movss	(%rdi), %xmm1
	cvtss2sd	%xmm1, %xmm1
	mulsd	%xmm1, %xmm0
	retq
.Lfunc_end5:
	.size	_D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2aTdZQvMxFNaNbNiNfdZSQCr__TQCmTQCnTdZQCw, .Lfunc_end5-_D7codegen__T1QTSQp6LengthTfZQq__T8opBinaryVAyaa1_2aTdZQvMxFNaNbNiNfdZSQCr__TQCmTQCnTdZQCw
	.cfi_endproc

	.section	.text.rawDivDF,"ax",@progbits
	.globl	rawDivDF
	.p2align	4, 0x90
	.type	rawDivDF,@function
rawDivDF:
	.cfi_startproc
	cvtss2sd	%xmm1, %xmm1
	divsd	%xmm1, %xmm0
	retq
.Lfunc_end6:
	.size	rawDivDF, .Lfunc_end6-rawDivDF
	.cfi_endproc

	.section	.text.quantityDivDF,"ax",@progbits
	.globl	quantityDivDF
	.p2align	4, 0x90
	.type	quantityDivDF,@function
quantityDivDF:
	.cfi_startproc
	cvtss2sd	%xmm1, %xmm1
	divsd	%xmm1, %xmm0
	retq
.Lfunc_end7:
	.size	quantityDivDF, .Lfunc_end7-quantityDivDF
	.cfi_endproc

	.section	.text._D7codegen__T1QTSQp6LengthTdZQq__T8opBinaryVAyaa1_2fTfZQvMxFNaNbNiNffZSQCr__TQCmTQCnTdZQCw,"axG",@progbits,_D7codegen__T1QTSQp6LengthTdZQq__T8opBinaryVAyaa1_2fTfZQvMxFNaNbNiNffZSQCr__TQCmTQCnTdZQCw,comdat
	.weak	_D7codegen__T1QTSQp6LengthTdZQq__T8opBinaryVAyaa1_2fTfZQvMxFNaNbNiNffZSQCr__TQCmTQCnTdZQCw
	.p2align	4, 0x90
	.type	_D7codegen__T1QTSQp6LengthTdZQq__T8opBinaryVAyaa1_2fTfZQvMxFNaNbNiNffZSQCr__TQCmTQCnTdZQCw,@function
_D7codegen__T1QTSQp6LengthTdZQq__T8opBinaryVAyaa1_2fTfZQvMxFNaNbNiNffZSQCr__TQCmTQCnTdZQCw:
	.cfi_startproc
	movsd	(%rdi), %xmm1
	cvtss2sd	%xmm0, %xmm0
	divsd	%xmm0, %xmm1
	movapd	%xmm1, %xmm0
	retq
.Lfunc_end8:
	.size	_D7codegen__T1QTSQp6LengthTdZQq__T8opBinaryVAyaa1_2fTfZQvMxFNaNbNiNffZSQCr__TQCmTQCnTdZQCw, .Lfunc_end8-_D7codegen__T1QTSQp6LengthTdZQq__T8opBinaryVAyaa1_2fTfZQvMxFNaNbNiNffZSQCr__TQCmTQCnTdZQCw
	.cfi_endproc

	.section	.text._D7codegen__T1QTSQp6LengthTfZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTfZQCbZb,"axG",@progbits,_D7codegen__T1QTSQp6LengthTfZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTfZQCbZb,comdat
	.weak	_D7codegen__T1QTSQp6LengthTfZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTfZQCbZb
	.p2align	4, 0x90
	.type	_D7codegen__T1QTSQp6LengthTfZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTfZQCbZb,@function
_D7codegen__T1QTSQp6LengthTfZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTfZQCbZb:
	.cfi_startproc
	movss	(%rsi), %xmm0
	cmpeqss	(%rdi), %xmm0
	movd	%xmm0, %eax
	andl	$1, %eax
	retq
.Lfunc_end9:
	.size	_D7codegen__T1QTSQp6LengthTfZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTfZQCbZb, .Lfunc_end9-_D7codegen__T1QTSQp6LengthTfZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTfZQCbZb
	.cfi_endproc

	.section	.text._D7codegen__T1QTSQp6LengthTfZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTfZQCaZm,"axG",@progbits,_D7codegen__T1QTSQp6LengthTfZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTfZQCaZm,comdat
	.weak	_D7codegen__T1QTSQp6LengthTfZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTfZQCaZm
	.p2align	4, 0x90
	.type	_D7codegen__T1QTSQp6LengthTfZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTfZQCaZm,@function
_D7codegen__T1QTSQp6LengthTfZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTfZQCaZm:
	.cfi_startproc
	movq	%rdi, %rsi
	movq	_D11TypeInfo_xf6__initZ@GOTPCREL(%rip), %rdi
	movq	(%rdi), %rax
	movq	48(%rax), %rax
	jmpq	*%rax
.Lfunc_end10:
	.size	_D7codegen__T1QTSQp6LengthTfZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTfZQCaZm, .Lfunc_end10-_D7codegen__T1QTSQp6LengthTfZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTfZQCaZm
	.cfi_endproc

	.section	.text._D7codegen__T1QTSQp6LengthTdZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTdZQCbZb,"axG",@progbits,_D7codegen__T1QTSQp6LengthTdZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTdZQCbZb,comdat
	.weak	_D7codegen__T1QTSQp6LengthTdZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTdZQCbZb
	.p2align	4, 0x90
	.type	_D7codegen__T1QTSQp6LengthTdZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTdZQCbZb,@function
_D7codegen__T1QTSQp6LengthTdZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTdZQCbZb:
	.cfi_startproc
	movsd	(%rsi), %xmm0
	cmpeqsd	(%rdi), %xmm0
	movq	%xmm0, %rax
	andl	$1, %eax
	retq
.Lfunc_end11:
	.size	_D7codegen__T1QTSQp6LengthTdZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTdZQCbZb, .Lfunc_end11-_D7codegen__T1QTSQp6LengthTdZQq11__xopEqualsMxFKxSQBw__TQBrTQBsTdZQCbZb
	.cfi_endproc

	.section	.text._D7codegen__T1QTSQp6LengthTdZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTdZQCaZm,"axG",@progbits,_D7codegen__T1QTSQp6LengthTdZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTdZQCaZm,comdat
	.weak	_D7codegen__T1QTSQp6LengthTdZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTdZQCaZm
	.p2align	4, 0x90
	.type	_D7codegen__T1QTSQp6LengthTdZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTdZQCaZm,@function
_D7codegen__T1QTSQp6LengthTdZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTdZQCaZm:
	.cfi_startproc
	movq	%rdi, %rsi
	movq	_D11TypeInfo_xd6__initZ@GOTPCREL(%rip), %rdi
	movq	(%rdi), %rax
	movq	48(%rax), %rax
	jmpq	*%rax
.Lfunc_end12:
	.size	_D7codegen__T1QTSQp6LengthTdZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTdZQCaZm, .Lfunc_end12-_D7codegen__T1QTSQp6LengthTdZQq9__xtoHashFNbNeKxSQBv__TQBqTQBrTdZQCaZm
	.cfi_endproc

	.type	_D7codegen__T1QTSQp6LengthTfZQq6__initZ,@object
	.section	.rodata._D7codegen__T1QTSQp6LengthTfZQq6__initZ,"aG",@progbits,_D7codegen__T1QTSQp6LengthTfZQq6__initZ,comdat
	.weak	_D7codegen__T1QTSQp6LengthTfZQq6__initZ
	.p2align	2, 0x0
_D7codegen__T1QTSQp6LengthTfZQq6__initZ:
	.long	0x7fc00000
	.size	_D7codegen__T1QTSQp6LengthTfZQq6__initZ, 4

	.type	_D11TypeInfo_xf6__initZ,@object
	.section	.data._D11TypeInfo_xf6__initZ,"aw",@progbits
	.weak	_D11TypeInfo_xf6__initZ
	.p2align	4, 0x0
_D11TypeInfo_xf6__initZ:
	.quad	_D14TypeInfo_Const6__vtblZ
	.quad	0
	.quad	_D10TypeInfo_f6__initZ
	.size	_D11TypeInfo_xf6__initZ, 24

	.type	_D7codegen__T1QTSQp6LengthTdZQq6__initZ,@object
	.section	.rodata._D7codegen__T1QTSQp6LengthTdZQq6__initZ,"aG",@progbits,_D7codegen__T1QTSQp6LengthTdZQq6__initZ,comdat
	.weak	_D7codegen__T1QTSQp6LengthTdZQq6__initZ
	.p2align	3, 0x0
_D7codegen__T1QTSQp6LengthTdZQq6__initZ:
	.quad	0x7ff8000000000000
	.size	_D7codegen__T1QTSQp6LengthTdZQq6__initZ, 8

	.type	_D11TypeInfo_xd6__initZ,@object
	.section	.data._D11TypeInfo_xd6__initZ,"aw",@progbits
	.weak	_D11TypeInfo_xd6__initZ
	.p2align	4, 0x0
_D11TypeInfo_xd6__initZ:
	.quad	_D14TypeInfo_Const6__vtblZ
	.quad	0
	.quad	_D10TypeInfo_d6__initZ
	.size	_D11TypeInfo_xd6__initZ, 24

	.type	_D7codegen12__ModuleInfoZ,@object
	.section	.data._D7codegen12__ModuleInfoZ,"aw",@progbits
	.globl	_D7codegen12__ModuleInfoZ
	.p2align	3, 0x0
_D7codegen12__ModuleInfoZ:
	.long	2147483652
	.long	0
	.asciz	"codegen"
	.size	_D7codegen12__ModuleInfoZ, 16

	.hidden	_D7codegen11__moduleRefZ
	.type	_D7codegen11__moduleRefZ,@object
	.section	__minfo,"awR",@progbits,unique,1
	.weak	_D7codegen11__moduleRefZ
	.p2align	3, 0x0
_D7codegen11__moduleRefZ:
	.quad	_D7codegen12__ModuleInfoZ
	.size	_D7codegen11__moduleRefZ, 8

	.ident	"ldc version 1.41.0"
	.section	".note.GNU-stack","",@progbits
