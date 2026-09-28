	.text
	.file	"codegen.d"
	.section	.text._D7codegen4qAddFNaNbNiNfikZSQBa__T1QTlZQf,"ax",@progbits
	.globl	_D7codegen4qAddFNaNbNiNfikZSQBa__T1QTlZQf
	.p2align	4, 0x90
	.type	_D7codegen4qAddFNaNbNiNfikZSQBa__T1QTlZQf,@function
_D7codegen4qAddFNaNbNiNfikZSQBa__T1QTlZQf:
	.cfi_startproc
	movslq	%edi, %rcx
	movl	%esi, %eax
	addq	%rcx, %rax
	retq
.Lfunc_end0:
	.size	_D7codegen4qAddFNaNbNiNfikZSQBa__T1QTlZQf, .Lfunc_end0-_D7codegen4qAddFNaNbNiNfikZSQBa__T1QTlZQf
	.cfi_endproc

	.section	.text._D7codegen4qSubFNaNbNiNfkkZSQBa__T1QTlZQf,"ax",@progbits
	.globl	_D7codegen4qSubFNaNbNiNfkkZSQBa__T1QTlZQf
	.p2align	4, 0x90
	.type	_D7codegen4qSubFNaNbNiNfkkZSQBa__T1QTlZQf,@function
_D7codegen4qSubFNaNbNiNfkkZSQBa__T1QTlZQf:
	.cfi_startproc
	movl	%edi, %eax
	movl	%esi, %ecx
	subq	%rcx, %rax
	retq
.Lfunc_end1:
	.size	_D7codegen4qSubFNaNbNiNfkkZSQBa__T1QTlZQf, .Lfunc_end1-_D7codegen4qSubFNaNbNiNfkkZSQBa__T1QTlZQf
	.cfi_endproc

	.section	.text._D7codegen4qMulFNaNbNiNfkkZSQBa__T1QTmZQf,"ax",@progbits
	.globl	_D7codegen4qMulFNaNbNiNfkkZSQBa__T1QTmZQf
	.p2align	4, 0x90
	.type	_D7codegen4qMulFNaNbNiNfkkZSQBa__T1QTmZQf,@function
_D7codegen4qMulFNaNbNiNfkkZSQBa__T1QTmZQf:
	.cfi_startproc
	movl	%edi, %ecx
	movl	%esi, %eax
	imulq	%rcx, %rax
	retq
.Lfunc_end2:
	.size	_D7codegen4qMulFNaNbNiNfkkZSQBa__T1QTmZQf, .Lfunc_end2-_D7codegen4qMulFNaNbNiNfkkZSQBa__T1QTmZQf
	.cfi_endproc

	.section	.text._D7codegen6qScaleFNaNbNiNfikZSQBc__T1QTlZQf,"ax",@progbits
	.globl	_D7codegen6qScaleFNaNbNiNfikZSQBc__T1QTlZQf
	.p2align	4, 0x90
	.type	_D7codegen6qScaleFNaNbNiNfikZSQBc__T1QTlZQf,@function
_D7codegen6qScaleFNaNbNiNfikZSQBc__T1QTlZQf:
	.cfi_startproc
	movslq	%edi, %rcx
	movl	%esi, %eax
	imulq	%rcx, %rax
	retq
.Lfunc_end3:
	.size	_D7codegen6qScaleFNaNbNiNfikZSQBc__T1QTlZQf, .Lfunc_end3-_D7codegen6qScaleFNaNbNiNfikZSQBc__T1QTlZQf
	.cfi_endproc

	.section	.text._D7codegen11qScaleRightFNaNbNiNfkiZSQBi__T1QTlZQf,"ax",@progbits
	.globl	_D7codegen11qScaleRightFNaNbNiNfkiZSQBi__T1QTlZQf
	.p2align	4, 0x90
	.type	_D7codegen11qScaleRightFNaNbNiNfkiZSQBi__T1QTlZQf,@function
_D7codegen11qScaleRightFNaNbNiNfkiZSQBi__T1QTlZQf:
	.cfi_startproc
	movl	%edi, %ecx
	movslq	%esi, %rax
	imulq	%rcx, %rax
	retq
.Lfunc_end4:
	.size	_D7codegen11qScaleRightFNaNbNiNfkiZSQBi__T1QTlZQf, .Lfunc_end4-_D7codegen11qScaleRightFNaNbNiNfkiZSQBi__T1QTlZQf
	.cfi_endproc

	.section	.text.rawInlineAddIU,"ax",@progbits
	.globl	rawInlineAddIU
	.p2align	4, 0x90
	.type	rawInlineAddIU,@function
rawInlineAddIU:
	.cfi_startproc
	movslq	%edi, %rcx
	movl	%esi, %eax
	addq	%rcx, %rax
	retq
.Lfunc_end5:
	.size	rawInlineAddIU, .Lfunc_end5-rawInlineAddIU
	.cfi_endproc

	.section	.text.quantityInlineAddIU,"ax",@progbits
	.globl	quantityInlineAddIU
	.p2align	4, 0x90
	.type	quantityInlineAddIU,@function
quantityInlineAddIU:
	.cfi_startproc
	movslq	%edi, %rcx
	movl	%esi, %eax
	addq	%rcx, %rax
	retq
.Lfunc_end6:
	.size	quantityInlineAddIU, .Lfunc_end6-quantityInlineAddIU
	.cfi_endproc

	.section	.text.rawInlineSubUU,"ax",@progbits
	.globl	rawInlineSubUU
	.p2align	4, 0x90
	.type	rawInlineSubUU,@function
rawInlineSubUU:
	.cfi_startproc
	movl	%edi, %eax
	movl	%esi, %ecx
	subq	%rcx, %rax
	retq
.Lfunc_end7:
	.size	rawInlineSubUU, .Lfunc_end7-rawInlineSubUU
	.cfi_endproc

	.section	.text.quantityInlineSubUU,"ax",@progbits
	.globl	quantityInlineSubUU
	.p2align	4, 0x90
	.type	quantityInlineSubUU,@function
quantityInlineSubUU:
	.cfi_startproc
	movl	%edi, %eax
	movl	%esi, %ecx
	subq	%rcx, %rax
	retq
.Lfunc_end8:
	.size	quantityInlineSubUU, .Lfunc_end8-quantityInlineSubUU
	.cfi_endproc

	.section	.text.rawInlineMulUU,"ax",@progbits
	.globl	rawInlineMulUU
	.p2align	4, 0x90
	.type	rawInlineMulUU,@function
rawInlineMulUU:
	.cfi_startproc
	movl	%edi, %ecx
	movl	%esi, %eax
	imulq	%rcx, %rax
	retq
.Lfunc_end9:
	.size	rawInlineMulUU, .Lfunc_end9-rawInlineMulUU
	.cfi_endproc

	.section	.text.quantityInlineMulUU,"ax",@progbits
	.globl	quantityInlineMulUU
	.p2align	4, 0x90
	.type	quantityInlineMulUU,@function
quantityInlineMulUU:
	.cfi_startproc
	movl	%edi, %ecx
	movl	%esi, %eax
	imulq	%rcx, %rax
	retq
.Lfunc_end10:
	.size	quantityInlineMulUU, .Lfunc_end10-quantityInlineMulUU
	.cfi_endproc

	.section	.text.rawInlineScaleIU,"ax",@progbits
	.globl	rawInlineScaleIU
	.p2align	4, 0x90
	.type	rawInlineScaleIU,@function
rawInlineScaleIU:
	.cfi_startproc
	movslq	%edi, %rcx
	movl	%esi, %eax
	imulq	%rcx, %rax
	retq
.Lfunc_end11:
	.size	rawInlineScaleIU, .Lfunc_end11-rawInlineScaleIU
	.cfi_endproc

	.section	.text.quantityInlineScaleIU,"ax",@progbits
	.globl	quantityInlineScaleIU
	.p2align	4, 0x90
	.type	quantityInlineScaleIU,@function
quantityInlineScaleIU:
	.cfi_startproc
	movslq	%edi, %rcx
	movl	%esi, %eax
	imulq	%rcx, %rax
	retq
.Lfunc_end12:
	.size	quantityInlineScaleIU, .Lfunc_end12-quantityInlineScaleIU
	.cfi_endproc

	.section	.text.rawInlineScaleRightUI,"ax",@progbits
	.globl	rawInlineScaleRightUI
	.p2align	4, 0x90
	.type	rawInlineScaleRightUI,@function
rawInlineScaleRightUI:
	.cfi_startproc
	movl	%edi, %ecx
	movslq	%esi, %rax
	imulq	%rcx, %rax
	retq
.Lfunc_end13:
	.size	rawInlineScaleRightUI, .Lfunc_end13-rawInlineScaleRightUI
	.cfi_endproc

	.section	.text.quantityInlineScaleRightUI,"ax",@progbits
	.globl	quantityInlineScaleRightUI
	.p2align	4, 0x90
	.type	quantityInlineScaleRightUI,@function
quantityInlineScaleRightUI:
	.cfi_startproc
	movl	%edi, %ecx
	movslq	%esi, %rax
	imulq	%rcx, %rax
	retq
.Lfunc_end14:
	.size	quantityInlineScaleRightUI, .Lfunc_end14-quantityInlineScaleRightUI
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
