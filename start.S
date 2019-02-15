#include "config.h"

.globl _start
_start:
	mov r7, pc @save REAL _start addr
	@ bl	save_boot_params
	/*
	 * set the cpu to SVC32 mode
	 */
	@mrs	r0, cpsr
	@bic	r0, r0, #0x1f
	@orr	r0, r0, #0xd3
	@msr	cpsr,r0

/* Lets clear a bss */
clear_bss:
	ldr	r0, =_bss_start
	ldr	r1, =_bss_end
	mov	r2, #0x00000000		/* clear			    */
clbss_l:
	cmp	r0, r1			/* clear loop... */
	bhs	clbss_e			/* if reached end of bss, exit */
	str	r2, [r0]
	add	r0, r0, #4
	b	clbss_l
clbss_e:

/* Set stackpointer in internal RAM to call board_init_f */
call_board_init_f:
	ldr	sp, =(CONFIG_SYS_INIT_SP_ADDR)
	bic	sp, sp, #7 /* 8-byte alignment for ABI compliance */
	@ldr	r0,=0x00000000
	@mov sp, r7 @ fix stack
	@bic	sp, sp, #7 /* 8-byte alignment for ABI compliance */
	mov r0, r7
	adr	r1, _start
	bl	board_init_f
	@mov r2, r7 @!!!!!!!!
	@ldr r0, =0x87300000
	@mov r1, r0
	@mov r2, r7 @ real _start addr !
	@bl relocate_code

.globl owl_get_sp
owl_get_sp:
	mov	r0, sp
	mov	pc, lr @ back to my caller

