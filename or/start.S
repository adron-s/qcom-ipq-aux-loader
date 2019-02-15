#include "config.h"

.globl _start
_start:
	@bl	save_boot_params
	/*
	 * set the cpu to SVC32 mode
	 */
	@mrs	r0, cpsr
	@bic	r0, r0, #0x1f
	@orr	r0, r0, #0xd3
	@msr	cpsr,r0

/* Set stackpointer in internal RAM to call board_init_f */
call_board_init_f:
	@ldr	sp, =(CONFIG_SYS_INIT_SP_ADDR)
	@bic	sp, sp, #7 /* 8-byte alignment for ABI compliance */
	@ldr	r0,=0x00000000
	@bl	board_init_f
	ldr r0, =0x87300000
	@ldr r1, =0x81820000
	mov r1, r0
	bl relocate_code

.globl owl_get_sp
owl_get_sp:
	mov	r0, sp
	mov	pc, lr @ back to my caller

.globl _TEXT_BASE
_TEXT_BASE:
	@ .word	CONFIG_SYS_TEXT_BASE
	.word	0x80000000

/*
 * These are defined in the board-specific linker script.
 */
.globl _bss_start_ofs
_bss_start_ofs:
	.word __bss_start - _start

.global	_image_copy_end_ofs
_image_copy_end_ofs:
	.word 	__image_copy_end - _start

.globl _bss_end_ofs
_bss_end_ofs:
	.word __bss_end__ - _start

.globl _end_ofs
_end_ofs:
	.word _end - _start

/*
 * void relocate_code (addr_sp, addr_moni)
 *
 * This "function" does not return, instead it continues in RAM
 * after relocating the monitor code.
 *
 */
 
.globl relocate_code
.align		4
relocate_code:

	mov	r4, r0	/* save addr_sp */
	@ mov	r5, r1	/* save addr of gd */
	mov	r6, r1	/* save addr of destination */

	/* Set up the stack						    */
stack_setup:
	mov	sp, r4

	adr	r0, _start
	cmp	r0, r6
	moveq	r9, #0		/* no relocation. relocation offset(r9) = 0 */

	beq	clear_bss		/* skip relocation */
	mov	r1, r6			/* r1 <- scratch for copy_loop */
	ldr	r3, _image_copy_end_ofs
	@ ldr	r3, _bss_end_ofs @ !!! copy MORE _image + bss(some important static variables!) !!!
	add	r2, r0, r3		/* r2 <- source end address	    */

copy_loop:
	ldmia	r0!, {r9-r10}		/* copy from source address [r0]    */
	stmia	r1!, {r9-r10}		/* copy to   target address [r1]    */
	cmp	r0, r2			/* until source end address [r2]    */
	blo	copy_loop

	/*
	 * fix .rel.dyn relocations
	 */
	ldr	r0, _TEXT_BASE		/* r0 <- Text base */
	sub	r9, r6, r0		/* r9 <- relocation offset */
	ldr	r10, _dynsym_start_ofs	/* r10 <- sym table ofs */
	add	r10, r10, r0		/* r10 <- sym table in FLASH */
	ldr	r2, _rel_dyn_start_ofs	/* r2 <- rel dyn start ofs */
	add	r2, r2, r0		/* r2 <- rel dyn start in FLASH */
	ldr	r3, _rel_dyn_end_ofs	/* r3 <- rel dyn end ofs */
	add	r3, r3, r0		/* r3 <- rel dyn end in FLASH */
fixloop:
	ldr	r0, [r2]		/* r0 <- location to fix up, IN FLASH! */
	add	r0, r0, r9		/* r0 <- location to fix up in RAM */
	ldr	r1, [r2, #4]
	and	r7, r1, #0xff
	cmp	r7, #23			/* relative fixup? */
	beq	fixrel
	cmp	r7, #2			/* absolute fixup? */
	beq	fixabs
	/* ignore unknown type of fixup */
	b	fixnext
fixabs:
	/* absolute fix: set location to (offset) symbol value */
	mov	r1, r1, LSR #4		/* r1 <- symbol index in .dynsym */
	add	r1, r10, r1		/* r1 <- address of symbol in table */
	ldr	r1, [r1, #4]		/* r1 <- symbol value */
	add	r1, r1, r9		/* r1 <- relocated sym addr */
	b	fixnext
fixrel:
	/* relative fix: increase location by offset */
	ldr	r1, [r0]
	add	r1, r1, r9
fixnext:
	str	r1, [r0] /* stores the value found in R1 to the memory address found in R0 */
	add	r2, r2, #8		/* each rel.dyn entry is 8 bytes */
	cmp	r2, r3
	blo	fixloop @ if(r2 < r3)
	b	clear_bss
_rel_dyn_start_ofs:
	.word __rel_dyn_start - _start
_rel_dyn_end_ofs:
	.word __rel_dyn_end - _start
_dynsym_start_ofs:
	.word __dynsym_start - _start
clear_bss:
#ifdef CONFIG_SPL_BUILD
	/* No relocation for SPL */
	ldr	r0, =__bss_start
	ldr	r1, =__bss_end__
#else
	ldr	r0, _bss_start_ofs
	ldr	r1, _bss_end_ofs
	mov	r4, r6			/* reloc addr */
	add	r0, r0, r4
	add	r1, r1, r4
#endif
	mov	r2, #0x00000000		/* clear			    */

clbss_l:
	cmp	r0, r1			/* clear loop... */
	bhs	clbss_e			/* if reached end of bss, exit */
	str	r2, [r0]
	add	r0, r0, #4
	b	clbss_l
clbss_e:

/*
 * We are done. Do not return, instead branch to second part of board
 * initialization, now running from RAM.
 */
jump_2_ram:
/*
 * If I-cache is enabled invalidate it
 */
#ifndef CONFIG_SYS_ICACHE_OFF
	mcr	p15, 0, r0, c7, c5, 0	@ invalidate icache
	mcr     p15, 0, r0, c7, c10, 4	@ DSB
	mcr     p15, 0, r0, c7, c5, 4	@ ISB
#endif
/*
 * Move vector table
 * Set vector address in CP15 VBAR register 
 */
	ldr     r0, =_start
	add     r0, r0, r9
	mcr     p15, 0, r0, c12, c0, 0  @Set VBAR

	ldr	r0, _board_init_f_ofs
	adr	r1, _start

	add	lr, r0, r1
	add	lr, lr, r9
	/* setup parameters for board_init_f */
	@ ldr	r0,=0x00000000
	mov	r0, r6		/* dest_addr */
	/* jump to it ... */
	mov	pc, lr

_board_init_f_ofs:
	.word board_init_f - _start
.type relocate_code STT_FUNC
.size relocate_code, .-relocate_code
