	.text
	.file	"codegen.d"
	.section	.text.rawAddIU,"ax",@progbits
	.globl	rawAddIU
	.p2align	4, 0x90
	.type	rawAddIU,@function
rawAddIU:
	.cfi_startproc
	movslq	%edi, %rcx
	movl	%esi, %eax
	addq	%rcx, %rax
	retq
.Lfunc_end0:
	.size	rawAddIU, .Lfunc_end0-rawAddIU
	.cfi_endproc

	.section	.text.quantityAddIU,"ax",@progbits
	.globl	quantityAddIU
	.p2align	4, 0x90
	.type	quantityAddIU,@function
quantityAddIU:
	.cfi_startproc
	movslq	%edi, %rcx
	movl	%esi, %eax
	addq	%rcx, %rax
	retq
.Lfunc_end1:
	.size	quantityAddIU, .Lfunc_end1-quantityAddIU
	.cfi_endproc

	.section	.text.rawSubUU,"ax",@progbits
	.globl	rawSubUU
	.p2align	4, 0x90
	.type	rawSubUU,@function
rawSubUU:
	.cfi_startproc
	movl	%edi, %eax
	movl	%esi, %ecx
	subq	%rcx, %rax
	retq
.Lfunc_end2:
	.size	rawSubUU, .Lfunc_end2-rawSubUU
	.cfi_endproc

	.section	.text.quantitySubUU,"ax",@progbits
	.globl	quantitySubUU
	.p2align	4, 0x90
	.type	quantitySubUU,@function
quantitySubUU:
	.cfi_startproc
	movl	%edi, %eax
	movl	%esi, %ecx
	subq	%rcx, %rax
	retq
.Lfunc_end3:
	.size	quantitySubUU, .Lfunc_end3-quantitySubUU
	.cfi_endproc

	.section	.text.rawMulUU,"ax",@progbits
	.globl	rawMulUU
	.p2align	4, 0x90
	.type	rawMulUU,@function
rawMulUU:
	.cfi_startproc
	movl	%edi, %ecx
	movl	%esi, %eax
	imulq	%rcx, %rax
	retq
.Lfunc_end4:
	.size	rawMulUU, .Lfunc_end4-rawMulUU
	.cfi_endproc

	.section	.text.quantityMulUU,"ax",@progbits
	.globl	quantityMulUU
	.p2align	4, 0x90
	.type	quantityMulUU,@function
quantityMulUU:
	.cfi_startproc
	movl	%edi, %ecx
	movl	%esi, %eax
	imulq	%rcx, %rax
	retq
.Lfunc_end5:
	.size	quantityMulUU, .Lfunc_end5-quantityMulUU
	.cfi_endproc

	.section	.text.rawScaleIU,"ax",@progbits
	.globl	rawScaleIU
	.p2align	4, 0x90
	.type	rawScaleIU,@function
rawScaleIU:
	.cfi_startproc
	movslq	%edi, %rcx
	movl	%esi, %eax
	imulq	%rcx, %rax
	retq
.Lfunc_end6:
	.size	rawScaleIU, .Lfunc_end6-rawScaleIU
	.cfi_endproc

	.section	.text.quantityScaleIU,"ax",@progbits
	.globl	quantityScaleIU
	.p2align	4, 0x90
	.type	quantityScaleIU,@function
quantityScaleIU:
	.cfi_startproc
	movslq	%edi, %rcx
	movl	%esi, %eax
	imulq	%rcx, %rax
	retq
.Lfunc_end7:
	.size	quantityScaleIU, .Lfunc_end7-quantityScaleIU
	.cfi_endproc

	.section	.text.rawScaleRightUI,"ax",@progbits
	.globl	rawScaleRightUI
	.p2align	4, 0x90
	.type	rawScaleRightUI,@function
rawScaleRightUI:
	.cfi_startproc
	movl	%edi, %ecx
	movslq	%esi, %rax
	imulq	%rcx, %rax
	retq
.Lfunc_end8:
	.size	rawScaleRightUI, .Lfunc_end8-rawScaleRightUI
	.cfi_endproc

	.section	.text.quantityScaleRightUI,"ax",@progbits
	.globl	quantityScaleRightUI
	.p2align	4, 0x90
	.type	quantityScaleRightUI,@function
quantityScaleRightUI:
	.cfi_startproc
	movl	%edi, %ecx
	movslq	%esi, %rax
	imulq	%rcx, %rax
	retq
.Lfunc_end9:
	.size	quantityScaleRightUI, .Lfunc_end9-quantityScaleRightUI
	.cfi_endproc

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
