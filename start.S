#include "config.h"

.globl _start
_start:
	bl	save_boot_params
	/*
	 * set the cpu to SVC32 mode
	 */
	@ mrs	r0, cpsr
	@ bic	r0, r0, #0x1f
	@ orr	r0, r0, #0xd3
	@ msr	cpsr,r0

/* Set stackpointer in internal RAM to call board_init_f */
call_board_init_f:
	ldr	sp, =(CONFIG_SYS_INIT_SP_ADDR)
	bic	sp, sp, #7 /* 8-byte alignment for ABI compliance */
	ldr	r0,=0x00000000
	bl	board_init_f

.globl owl_get_sp
owl_get_sp:
	mov	r0, sp
	mov	pc, lr @ back to my caller
